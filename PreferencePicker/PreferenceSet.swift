//
//  PreferenceSet.swift
//  PreferencePicker
//
//  Created by Kevin Connor on 2/22/16.
//  Copyright © 2016 Kevin Connor. All rights reserved.
//

import Foundation
import MediaPlayer
import CoreData
import Photos

// PHAsset are persistently identified by strings
// MPMediaItem are persistently identified by UInt64
// so, create an in-memory id on import/load
// and only use the persistent ids for persistence layer
// typealias in case Int is no good sometime in the future
typealias MemoryId = Int

// PreferenceSet protocol provides APIs for the presentation
// and modification of PreferenceSet in view controllers and
// persistence layer
protocol PreferenceSet {
    var title: String {get set }
    var preferenceSetType: String { get set }
    
    //might want more flexibility here eventually by implementing scoreManager protocol
    var scoreManager: ELOManager { get set }
    func itemCount() -> Int
    func getItemsForComparison() -> [PreferenceSetItem]
    func getItemByIndex(_ index: Int) -> PreferenceSetItem
    func getNextMemoryId() -> Int
    func getAllItems() -> [PreferenceSetItem]
    func registerComparison(_ id1: MemoryId, id2: MemoryId, result: MemoryId)
    func updateRatings()
    func returnSortedPreferenceScores() -> [(MemoryId, Double)]
    func getItemById(_ id: MemoryId) -> PreferenceSetItem?
    func getPreferenceScoreById(_ id: MemoryId) -> PreferenceScore?
    func getAllComparisons() -> [Date: Comparison]
    func getAllPreferenceScores() -> [MemoryId: PreferenceScore]
    func restoreScoreManagerScores(_ candidateComparisons: [Comparison], candidateScores: [MemoryId: Double])
    func getMemoryIdByPreferenceSetItemMO(_ item: PreferenceSetItemMO) -> MemoryId
    func getMemoryIdsFromManagedComparison(_ comparison: ComparisonMO) -> MemoryIdResult
    func buildComparisonArrayFromMOs(_ managedComparisons: [ComparisonMO]) -> [Comparison]
    func buildScoreArrayFromMOs(_ managedScores: [PreferenceScoreMO]) -> [MemoryId: Double]
}

struct MemoryIdResult {
    var id1: MemoryId
    var id2: MemoryId
    var result: MemoryId
}

// PreferenceSetBase holds common logic for determining
// and storing user preferences about the items in the set
// and common PreferenceSet persistence layer accessors
class PreferenceSetBase : PreferenceSet {
    var title = String()
    var preferenceSetType = String()
    static var appDelegate =
    UIApplication.shared.delegate as? AppDelegate
    var scoreManager = ELOManager()
    fileprivate var items = [PreferenceSetItem]()
    fileprivate var keyedItems = [MemoryId : PreferenceSetItem]()
    fileprivate var memoryId = 0
    
    init(title: String) {
        self.title = title
    }

    func itemCount() -> Int {
        return items.count
    }

    func getItemsForComparison() -> [PreferenceSetItem] {
        let ids = scoreManager.getIdsForComparison()
        return [keyedItems[ids[0]]!, keyedItems[ids[1]]!]
    }
    
    func getItemByIndex(_ index: Int) -> PreferenceSetItem {
        return items[index]
    }
    
    func getNextMemoryId() -> Int {
        let ret = memoryId
        memoryId = memoryId + 1
        return ret
    }

    func getItemById(_ id: MemoryId) -> PreferenceSetItem? {
        return keyedItems[id]
    }
    
    func getAllItems() -> [PreferenceSetItem] {
        return items
    }
    
    func registerComparison(_ id1: MemoryId, id2: MemoryId, result: MemoryId) {
        self.scoreManager.createAndAddComparison(id1, id2: id2, result: result)
    }
    
    func getAllComparisons() -> [Date: Comparison] {
        return self.scoreManager.getAllComparisons() as [Date : Comparison]
    }
    
    func getAllPreferenceScores() -> [MemoryId: PreferenceScore] {
        return self.scoreManager.getAllPreferenceScores()
    }
    
    func getPreferenceScoreById(_ id: MemoryId) -> PreferenceScore? {
        return self.scoreManager.getPreferenceScoreById(id)
    }
    
    func updateRatings() {
        self.scoreManager.update()
        //might need to update model here...
        PreferenceSetBase.update(self)

    }
    
    func returnSortedPreferenceScores() -> [(MemoryId, Double)] {
        return self.scoreManager.getUpdatedSortedPreferenceScores()
    }
 
    func restoreScoreManagerScores(_ candidateComparisons: [Comparison], candidateScores: [MemoryId: Double]) {
        do {
           try scoreManager.restoreComparisons(candidateComparisons, candidateScores: candidateScores)
        } catch let error as ManagerError {
            ELOManager.errorHandler(error: error)
        }
        catch {
            print("Error restoring scores")
        }
    }
    
    //Decided to manage all persistence layer api
    //through PreferenceSetBase. That will make it easier to
    //swap persistence layers
    
    // not crazy about how these build* methods wound up...
    // among other things, they will be fragile as MemoryId typedef changes
    // decided to live with it for now
    func buildComparisonArrayFromMOs(_ managedComparisons: [ComparisonMO]) -> [Comparison] {
        var comparisons = [Comparison]()
        
        do {
            for managedComparison in managedComparisons {
                let memoryIdResult = getMemoryIdsFromManagedComparison(managedComparison)
                comparisons.append(try Comparison(id1: memoryIdResult.id1, id2: memoryIdResult.id2, result: memoryIdResult.result, timestamp: managedComparison.timestamp!))
            }
        }
        catch let error as ManagerError {
            ELOManager.errorHandler(error: error)
        }
        catch {
            print("Error creating comparison")
        }
        
        return comparisons
    }
    
    func buildScoreArrayFromMOs(_ managedScores: [PreferenceScoreMO]) -> [MemoryId: Double] {
        var output = [MemoryId: Double]()
        var memoryId = 0
        for managedScore in managedScores {
            memoryId = getMemoryIdByPreferenceSetItemMO(managedScore.preferenceSetItem!)
            output[memoryId] = managedScore.score!.doubleValue
        }
        return output
    }
    
    static func updateActiveSetForModel(_ setMO: PreferenceSetMO) {
        appDelegate!.dataController!.updateActiveSetMO(setMO)
    }
    
    static func create(_ preferenceSet: PreferenceSet) {
        appDelegate!.dataController!.createSetMO(preferenceSet)
    }
    
    static func update(_ preferenceSet: PreferenceSet) {
        appDelegate!.dataController!.updateSetMO(preferenceSet)
    }
    
    static func getAllSavedSets() -> [PreferenceSetMO] {
        return appDelegate!.dataController!.getAllSavedSets()
    }
    
    // these need to be overridden by specific type
    func getMemoryIdByPreferenceSetItemMO(_ item: PreferenceSetItemMO) -> MemoryId {
        return -1
    }
    func getMemoryIdByPreferenceScoreMO(_ scoreMO: PreferenceScoreMO) -> MemoryId {
        return -1
    }

    func getMemoryIdsFromManagedComparison(_ comparison: ComparisonMO) -> MemoryIdResult {
        let items = comparison.preferenceSetItem!.allObjects as! [PreferenceSetItemMO]
        var result = 0
        let id1 = getMemoryIdByPreferenceSetItemMO(items[0])
        let id2 = getMemoryIdByPreferenceSetItemMO(items[1])
        
        if (comparison.result! == items[0].id) {
            result = id1
        } else if (comparison.result! == items[0].id) {
            result = id2
        }
        return MemoryIdResult(id1: id1,
                            id2: id2,
                            result: result)
    }
}

// Preference Sets should conform to PreferenceSet, and subclass PreferenceSetBase

// would love to figure out how to classname this programmatically, e.g. PreferenceSetTypeIds.iTunesPlaylist
class iTunesPlaylistPreferenceSet : PreferenceSetBase {
    var referencedItems = [UInt64 : MemoryId]()
    
    init(candidateItems: [MPMediaItem], title: String) {
        super.init(title: title)
        super.preferenceSetType = PreferenceSetTypeIds.iTunesPlaylist
        
        for item in candidateItems {
            let newiTunesItem = iTunesPreferenceSetItem(candidateItem: item, set: self)
            items.append(newiTunesItem)
            keyedItems[newiTunesItem.memoryId] = newiTunesItem
            referencedItems[item.persistentID] = newiTunesItem.memoryId
        }
        self.scoreManager.initializeComparisons(items)
    }
    
    override func getMemoryIdByPreferenceSetItemMO(_ item: PreferenceSetItemMO) -> MemoryId {
        return self.referencedItems[UInt64(truncating: item.id!)] ?? -1
    }
}

// would love to figure out how to classname this programmatically, e.g. PreferenceSetTypeIds.iTunesPlaylist
class photoMomentPreferenceSet : PreferenceSetBase {
    
    init(candidateItems: [PHAsset], title: String) {
        super.init(title: title)
        super.preferenceSetType = PreferenceSetTypeIds.photoMoment
        
        for item in candidateItems {
            let newItem = photoMomentPreferenceSetItem(candidateItem: item, set: self)
            items.append(newItem)
            keyedItems[newItem.memoryId] = newItem
        }
        
        self.scoreManager.initializeComparisons(items)
    }
    
}
