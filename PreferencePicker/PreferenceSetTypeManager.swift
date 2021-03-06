//
//  PreferenceSetTypeManager.swift
//  PreferencePicker
//
//  API for Preference Set Types for View Controllers
//  Created by Kevin Connor on 2/22/16.
//  Copyright © 2016 Kevin Connor. All rights reserved.
//

import Foundation
import MediaPlayer
import Photos

class PreferenceSetTypeManager {
    static let types = [
        PreferenceSetTypeIds.iTunesPlaylist: iTunesPreferenceSetType(),
        PreferenceSetTypeIds.photoMoment: photoPreferenceSetType()
    ] as [String : Any]
    
    static func allPreferenceSetTypes() -> [PreferenceSetType] {
        var typeArray = [PreferenceSetType]()
        for type in types {
            typeArray.append(type.value as! PreferenceSetType)
        }
        return typeArray
    }
    
    static func getSetType(_ psId: String) -> PreferenceSetType {
       return types[psId] as! PreferenceSetType
    }
    
}

struct PreferenceSetTypeIds {
    static let iTunesPlaylist = "iTunesPlayList"
    static let photoMoment = "photoMoment"
}

// pass-through container that enables PreferenceSetType
// protocol to support different PreferenceSetItem types
// with the same view and persistence layer code.
// PST implementations know which variable(s) to fill and use internally
// but that is abstracted from view and persistence layers
class PreferenceSetItemCollection {
    var mpmic: MPMediaItemCollection?
    var mpmi: [MPMediaItem]?
    var phac: PHAssetCollection?
}

protocol PreferenceSetType {
    static var importable: Bool { get }
    static var creatable: Bool { get }
    var description: String { get }
    var id: String { get }
    
    func getAvailableSetsForImport() -> [PreferenceSetItemCollection]
    func displayNameForCandidateSet(_ candidateSet: PreferenceSetItemCollection) -> String
    func itemDetailForDisplay(_ candidateSet:PreferenceSetItemCollection) -> String
    func nameForItemsOfThisType(_ count: Int) -> String
    func createPreferenceSet(_ candidateSet: PreferenceSetItemCollection, title: String) -> PreferenceSet
    func createPreferenceItemCollectionFromMOs(_ managedSet: [PreferenceSetItemMO]) -> PreferenceSetItemCollection
}

class iTunesPreferenceSetType: PreferenceSetType {
    static var importable = true
    static var creatable = false
    var description = "iTunes Playlist"
    var id = PreferenceSetTypeIds.iTunesPlaylist
    
    func getAvailableSetsForImport() -> [PreferenceSetItemCollection] {
      var output = [PreferenceSetItemCollection]()
        for collection in MPMediaQuery.playlists().collections! {
            let gc = PreferenceSetItemCollection()
            gc.mpmic = collection
            output.append(gc)
        }
        return output
    }
    
    func displayNameForCandidateSet(_ candidateSet: PreferenceSetItemCollection) -> String {
        let playlist = candidateSet.mpmic as! MPMediaPlaylist
        return playlist.name!
    }
    func itemDetailForDisplay(_ candidateSet: PreferenceSetItemCollection) -> String {
        let count = candidateSet.mpmic!.count
        return "\(count) \(self.nameForItemsOfThisType(count))"
    }

    func nameForItemsOfThisType(_ count: Int) -> String {
        return (count > 1 ? "songs" : "song")
    }
    
    func createPreferenceSet(_ candidateSet: PreferenceSetItemCollection, title: String) -> PreferenceSet {
        var items: [MPMediaItem]
        if candidateSet.mpmic != nil {
            items = candidateSet.mpmic!.items
        } else {
            items = candidateSet.mpmi!
        }
        
        return iTunesPlaylistPreferenceSet(candidateItems: items, title: title)
    }
    
    func createPreferenceItemCollectionFromMOs(_ managedSet: [PreferenceSetItemMO]) -> PreferenceSetItemCollection {
            let mediaItemArray = MPMediaQuery.songs().items!
            let collection = PreferenceSetItemCollection()
            collection.mpmi = [MPMediaItem]()
            for mediaItem in mediaItemArray {
                let castedId = NSNumber(value: mediaItem.persistentID as UInt64)
                if managedSet.contains(where: {$0.id! == castedId}) {
                    collection.mpmi!.append(mediaItem)
                }
            }
            return collection
    }
    
}

class photoPreferenceSetType: PreferenceSetType {
    static var importable = true
    static var creatable = false
    var description = "Photo Moments"
    var id = PreferenceSetTypeIds.photoMoment
    
    func getAvailableSetsForImport() -> [PreferenceSetItemCollection] {
        var output = [PreferenceSetItemCollection]()
        
        // this is not the world's finest api, Apple
        let fetchResult = PHAssetCollection.fetchMoments(with: nil)
        print("\(fetchResult.count)")
        fetchResult.enumerateObjects({(object: AnyObject!,
            count: Int,
            stop: UnsafeMutablePointer<ObjCBool>) in
            let collection = object as! PHAssetCollection
            let gc = PreferenceSetItemCollection()
            gc.phac = collection
            output.append(gc)
            
        })
        return output
    }
    
    func displayNameForCandidateSet(_ candidateSet: PreferenceSetItemCollection) -> String {
        return candidateSet.phac!.localizedTitle ?? "(No Title Available)"
    }
    
    func itemDetailForDisplay(_ candidateSet: PreferenceSetItemCollection) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.short
        dateFormatter.timeStyle = DateFormatter.Style.short
        return ("\(dateFormatter.string(from: candidateSet.phac!.startDate!)) - \(dateFormatter.string(from: candidateSet.phac!.endDate!))")
    }
    
    func nameForItemsOfThisType(_ count: Int) -> String {
        return (count > 1 ? "photos" : "photo")
    }
    
    func createPreferenceSet(_ candidateSet: PreferenceSetItemCollection, title: String) -> PreferenceSet {
        var items = [PHAsset]()
        // this seems awkward...
        if candidateSet.phac != nil {
            let fetchResult = PHAsset.fetchAssets(in: candidateSet.phac!, options: nil)
            fetchResult.enumerateObjects({(object: AnyObject!,
                count: Int,
                stop: UnsafeMutablePointer<ObjCBool>) in
                let item = object as! PHAsset
                items.append(item)
            })
        }
        
        return photoMomentPreferenceSet(candidateItems: items, title: "title")
    }
    
    func createPreferenceItemCollectionFromMOs(_ managedSet: [PreferenceSetItemMO]) -> PreferenceSetItemCollection {
        return PreferenceSetItemCollection()
    }
}
