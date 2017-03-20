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

class PhotoViewController: UICollectionViewController, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    let latitude = DefaultValues.Lat
    let longitude = DefaultValues.Lon
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the frc changes, we execute the search and
            // reload the table
            fetchedResultsController?.delegate = self
            executeSearch()
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
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
            }
        }
    }
    
}
