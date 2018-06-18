//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Kyle Stokes on 6/10/18.
//  with attribution to nsutanto
//  https://github.com/nsutanto/ios-VirtualTourist/blob/master/VirtualTourist/Model/Flickr/FlickrClient.swift
//  Copyright © 2018 Kyle Stokes. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class FlickrClient: NSObject  {
    
    // Shared session
    var session = URLSession.shared
    
    // MARK: Initializers
    
    override init() {
        super.init()
    }
    
    // Get all photo URLs for pin
    func getPhotoURLsForLocation(_ latitude: Double, _ longitude: Double, _ pageNumber: Int = 1, completionHandlerPhotos: @escaping (_ result: [String]?, _ numberOfPages: Int?, _ error: NSError?)
        -> Void) {
        
        // 1. Specify parameters
        let request = URLRequest(url: URL(string: "\(Constants.Flickr.APIBaseURL)?\(Constants.FlickrParameterKeys.Method)=\(Constants.FlickrParameterValues.PhotosSearchMethod)&\(Constants.FlickrParameterKeys.APIKey)=\(Constants.FlickrParameterValues.APIKey)&\(Constants.FlickrParameterKeys.Latitude)=\(String(latitude))&\(Constants.FlickrParameterKeys.Longitude)=\(String(longitude))&\(Constants.FlickrParameterKeys.Extras)=\(Constants.FlickrParameterValues.SquareURL)&\(Constants.FlickrParameterKeys.PerPage)=\(Constants.FlickrParameterValues.TwentyOne)&\(Constants.FlickrParameterKeys.Page)=\(String(pageNumber))&\(Constants.FlickrParameterKeys.Format)=\(Constants.FlickrParameterValues.ResponseFormat)&\(Constants.FlickrParameterKeys.NoJSONCallback)=\(Constants.FlickrParameterValues.DisableJSONCallback)")!)
        
        // 2. Make the request
        let _ = performRequest(request: request) { (parsedResult, error) in
            
            func displayError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerPhotos(nil, nil, NSError(domain: "getPhotoURLsForLocation", code: 1, userInfo: userInfo))
            }
            
            // 3. Send the desired value(s) to completion handler
            if let error = error {
                displayError("\(error)")
            } else {
                
                /* GUARD: Did Flickr return an error (stat != ok)? */
                guard let stat = parsedResult![Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                    displayError("Flickr returned error!")
                    return
                }
                
                /* GUARD: Is the "photos" keys in our result? */
                guard let photosDictionary = parsedResult![Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                    displayError("'Photos' key not in result!")
                    return
                }
                
                /* GUARD: Is the "pages" key in our result? */
                guard let pages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                    displayError("'Pages' key not in result!")
                    return
                }
                
                /* GUARD: Is the "photo" key in photosDictionary? */
                guard let photos = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                    displayError("'Photo' key not in result!")
                    return
                }
                
                var photoURLs = [String]()
                
                for photo in photos {
                    let photoDictionary = photo as [String:Any]
                    
                    /* GUARD: Does our photo have a key for 'url_q'? */
                    guard let photoURL = photoDictionary[Constants.FlickrResponseKeys.SquareURL] as? String else {
                        displayError("'url_q' key not in result!")
                        return
                    }
                    
                    photoURLs.append(photoURL)
                }
                
                completionHandlerPhotos(photoURLs, pages, nil)
            }
        }
    }
    
    func convertURLToPhotoData(photoURL: String, completionHandler: @escaping(_ photoData: Data?, _ error: NSError?) ->  Void) -> URLSessionTask {
        
        let url = URL(string: photoURL)
        let request = URLRequest(url: url!)
        
        let task = session.dataTask(with: request) {data, response, downloadError in
            
            if downloadError != nil {
                // Cancel task
            } else {
                completionHandler(data, nil)
            }
        }
        task.resume()
        return task
    }
    
    // This abstracts the guard statements for requests to one location
    private func performRequest(request: URLRequest,
                                completionHandlerRequest: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void)
        -> URLSessionDataTask {
            
            let task = session.dataTask(with: request as URLRequest) { data, response, error in
                
                func sendError(_ error: String) {
                    print(error)
                    let userInfo = [NSLocalizedDescriptionKey : error]
                    completionHandlerRequest(nil, NSError(domain: "performRequest", code: 1, userInfo: userInfo))
                }
                
                /* GUARD: Was there an error? */
                guard (error == nil) else {
                    sendError("There was an error with your request: \(error!)")
                    return
                }
                
                /* GUARD: Did we get a successful 2XX response? */
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                    let httpError = (response as? HTTPURLResponse)?.statusCode
                    sendError("Your request returned a status code : \(String(describing: httpError))")
                    return
                }
                
                /* GUARD: Was there any data returned? */
                guard let data = data else {
                    sendError("No data was returned by the request!")
                    return
                }
                
//                print(String(data: data, encoding: String.Encoding.utf8)!)
                
                self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerRequest)
            }
            
            task.resume()
            
            return task
    }
    
    // When given raw JSON, return a usable Foundation object
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

