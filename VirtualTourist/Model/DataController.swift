//
//  DataController.swift
//  VirtualTourist
//
//  Created by Kyle Stokes on 5/16/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    
    let persistantContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return persistantContainer.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext!
    
    init(modelName: String) {
        persistantContainer = NSPersistentContainer(name: modelName)
    }
    
    func configureContexts() {
        backgroundContext = persistantContainer.newBackgroundContext()
        
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistantContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            guard error == nil else {
                fatalError(error.debugDescription)
            }
            self.autoSaveViewContext()
            self.configureContexts()
            completion?()
        })
    }
}

// MARK: - Autosave

extension DataController {
    func autoSaveViewContext(interval: TimeInterval = 30) {
        print("autosaving")
        guard interval > 0 else {
            print("Can't autosave on negative interval")
            return
        }
        
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("Unable to autosave changes")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: {(
            self.autoSaveViewContext(interval: interval)
            )})
    }
}

// MARK: - Background processing
// https://github.com/nsutanto/ios-VirtualTourist/blob/master/VirtualTourist/Model/CoreData/CoreDataStack.swift
extension DataController {
    
    typealias Batch = (_ workerContext: NSManagedObjectContext) -> ()
    
    func performBackgroundOperation(_ batch: @escaping Batch) {
        
        backgroundContext.perform() {
            
            batch(self.backgroundContext)
            
            do {
                try self.backgroundContext.save()
            } catch {
                fatalError("Error while saving backgroundContext: \(error)")
            }
        }
    }
}
