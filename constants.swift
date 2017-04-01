//
//  constants.swift
//  VirtualTourist
//
//  Created by Lisa Litchfield on 3/17/17.
//  Copyright © 2017 Lisa Litchfield. All rights reserved.
//

import Foundation

struct Keys {
    static let LatKey = "LatitudeKey"
    static let LonKey = "LongitudeKey"
    static let LatDeltasKey = "LatitudeDeltaKey"
    static let LonDeltaKey = "LongitudeDeltaKey"
    static let Not1stLaunch = "hasLaunchedBefore"
    static let SavedMapSettings = "mapSettings"
}
struct DefaultValues {
    static let Lat = 30.0
    static let Lon = -40.0
    static let LatDelta = 125.4
    static let LonDelta = 112.4
}
struct PinProperties {
    static let Lat = "latitude"
    static let Lon = "longitude"
    static let Photos = "photos"
}
struct PhotoProperties {
    static let URL = "image_url"
    static let Image = "image"
    static let Pin = "pin"
    static let ReuseIdentifier = "PhotoCell"
}
struct Constants {
    static let PhotosPerAlbum = 21

}
