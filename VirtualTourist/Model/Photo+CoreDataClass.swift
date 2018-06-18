//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Kyle Stokes on 6/13/18.
//  with attribution to nsutanto
//  https://github.com/nsutanto/ios-VirtualTourist/blob/master/VirtualTourist/Model/CoreData/Image.swift
//  Copyright © 2018 Kyle Stokes. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Photo)
public class Photo: NSManagedObject {
    convenience init(photoURL: String, photoData: NSData?, context: NSManagedObjectContext) {
        
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: ent, insertInto: context)
            self.imageURL = photoURL
            self.image = photoData
        } else {
            fatalError("Unable to find Photo in entities!")
        }
    }
}
