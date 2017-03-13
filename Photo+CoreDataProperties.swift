//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Lisa Litchfield on 3/13/17.
//  Copyright © 2017 Lisa Litchfield. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var image_url: String?
    @NSManaged public var pin: Pin?

}
