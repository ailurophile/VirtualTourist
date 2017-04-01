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
import UIKit

class PhotoViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate {
    @IBOutlet weak var albumButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
//    var latitude = DefaultValues.Lat
//    var longitude = DefaultValues.Lon
    var coordinate = CLLocationCoordinate2D(latitude: DefaultValues.Lat, longitude: DefaultValues.Lon)
    var pin: Pin! = nil
    let reuseIdentifier = PhotoProperties.ReuseIdentifier
    var editingAlbum = false
    var photoURLS: [String]!
//    var storedPhotos: [Photo]!
    var currentPage = 0
    let numberOfPages: Int? = nil
    var currentIndex = 0  //used to keep track of last used image URL in array for downloading images
//    var flickrClient = FlickrClient()
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
        //get pictures from memory if any
        
        //get pictures from Flickr
        FlickrClient.sharedInstance().getPhotos(latitude: coordinate.latitude as Double, longitude: coordinate.longitude as Double, page: nil, radius: nil, completionHandler: {(photos, error) in
            guard error == nil else{
                notifyUser(self, message: (error!.localizedDescription))
                return
            }
            self.photoURLS = photos
            print(photos)
/*            while (self.currentIndex < (photos?.count)! ){
                let pic = photos?[self.currentIndex]
                self.currentIndex+=1
                print(pic!)
            }*/
            //download images and create Photo objects 
            self.getImages()

            })
        
    }
    //This method deletes all photos for the current pin
    func clearAlbum(){
        
    }
    //This method download the image stored at the url retrieved earlier from Flickr 
    // and creates  and stores Photo objects
    func getImages(){
        //Get the persistent container
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext
        for i in 1...Constants.PhotosPerAlbum{
            let url = URL(string: photoURLS[currentIndex+i])
            do{
            let imageData = try Data(contentsOf: url!)
                
                //create Photo object and set realtionship to pin
                let newPhoto = Photo(entity:Photo.entity(), insertInto: context)
                newPhoto.image = imageData as NSData?
                newPhoto.pin = pin
            } catch let error as NSError {
                    print("Could not get image. \(error), \(error.userInfo)")
                break
            }
            //store new Photo objects
//            delegate.saveContext()
            /*
            DispatchQueue.main.async {
           //store new Photo Objects
                delegate.saveContext()
            
            } */
                
            
            
            

            
            
        }
        currentIndex += Constants.PhotosPerAlbum
    }
    @IBAction func albumButtonSelected(_ sender: Any) {
        if(editingAlbum){
            //TBDdelete selected photos
            return
        }
        else {
            // delete all stored Photos
            clearAlbum()
            
            //Check if unused urls from previous download
            if photoURLS.count - 1 - currentIndex < Constants.PhotosPerAlbum {
            
            //TBDdownload new photos from FLickr
            }
            else{
            //use previously stored URLs
                getImages()
            }
            
            return
        }
        
    }
    
    //MARK: Collection View Delegate
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fc = fetchedResultsController {
            return fc.sections![section].numberOfObjects
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
