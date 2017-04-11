# VirtualTourist

The VirtualTourist app was developed as part of the Udacity iOS developer nanodegree program to allow users to create photo albums using pictures downloaded from Flickr.

## Features

* allows user to pan and zoom map, saving the last selected values between launches
* allows user to drop a pin at a location on the map for which they would like to see photos by touching the map with a single finger for 2 seconds
* select a pin by tapping it to see the saved photos for that location or download and save 18 pictures from Flickr tagged with that location
* if selected location returns no images the search radius is doubled and a second attempt is made
* download a different set of photos from Flickr by pressing the New Collection button
* once all photos for a given location have been viewed, pressing the New Collection Button will result in an empty album showing the message 'No images for pin'
* select and remove photos by tapping them and selecting the Remove Selected Photos button
* remove a photo album and pin by tapping the pin in the photo album view and selecting delete from the resulting Alert
* pins and photos are retained between app launches
