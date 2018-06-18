//
//  Pin+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Kyle Stokes on 6/13/18.
//  with attribution to nsutanto
//  https://github.com/nsutanto/ios-VirtualTourist/blob/master/VirtualTourist/Model/CoreData/Location.swift
//  Copyright © 2018 Kyle Stokes. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Pin)
public class Pin: NSManagedObject {
    convenience init(longitude: Double, latitude: Double, context: NSManagedObjectContext) {
        
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: ent, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
        } else {
            fatalError("Unable to find Pin in entities!")
        }
    }
}
