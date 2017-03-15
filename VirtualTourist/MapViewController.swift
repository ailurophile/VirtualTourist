//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Lisa Litchfield on 3/10/17.
//  Copyright © 2017 Lisa Litchfield. All rights reserved.
//

import UIKit
import MapKit

struct Keys {
    static let LatKey = "LatitudeKey"
    static let LonKey = "LongitudeKey"
    static let LatDeltasKey = "LatitudeDeltaKey"
    static let LonDeltaKey = "LongitudeDeltaKey"
}
struct DefaultsValues {
    static let Lat = 30.0
    static let Lon = -40.0
    static let LatDelta = 125.4
    static let LonDelta = 112.4
}

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!

    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let holdTouch = UILongPressGestureRecognizer(target: self, action: #selector(dropPin(gestureRecognizer:)))
        holdTouch.minimumPressDuration = 2.0
        mapView.addGestureRecognizer(holdTouch)
        print(" span = \(mapView.region.span)")
        print("center = \(mapView.centerCoordinate)")

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
            annotation.coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            mapView.addAnnotation(annotation)
        }
    }
    
    
    // This delegate method is implemented to respond to taps. It opens the system browser
    // to the URL specified in the annotationViews subtitle property.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let viewController = self.storyboard?.instantiateViewController(withIdentifier: "PhotoViewController") as! PhotoViewController
        self.present(viewController, animated: true, completion: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
 
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

