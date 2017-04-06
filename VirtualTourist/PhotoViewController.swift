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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    var coordinate = CLLocationCoordinate2D(latitude: DefaultValues.Lat, longitude: DefaultValues.Lon)
    var pin: Pin! = nil
    let reuseIdentifier = PhotoProperties.ReuseIdentifier
    var editingAlbum = false
    var photoURLS: [String]!
    var storedPhotosToBeDeleted = [Photo]()
    var currentPage = 1
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
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = true
        
        //check if any pictures in memory for this pin
        // if not, get pictures from Flickr
        executeSearch()
        print("number of items returned: \(fetchedResultsController?.fetchedObjects?.count)")
        if fetchedResultsController?.fetchedObjects?.count == 0 {
            getNewURLs(latitude: coordinate.latitude as Double, longitude: coordinate.longitude as! Double, page: nil, radius: nil)
/*            activityIndicator.startAnimating()
            FlickrClient.sharedInstance().getPhotos(latitude: coordinate.latitude as Double, longitude: coordinate.longitude as Double, page: nil, radius: nil, completionHandler: {(photos, error) in
            guard error == nil else{
                notifyUser(self, message: (error!.localizedDescription))
                return
            }
            self.photoURLS = photos
            print(photos)

            //download images and create Photo objects 
            DispatchQueue.global().async {
                self.getImages()
            }
//            self.getImages()
            
            

            })
 */
        }
        else{
            albumButton.isEnabled = true
        }
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // set up flow layout
        configureFlowLayout(view.frame.size)
        
    }

    //This method deletes all photos for the current pin
    func clearAlbum(){
        //Get the persistent container
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext
        if let pics = fetchedResultsController?.fetchedObjects{
            for pic in pics {
                context.delete(pic as! NSManagedObject)
            }
            delegate.saveContext()
            print("all photos deleted")
            executeSearch()
            collectionView.reloadData()
        }
        
    }
    //This method downloads the image stored at the url retrieved earlier from Flickr
    // and creates  and stores Photo objects
    func getImages(){
        activityIndicator.startAnimating()
        //Get the persistent container
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext
        let albumSize = min(Constants.PhotosPerAlbum,photoURLS.count)
        for i in 0..<albumSize{
            let url = URL(string: photoURLS[currentIndex+i])
            do{
            let imageData = try Data(contentsOf: url!)
                
                //create Photo object and set realtionship to pin
                let newPhoto = Photo(entity:Photo.entity(), insertInto: context)
                newPhoto.image = imageData as NSData?
                newPhoto.pin = pin
                //store new Photo in Core Data
                DispatchQueue.main.async {
                    //store new Photo Objects
                    delegate.saveContext()
//                    self.albumButton.isEnabled = true
                    
                }
            } catch let error as NSError {
                    print("Could not get image. \(error), \(error.userInfo)")
                break
            }
            //store new Photo objects
//            delegate.saveContext()
            
            DispatchQueue.main.async {
           //update user interface
//                delegate.saveContext()
                self.activityIndicator.stopAnimating()
                self.albumButton.isEnabled = true
                self.executeSearch()
                self.collectionView.reloadData()
            
            }
            
           
        }
        currentIndex += albumSize
    }
    
    //This method uses the FlickClient to obtain new photo URLs
    func getNewURLs(latitude: Double, longitude: Double, page: Int?, radius: Int?){
        activityIndicator.startAnimating()
        FlickrClient.sharedInstance().getPhotos(latitude: latitude , longitude: longitude, page: page, radius:radius, completionHandler: {(photos, error) in
            guard error == nil else{
                notifyUser(self, message: (error!.localizedDescription))
                return
            }
            guard let pics = photos else{
                notifyUser(self, message: "No photos returned")
                //TBD add label showing pin has no images
                return
            }
            self.photoURLS = pics
            print(pics)
            
            //download images and create Photo objects
            DispatchQueue.global().async {
                self.getImages()
            }
        })

    }
    //If user was editing an album, this method deletes the selected photos 
    //otherwise it deletes all photos from the album and downloads a new batch from Flickr
    @IBAction func albumButtonSelected(_ sender: Any) {
        if(editingAlbum){
            //Get the persistent container
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let context = delegate.persistentContainer.viewContext
            //delete selected photos
            for pic in storedPhotosToBeDeleted{
                context.delete(pic)
            }
            delegate.saveContext()
            print("\(storedPhotosToBeDeleted.count) photos deleted")
            executeSearch()
            collectionView.reloadData()
            albumButton.setTitle(ButtonText.NotEditing, for: .normal)
            return
        }
        else {
            // delete all stored Photos
            clearAlbum()
            
            //Check if unused urls from previous download
            if  currentIndex  >= photoURLS.count   {
                currentPage += 1
                if currentPage >= numberOfPages! {
                   //TBD inform user no more pictures
                    print("no more pictures")
        
                }
                else {
                    getNewURLs(latitude: coordinate.latitude as Double, longitude: coordinate.longitude as! Double, page: currentPage, radius: nil)
                }
            
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
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let fc = fetchedResultsController {
            return fc.sections!.count
        } else {
            return 0
        }
    }
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
            //change button text
            albumButton.setTitle(ButtonText.Editing, for: .normal)
        }
        let selectedPhoto = fetchedResultsController?.object(at: indexPath) as! Photo
        storedPhotosToBeDeleted.append(selectedPhoto)

        let cell = collectionView.cellForItem(at: indexPath)
        cell?.alpha = 0.5

        
    }
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let selectedPhoto = fetchedResultsController?.object(at: indexPath) as! Photo
        if storedPhotosToBeDeleted.contains(selectedPhoto){
            let index = storedPhotosToBeDeleted.index(of: selectedPhoto)
            storedPhotosToBeDeleted.remove(at: index!)
        }
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.alpha = 1.0
        
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Find the right Photo for this indexpath
        let photo = fetchedResultsController!.object(at: indexPath) as! Photo
        let photoImage = UIImage(data: photo.image as! Data)
        

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionViewCell
        //configure cell
        cell.imageView.image = photoImage
        cell.alpha = 1.0
        
        return cell
    }
    func configureFlowLayout( _ size: CGSize){
        let space: CGFloat = 3.0
        let width = size.width
        let height = size.height
        var dimension = (width - (2*space))/3.0
        if width > height {
            dimension = (width - (5 * space))/6.0
        }
        
        flowLayout?.minimumLineSpacing = space
        flowLayout?.minimumInteritemSpacing = space
        flowLayout?.itemSize = CGSize(width: dimension,height: dimension)
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
