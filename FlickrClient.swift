//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Lisa Litchfield on 3/13/17.
//  Copyright © 2017 Lisa Litchfield. All rights reserved.
//

import Foundation


class FlickrClient: NSObject{
    
    func getPhotos(latitude: Double, longitude: Double, page: Int?, radius: Int?, completionHandler: @escaping (_ pages: Int, _ results: [String]?, _ error: NSError?)->()){
        //build query parameters
        var parameters = [FlickrClient.ParameterKeys.Method: FlickrClient.ParameterValues.FindPhotos,
                          FlickrClient.ParameterKeys.Latitude: latitude,
                          FlickrClient.ParameterKeys.Longitude: longitude,
                          FlickrClient.ParameterKeys.ContentType: FlickrClient.ParameterValues.PhotosOnly,
                          FlickrClient.ParameterKeys.Extras: FlickrClient.ParameterValues.SquarePicURL,
                          FlickrClient.ParameterKeys.Format: FlickrClient.ParameterValues.Format,
                          FlickrClient.ParameterKeys.PerPage: FlickrClient.ParameterValues.PhotosPerPage] as [String : Any]
        //check if a specific page is desired
        if let page = page{
            parameters[FlickrClient.ParameterKeys.Page] = page
        }
        queryFlickr( parameters as [String : AnyObject], completionHandlerForQuery: {(results,error) in
            guard error == nil else{
                let userInfo = [NSLocalizedDescriptionKey : error?.localizedDescription]
                completionHandler(0, nil, NSError(domain: "getPhotos", code: 1, userInfo: (userInfo as Any as! [AnyHashable : Any])))
                return
            }
//            print(results)
            guard let data = results as! [String:Any]? else {
                let userInfo = [NSLocalizedDescriptionKey : "No photos returned"]
                completionHandler(0, nil, NSError(domain: "getPhotos", code: 1, userInfo: userInfo))
                return
            }

            // verify photos and photo keys in results
            guard let photosDictionary = data[FlickrClient.ParameterValues.Photos] as? [String:AnyObject],  let photoArray = photosDictionary[FlickrClient.ParameterValues.Photo] as? [[String:AnyObject]] else {
                let userInfo = [NSLocalizedDescriptionKey : "Cannot find keys '\(FlickrClient.ParameterValues.Photos)' and '\(FlickrClient.ParameterValues.Photo)' in \(data)"]
                completionHandler(0, nil, NSError(domain: "getPhotos", code: 1, userInfo: userInfo))
                
                return
            }
            
//            print("PhotoArray count = \(photoArray.count)")
            var photoURLS = [String]()
            for pic in photoArray{
                photoURLS.append(pic[FlickrClient.ParameterValues.SquarePicURL] as! String)
            }
            if let pages = photosDictionary[FlickrClient.ParameterKeys.Pages] as? Int {
            // Return array of photo URLs and page count
                completionHandler(pages,photoURLS,nil)
            }
            else{
              completionHandler(0,photoURLS,nil)
            }
            return

        })
        
        
    }
    
    func getImage(urlString: String, completionHandler: @escaping (_ results:Any?,_ error:NSError?)->()){
        DispatchQueue.global(qos: .userInitiated).async {

            do{
                let url = URL(string: urlString)
                let imageData = try Data(contentsOf: url!)
                completionHandler(imageData,nil)
            }
            catch let error as NSError {
                completionHandler(nil,error)
            }
        }
    
    }
    
    //MARK: Networking
    func queryFlickr(_ parameters: [String:AnyObject], completionHandlerForQuery: @escaping ( _ results: Any?, _ error: NSError?) -> Void){
        let url = flickrURLFromParameters(parameters)
        let request = URLRequest(url: url)
        let session = URLSession.shared
        var task = session.dataTask(with: request as URLRequest) { data, response, error in
            func sendError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForQuery(nil, NSError(domain: "makeRequest", code: 1, userInfo: userInfo))
            }
            if error != nil { 
                sendError((error?.localizedDescription)!)
                return
            }
            // GUARD: Did we get a successful 2XX response?
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else{
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            guard  statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned status code: \(HTTPURLResponse.localizedString(forStatusCode:statusCode))")
                return
            }
            
            // GUARD: Was there any data returned?
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            //            print(NSString(data: data, encoding: String.Encoding.utf8.rawValue)!)
            
            
            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForQuery)
            
        }
        task.resume()
    }
    
    // MARK: Helper functions
    
    fileprivate func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = FlickrClient.Constants.ApiScheme
        components.host = FlickrClient.Constants.ApiHost
        components.path = FlickrClient.Constants.SessionPath
        components.queryItems = [URLQueryItem]()
        //add  parameters required by all queries
        var allParameters = parameters
        allParameters[FlickrClient.ParameterKeys.APIKey] = FlickrClient.ParameterValues.APIKey as AnyObject?
        allParameters[FlickrClient.ParameterKeys.NoJSONCallback] = FlickrClient.ParameterValues.DisableJSONCallback as AnyObject!
        
        for (key, value) in allParameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }

        return components.url!
    }
    
    // given raw JSON, return a usable Foundation object
    private func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsedResult: AnyObject! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(parsedResult, nil)
    }
    

    // MARK: Shared Instance
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }

}
