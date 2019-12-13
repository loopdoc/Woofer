//
//  Breed.swift
//  Woofer
//
//  Created by Chris on 12/12/19.
//  Copyright © 2019 WellKeep. All rights reserved.
//

import UIKit

struct BreedMessageCodeable: Codable {
    
    let message : [String : [String]]
    
    enum CodingKeys : String, CodingKey {
        case message
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.message = try container.decode([String : [String]].self, forKey: .message)
    }
    
    func encode(to encoder: Encoder) throws {
        //No-op, we're not using this but the stub needs to be here
        // for protocol conformance
    }
}

struct BreedImageMessageCodeable: Codable {
    
    let message : [String]
    
    enum CodingKeys : String, CodingKey {
        case message
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.message = try container.decode([String].self, forKey: .message)
    }
    
    func encode(to encoder: Encoder) throws {
        //No-op, we're not using this but the stub needs to be here
        // for protocol conformance
    }
}

final class Breed : Hashable, Comparable {
    static let allBreedsListSource = "https://dog.ceo/api/breeds/list/all"
    static let breedsImagesPrefix = "https://dog.ceo/api/breed/"
    static let breedsImagesPostfix = "/images"
    
    static func < (lhs: Breed, rhs: Breed) -> Bool {
        return lhs.displayName < rhs.displayName
    }

    static func ==(lhs: Breed, rhs: Breed) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    let name : String
    let subbreedName: String?
    var lookupName : String {
        if let subbreedName = subbreedName {
            return "\(name)-\(subbreedName)"
        } else {
            return "\(name)"
        }
    }
    
    var poochPictures : [PoochPicture] = []

    var displayName : String {
        if let subbreedName = subbreedName {
            return "\(subbreedName) \(name)"
        } else {
            return "\(name)"
        }
    }
    let identifier = UUID()
    
    init(name: String, subbreedName: String? = nil) {
        self.name = name
        self.subbreedName = subbreedName
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    

    func contains(_ query: String?) -> Bool {
        guard let query = query else { return true }
        guard !query.isEmpty else { return true }
        let lowerCasedQuery = query.lowercased()
        return name.lowercased().contains(lowerCasedQuery) || (subbreedName?.lowercased().contains(lowerCasedQuery) ?? false)
    }
    
    func hasPrefix(_ query: String?) -> Bool {
        guard let query = query else { return true }
        guard !query.isEmpty else { return true }
        let lowerCasedQuery = query.lowercased()
        return name.lowercased().hasPrefix(lowerCasedQuery) || (subbreedName?.lowercased().hasPrefix(lowerCasedQuery) ?? false)
    }
    
    class func processNamedBreeds(_ breedNames : [String : [String]]) -> [Breed] {
        var processedBreeds : [Breed] = []
        for (breedName, subbreedNames) in breedNames {
            if subbreedNames.count == 0 {
                let newBreed = Breed(name: breedName, subbreedName: nil)
                processedBreeds.append(newBreed)
                fetchImageSources([newBreed])
            } else {
                var newSubbreeds : [Breed] = []
                for subbreedName in subbreedNames {
                    let newBreed = Breed(name: breedName, subbreedName: subbreedName)
                    processedBreeds.append(newBreed)
                    newSubbreeds.append(newBreed)
                }
                fetchImageSources(newSubbreeds)
            }

        }
        return processedBreeds
    }
    
    class func fetchImageSources(_ breeds : [Breed]) {
        guard let breedName = breeds.first?.name else {
            assertionFailure("No breed name")
            return
        }
        let imageSourceString = breedsImagesPrefix + breedName + breedsImagesPostfix
        DispatchQueue.global(qos: .userInteractive).async {
            guard let url = URL(string: imageSourceString) else {
                assertionFailure("Can't create URL from imageSourceString")
                return
            }
            do {
                let data = try Data(contentsOf: url)
                let breedImageMessageCodeable = try JSONDecoder().decode(BreedImageMessageCodeable.self, from: data)
                processBreedImageSources(breeds, breedImageSources: breedImageMessageCodeable.message)
            } catch {
                return
            }
        }
    }
    
    /**
     The image sources that come from the server only do so based on the breed name with
     the subbreed images combined.  The text contains a "name-subbreedName"  So we
     use that to parse out the sources and assign to the Breed objects based on both
     name and subbreedName
     
     - Complexity: O(NxM) where N is number of breedImageSources and M is the number of breeds
     */
    class func processBreedImageSources(_ breeds : [Breed], breedImageSources: [String]) {
        if breeds.count == 1 {
            breeds.first?.poochPictures = breedImageSources.map{ PoochPicture(urlString: $0)}
        } else {
            let values = [[String]].init(repeating: [], count: breeds.count)
            let subbreedNames = breeds.compactMap{ $0.subbreedName }
            var imageSourcesBySubbreedName = Dictionary(uniqueKeysWithValues: zip(subbreedNames, values))
            for imageSourceString in breedImageSources {
                guard let startIndex = imageSourceString.firstIndex(of: "-") else { continue }
                let subbreedSourceString = imageSourceString[startIndex...]
                for subbreedName in subbreedNames {
                    if subbreedSourceString.dropFirst().hasPrefix(subbreedName) {
                        imageSourcesBySubbreedName[subbreedName]?.append(imageSourceString)
                        continue
                    }
                    
                }
            }
            for breed in breeds {
                guard let subbreedName = breed.subbreedName
                    , let subbreedImageSources = imageSourcesBySubbreedName[subbreedName] else { continue }
                breed.poochPictures = subbreedImageSources.map{ PoochPicture(urlString: $0)}
            }
        }
    }
    
}
