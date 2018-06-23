//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by Kyle Stokes on 6/7/18.
//  Copyright © 2018 Kyle Stokes. All rights reserved.
//

import UIKit
import MapKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let dataController = DataController(modelName: "VirtualTourist")
    var coordinates = [CLLocationDegrees]()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        dataController.load()
        
        // Inject dependency 'dataController' into LocationsController
        let navigationController = window?.rootViewController as! UINavigationController
        let locationsController = navigationController.topViewController as! LocationsController
        locationsController.dataController = dataController
        
        // Set default coordinate values
        coordinates.append(37.1328 as CLLocationDegrees)
        coordinates.append(-95.7855 as CLLocationDegrees)
        
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        UserDefaults.standard.set(coordinates, forKey: "centerCoordinate")
    }
}

