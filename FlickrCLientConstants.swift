//
//  FlickrCLientConstants.swift
//  VirtualTourist
//
//  Created by Lisa Litchfield on 3/13/17.
//  Copyright © 2017 Lisa Litchfield. All rights reserved.
//

import Foundation

extension FlickrClient{
    struct Constants{
        //MARK: URLs
        static let ApiScheme = "https"
        static let ApiHost = "www.flickr.com"
        static let SessionPath = "/services/rest"
    }
    //MARK: Parameter Keys
    struct ParameterKeys {
        static let APIKey = "api_key"
        static let Extras = "extras"
        static let Format = "format"
        static let Latitude = "lat"
        static let Longitude = "lon"
        static let Method = "method"
        static let NoJSONCallback = "nojsoncallback"
        static let Page = "page"
        static let PerPage = "per_page"
        static let Radius = "radius"
    }
    //MARK: Parameter Values
    struct ParameterValues {
        static let APIKey = "cd5bcb2f1858e7619add5bf3d73137fa"
        static let DisableJSONCallback = 1
        static let ExtendedRadius = 10    // default is 5Km
        static let FindPhotos = "flickr.photos.search"
        static let MediumURL = "url_m"
        static let Status = "stat"
        static let Title = "title"

    }
    
}
