//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Kyle Stokes on 6/14/18.
//  Copyright © 2018 Kyle Stokes. All rights reserved.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var image: NSData?
    @NSManaged public var imageURL: String?
    @NSManaged public var pin: Pin?

}
