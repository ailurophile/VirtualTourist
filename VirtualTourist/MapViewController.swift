//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Lisa Litchfield on 3/10/17.
//  Copyright © 2017 Lisa Litchfield. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var storedPins : [Pin]!
    var annotations = [MKAnnotation]()
    
    
    


    override func viewDidLoad() {
        super.viewDidLoad()
        // Set delegate
        mapView.delegate = self
        //Create touch and hold gesture recognizer
        let holdTouch = UILongPressGestureRecognizer(target: self, action: #selector(dropPin(gestureRecognizer:)))
        holdTouch.minimumPressDuration = 2.0
        mapView.addGestureRecognizer(holdTouch)
        // Retrieve user's last used map settings
        let mapSettings = UserDefaults.standard.value(forKey: Keys.SavedMapSettings) as! [String: Double]
        mapView.centerCoordinate = CLLocationCoordinate2DMake(mapSettings[Keys.LatKey]!, mapSettings[Keys.LonKey]!)
        let span = MKCoordinateSpan(latitudeDelta: mapSettings[Keys.LatDeltasKey]!, longitudeDelta: mapSettings[Keys.LonDeltaKey]!)
        mapView.region.span = span
        //register for notifications
        NotificationCenter.default.addObserver(self, selector: #selector(loadPins), name: NSNotification.Name(rawValue: Constants.ModelUpdatedNotificationKey), object: nil)
        loadPins()
        
    }
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    // This method will add a pin to the map when user holds touch for 2 seconds
    func dropPin(gestureRecognizer:UIGestureRecognizer){
        if gestureRecognizer.state == UIGestureRecognizerState.began{
            let location = gestureRecognizer.location(in: mapView)
            let annotation = MKPointAnnotation()
            let coordinates = mapView.convert(location, toCoordinateFrom: mapView)
            annotation.coordinate = coordinates
            mapView.addAnnotation(annotation)
            //Get the persistent container
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let context = delegate.persistentContainer.viewContext
            //Create newPin managed object
            let newPin = Pin(entity: Pin.entity(), insertInto: context)
            newPin.latitude = coordinates.latitude
            newPin.longitude = coordinates.longitude
            storedPins.append(newPin)
            //save Pin
            delegate.saveContext()
        }
    }
    // This delegate method is implemented to respond to taps. It presents the Photos view controller.
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView){
        let c = view.annotation?.coordinate
        mapView.deselectAnnotation(view.annotation, animated: false)

        performSegue(withIdentifier: "ShowPhotos", sender: c)
    }
    
    
   //store map settings after mapiew has changed
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool){
        let mapSettings = [Keys.LatKey: mapView.centerCoordinate.latitude,
                           Keys.LonKey: mapView.centerCoordinate.longitude,
                           Keys.LatDeltasKey: mapView.region.span.latitudeDelta,
                           Keys.LonDeltaKey: mapView.region.span.longitudeDelta]
        UserDefaults.standard.setValue(mapSettings, forKey: Keys.SavedMapSettings)
        UserDefaults.standard.synchronize()
    }
    
    private func addAnnotationsToMap(){
        
        annotations.removeAll()
        mapView.removeAnnotations(mapView.annotations)
        for pin in storedPins{
            let annotation = MapViewController.getAnnotation(pin: pin)
            annotations.append(annotation)
            
        }
        mapView.addAnnotations(annotations)
    }
    
    class func getAnnotation(pin: Pin)-> MKPointAnnotation{
        let lat = CLLocationDegrees(pin.latitude  )
        let long = CLLocationDegrees(pin.longitude )
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        //create annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        return annotation
        
        
    }
    //MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //get Pin managed object for selected annotation
        let pin = getPin(for: sender! as! CLLocationCoordinate2D)
        let viewController = segue.destination as! PhotoViewController
        //store coordinate in view controller
        viewController.coordinate = sender! as! CLLocationCoordinate2D
        viewController.pin = pin
        //Get the persistent container
        let delegate = UIApplication.shared.delegate as! AppDelegate
        //Create fetch request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        //        fetchRequest.sortDescriptors = [NSSortDescriptor(key: PinProperties.Lat, ascending: true), NSSortDescriptor(key: PinProperties.Lon, ascending: true)]
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: PhotoProperties.Image, ascending: true)]
        //        let pred = NSPredicate.subst
        let pred = NSPredicate(format: "pin = %@" , argumentArray: [pin])
        fetchRequest.predicate = pred
        
        //Create FetchedResultsController
        viewController.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: delegate.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
       
    }
    //MARK: Core Data 
    func getPin(for coordinate: CLLocationCoordinate2D) -> Pin {
        for pin in storedPins{
            if pin.latitude == coordinate.latitude && pin.longitude == coordinate.longitude{
                return pin
            }
        }
        
        print("Pin not found so using 1st Pin")
        return storedPins[0]
            
        
    }
    
    @objc private func loadPins(){
        //Get the persistent container
        let delegate = UIApplication.shared.delegate as! AppDelegate
        //Create fetch request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: PinProperties.Lat, ascending: true),NSSortDescriptor(key: PinProperties.Lon, ascending: true)]
        do {
            let results = try delegate.persistentContainer.viewContext.fetch(fetchRequest) as! [Pin]
/*            for pin in results{
                print("pin at coordinates: \(pin.latitude),\(pin.longitude)")
            }*/
            storedPins = results
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        addAnnotationsToMap()

        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
 
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }


}


