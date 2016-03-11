//
//  PreferenceSetDataController.swift
//  PreferencePicker
//
//  Created by Kevin Connor on 3/9/16.
//  Copyright © 2016 Kevin Connor. All rights reserved.
//

import Foundation
import CoreData
import MediaPlayer

class PreferenceSetDataController : NSObject {
    var managedObjectContext: NSManagedObjectContext
    
    // store 
    var activeSet: PreferenceSetMO?
    var activeItems: [Int: PreferenceSetItemMO]?
    
    override init() {
        self.managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        //self.activeSet = PreferenceSetMO()
        //self.activeItems = self.getAllSavedItems()
        super.init()
        
        guard let modelURL = NSBundle.mainBundle().URLForResource("PreferenceSet", withExtension:"momd") else {
            fatalError("Error loading model from bundle")
        }
        // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
        guard let mom = NSManagedObjectModel(contentsOfURL: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)

        self.managedObjectContext.persistentStoreCoordinator = psc
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
            let docURL = urls[urls.endIndex-1]
            /* The directory the application uses to store the Core Data store file.
            This code uses a file named "PreferenceSetDataModel.sqlite" in the application's documents directory.
            */
            let storeURL = docURL.URLByAppendingPathComponent("PreferenceSetDataModel.sqlite")
            do {
                try psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
            } catch {
                fatalError("Error migrating store: \(error)")
            }
        }
    }
    
    private func fetcher(entityName: String, predicate: NSPredicate?) -> [AnyObject] {
        let moc = self.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: entityName)
        if predicate != nil {
            fetchRequest.predicate = predicate!
        }
        do {
            let fetched = try moc.executeFetchRequest(fetchRequest)
            return fetched
        } catch {
            fatalError("Failed to fetch \(entityName): \(error)")
        }
    }
    
    private func getAllSavedSets () -> [PreferenceSetMO] {
        return self.fetcher("PreferenceSet", predicate: nil) as! [PreferenceSetMO]
    }
    
    private func getAllSavedPSItems() -> [PreferenceSetItemMO] {
        var existingItems = self.fetcher("PreferenceSetItem", predicate: nil) as! [PreferenceSetItemMO]
        if existingItems.count == 0 {
            existingItems = [PreferenceSetItemMO()]
        }
        return existingItems
    }
    
    private func fetchPSItem(id: Int64) -> PreferenceSetItemMO? {
        let itemPredicate = NSPredicate(format: "id is[c] %@", id)
        return self.fetcher("PreferenceSetItem", predicate: itemPredicate)[0] as? PreferenceSetItemMO
    }
    
    func save (preferenceSet: PreferenceSet) {
        var managedSet = NSEntityDescription.insertNewObjectForEntityForName("PreferenceSet", inManagedObjectContext: self.managedObjectContext) as! PreferenceSetMO
        managedSet.setValue(preferenceSet.title, forKey: "title")
        managedSet.setValue(preferenceSet.preferenceSetType, forKey: "preferenceSetType")
        
        // existingItems only for recovery step
        //let existingItems = self.getAllSavedPSItems()
        for item in preferenceSet.getAllItems() {
            let setItem = Int64(item.mediaItem.persistentID)
            let existingItem = self.fetchPSItem(setItem)
            if existingItem != nil {
                // relate existingItem to the PreferenceSetMO just created
            } else {
                // try recovery when recovery is implemented
                // create new PreferenceSetItemMO for this persistent ID
            }
        }
        
        do {
            try self.managedObjectContext.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
    }
    
    func update(preferenceSet: PreferenceSet) {
        
    }
    
    func load(name: String, type: PreferenceSetType) -> PreferenceSet {

        return type.createPreferenceSet(MPMediaItemCollection(), title: "Test")
    }
    
}

class PreferenceSetMO: NSManagedObject {
    @NSManaged var title: String?
    @NSManaged var preferenceSetType: String?
}

class PreferenceSetItemMO: NSManagedObject {
    @NSManaged var id: NSNumber?
    @NSManaged var recoveryProp1: String?
    @NSManaged var recoveryProp2: String?
}