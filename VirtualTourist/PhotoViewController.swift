//
//  PhotoViewController.swift
//  VirtualTourist
//
//  Created by Lisa Litchfield on 3/12/17.
//  Copyright © 2017 Lisa Litchfield. All rights reserved.
//

import Foundation
import MapKit
import  CoreData

class PhotoViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate {
    @IBOutlet weak var albumButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
//    var latitude = DefaultValues.Lat
//    var longitude = DefaultValues.Lon
    var coordinate = CLLocationCoordinate2D(latitude: DefaultValues.Lat, longitude: DefaultValues.Lon)
    let reuseIdentifier = PhotoProperties.ReuseIdentifier
    var editingAlbum = false
    var flickrClient = FlickrClient()
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the frc changes, we execute the search and
            // reload the table
            fetchedResultsController?.delegate = self
            executeSearch()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        editingAlbum = false
        albumButton.isEnabled = false
        mapView.centerCoordinate = coordinate
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        //get pictures from Flickr
        flickrClient.getPhotos(latitude: coordinate.latitude as Double, longitude: coordinate.longitude as Double, page: nil, radius: nil, completionHandler: {(photos, error) in
            guard error == nil else{
                notifyUser(self, message: (error!.localizedDescription))
                return
            }
            print(photos)

            })
        
    }
    @IBAction func albumButtonSelected(_ sender: Any) {
        if(editingAlbum){
            //TBDdelete selected photos
            return
        }
        else {
            //TBDdownload new photos from FLickr
            return
        }
        
    }
    
    //MARK: Collection View Delegate
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fc = fetchedResultsController {
            return (fc.sections?.count)!
        } else {
            return 0
        }
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (!editingAlbum){
            
            editingAlbum = true
            //TBD change button
        }
        
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionViewCell
        //configure cell
        
        return cell
    }
}

//MARK: Core Data suppport
extension PhotoViewController: NSFetchedResultsControllerDelegate{
    func executeSearch() {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
            }
        }
    }
    
}
