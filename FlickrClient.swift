//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Lisa Litchfield on 3/13/17.
//  Copyright © 2017 Lisa Litchfield. All rights reserved.
//

import Foundation

class FlickrClient: NSObject{
 
    // MARK: Shared Instance
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }

}
