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
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var enlargeButton: UIButton!
    var coordinate = CLLocationCoordinate2D(latitude: DefaultValues.Lat, longitude: DefaultValues.Lon)
    var pin: Pin! = nil
    let reuseIdentifier = PhotoProperties.ReuseIdentifier
    var editingAlbum = false
    var photoURLS: [String] = []
    var storedPhotosToBeDeleted = [Photo]()
    var currentPage = 1
    var numberOfPages = 0
    var currentIndex = 0  //used to keep track of last used image URL in array for downloading images
    var newAlbumURLs = [String]()
    var photoImage = #imageLiteral(resourceName: "turtle.jpg")
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the frc changes execute the search

            executeSearch()

        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        fetchedResultsController?.delegate = self
        editingAlbum = false
        albumButton.isEnabled = false
        mapView.centerCoordinate = coordinate
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = true
        label.text = ""
        enlargeButton.isEnabled = false
        
        //check if any pictures in memory for this pin
        // if not, get pictures from Flickr
        executeSearch()
//        print("number of items returned: \(fetchedResultsController?.fetchedObjects?.count)")
        if fetchedResultsController?.fetchedObjects?.count == 0 || photoURLS.count == 0{
            
            getNewURLs(latitude: coordinate.latitude , longitude: coordinate.longitude , page: nil, radius: nil, createNewAlbum: fetchedResultsController?.fetchedObjects?.count == 0)

        }
        if fetchedResultsController?.fetchedObjects?.count != 0 {
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
//            print("all photos deleted")
            executeSearch()
            collectionView.reloadData()
        }
        
    }
    //This method creates and stores Photo objects for new album
    func createNewAlbum(){
        //Get the persistent container
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext
        fillAlbumLoader()
        let albumSize = min(Constants.PhotosPerAlbum,photoURLS.count-currentIndex)

        DispatchQueue.main.async {
            for _ in 0..<albumSize{
                //create Photo object and set realtionship to pin
                let newPhoto = Photo(entity:Photo.entity(), insertInto: context)
                newPhoto.pin = self.pin
                
                }
        
           //update user interface

                self.albumButton.isEnabled = true
                self.executeSearch()
                self.collectionView.reloadData()
            
            }
            

        currentIndex += albumSize  //update pointer for  next album request
    }
    //This method copies one album's worth of image URLs to newAlbumURLs array used for loading a new album
    func fillAlbumLoader(){
        let albumSize = min(Constants.PhotosPerAlbum,photoURLS.count-currentIndex)
        newAlbumURLs.removeAll()
        for i in 0..<albumSize{
            newAlbumURLs.append(self.photoURLS[self.currentIndex+i]) //copy image url to array for consumption by collectionView cell
        }
    }
    
    //This method uses the FlickrClient to obtain new photo URLs
    func getNewURLs(latitude: Double, longitude: Double, page: Int?, radius: Int?, createNewAlbum: Bool){
        FlickrClient.sharedInstance().getPhotos(latitude: latitude , longitude: longitude, page: page, radius:radius, completionHandler: {(pages,photos, error) in
            guard error == nil else{
                notifyUser(self, message: (error!.localizedDescription))
                return
            }
            guard let pics = photos else{
                notifyUser(self, message: "No photos returned")
                return
            }
            
            self.numberOfPages = pages
            
            self.photoURLS = pics
//            print(pics)
            
            //If no pictures found use wider search radius
            if pics.count == 0 && radius == nil {
                FlickrClient.sharedInstance().getPhotos(latitude: latitude , longitude: longitude, page: page, radius:FlickrClient.ParameterValues.ExtendedRadius, completionHandler: {(pages,photos, error) in
                    guard error == nil else{
                        notifyUser(self, message: (error!.localizedDescription))
                        return
                    }
                    guard let pics = photos else{
                        notifyUser(self, message: "No photos returned")
                        return
                    }
                    
                    self.numberOfPages = pages
                    
                    self.photoURLS = pics
//                    print(pics)
                    if pics.count == 0{
                        DispatchQueue.main.async {
                            self.label.text = "No images for pin"
                        }
                    }
                })
                
            
            }
            self.fillAlbumLoader()
            if(createNewAlbum){
            //create Photo objects for new album
                self.createNewAlbum()

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
//            print("\(storedPhotosToBeDeleted.count) photos deleted")
            executeSearch()
            collectionView.reloadData()
            albumButton.setTitle(ButtonText.NotEditing, for: .normal)
            editingAlbum = false
            return
        }
        else {
            //disable button
            albumButton.isEnabled = false
            // delete all stored Photos
            clearAlbum()
            
            //Check if unused urls from previous download
            if  currentIndex  >= photoURLS.count   {
                currentPage += 1
                if (currentPage > numberOfPages) {
                    
                   // inform user no more pictures
                    self.label.text = "No images for pin"
        
                }
                else {
                    currentIndex = 0
                    getNewURLs(latitude: coordinate.latitude, longitude: coordinate.longitude, page: currentPage, radius: nil, createNewAlbum: true)
                }
            
            //TBDdownload new photos from FLickr
            }
            else{
            //use previously stored URLs
                createNewAlbum()
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
            enlargeButton.isEnabled = true
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
        if storedPhotosToBeDeleted.count == 0{
            editingAlbum = false
            albumButton.setTitle(ButtonText.NotEditing, for: .normal)
            enlargeButton.isEnabled = false
        }
        
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionViewCell
        // Find the right Photo for this indexpath & use it's image if one is present
        let photo = fetchedResultsController!.object(at: indexPath) as! Photo
        if let image = photo.image{
            photoImage = UIImage(data: image as Data)!
        }
        else{
            photoImage = #imageLiteral(resourceName: "turtle.jpg")  //set placeholder image
            if newAlbumURLs.count == 0{
                
                return cell  //this might occur if user selected back while album downloading
            }

            //get next url
            cell.activityIndicator.startAnimating()
            let url = newAlbumURLs.popLast()
            // download image from FLickr
            FlickrClient.sharedInstance().getImage(urlString: url!, completionHandler: {(image,error) in
                guard error == nil else{
                    notifyUser(self, message: "Error downloading image")
                    return
                    
                }
                DispatchQueue.main.async {
                    cell.imageView.image = UIImage(data: image as! Data)
                    photo.image = image as? NSData
                    cell.activityIndicator.stopAnimating()
                    //Get the persistent container
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    //store new Photo in Core Data
                    
                    delegate.saveContext()
                    self.albumButton.isEnabled = true
                
                }
                
            })
        }
        

        
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
    
    
    
    
    
    //MARK: mapView delegate
    //User can delete all photos and the associated pin by tapping on the pin and selecting "Delete" when the Alert is displayed
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView){
         mapView.deselectAnnotation(view.annotation, animated: false)  //reset so user can select again
    
        
     let controller = UIAlertController(title: "Alert", message: "Do you wish to delete this pin and it's associated photos?", preferredStyle: .alert)
     let deleteAction = UIAlertAction(title: "DELETE", style: .destructive) { action in

     
        self.clearAlbum()
        //Get the persistent container
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext
        context.delete(self.pin)

        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.ModelUpdatedNotificationKey), object: self)
        self.navigationController?.popViewController(animated: false)

    
     
     }
     let cancelAction = UIAlertAction(title: "CANCEL", style: .cancel, handler: {action in self.dismiss(animated: false)})
     controller.addAction(deleteAction)
     controller.addAction(cancelAction)
     self.present(controller, animated: true, completion: nil)
     
     }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller = segue.destination as! EnlargementViewController
        
        if segue.identifier == "enlarge"{
            
            controller.imageToBlowup = UIImage(data: (storedPhotosToBeDeleted.last?.image)! as Data)
        }
        
    }
    
}







//MARK: Core Data suppport
extension PhotoViewController: NSFetchedResultsControllerDelegate{
    func executeSearch() {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                sendAlert(self, message: "Error performing search: \(e)")
            }
        }
    }
    
}
