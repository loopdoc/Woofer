//
//  Breed.swift
//  Woofer
//
//  Created by Chris on 12/12/19.
//  Copyright © 2019 WellKeep. All rights reserved.
//

import Foundation

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

struct Breed : Hashable, Comparable {
    static let allBreedsListSource = "https://dog.ceo/api/breeds/list/all"
    
    static func < (lhs: Breed, rhs: Breed) -> Bool {
        return lhs.displayName < rhs.displayName
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

    var displayName : String {
        if let subbreedName = subbreedName {
            return "\(subbreedName) \(name)"
        } else {
            return "\(name)"
        }
    }
    let specials : [String]
    let identifier = UUID()

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    static func ==(lhs: Breed, rhs: Breed) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    func contains(query: String?) -> Bool {
        guard let query = query else { return true }
        guard !query.isEmpty else { return true }
        let lowerCasedQuery = query.lowercased()
        return name.lowercased().contains(lowerCasedQuery) || (subbreedName?.lowercased().contains(lowerCasedQuery) ?? false)
    }
    
    static func processNamedBreeds(_ breedNames : [String : [String]]) -> [Breed] {
        var processedBreeds : [Breed] = []
        for (breedName, subbreedNames) in breedNames {
            if subbreedNames.count == 0 {
                let newBreed = Breed(name: breedName, subbreedName: nil, specials: [])
                processedBreeds.append(newBreed)
            } else {
                for subbreedName in subbreedNames {
                    let newBreed = Breed(name: breedName, subbreedName: subbreedName, specials: [])
                    processedBreeds.append(newBreed)
                }
            }
        }
        return processedBreeds
    }
    
}
