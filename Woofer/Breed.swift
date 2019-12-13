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
    
    func encode(to encoder: Encoder) throws {  }
}

final class Breed : Hashable, PoochPictureDelegate {
    
    static let allBreedsListSource = "https://dog.ceo/api/breeds/list/all"
    static let breedsImagesPrefix = "https://dog.ceo/api/breed/"
    static let breedsImagesPostfix = "/images"
    
    let name : String
    let subbreedName: String?
    
    var poochPictures : [PoochPicture] = []
    
    var displayName : String {
        if let subbreedName = subbreedName {
            return "\(subbreedName) \(name)"
        } else {
            return "\(name)"
        }
    }
    
    let identifier = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    let imageFetchOperationQueue = OperationQueue()
    
    init(name: String, subbreedName: String? = nil) {
        self.name = name
        self.subbreedName = subbreedName
        imageFetchOperationQueue.maxConcurrentOperationCount = 3
    }
    
    
}

extension Breed : Comparable {
    //MARK: Comparison
    
    static func < (lhs: Breed, rhs: Breed) -> Bool {
        return lhs.displayName < rhs.displayName
    }
    
    static func ==(lhs: Breed, rhs: Breed) -> Bool {
        return lhs.identifier == rhs.identifier
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
    
}

extension Breed {
    //MARK: Queue Management
    
    func suspendImageFetching(){
        imageFetchOperationQueue.isSuspended = true
    }
    
    func resumeImageFetching(){
        imageFetchOperationQueue.isSuspended = false
    }
    
}

extension Breed {
    //MARK: - Fetch and Process Image Sources
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
            autoreleasepool{
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
    }
    
    class func processBreedImageSources(_ breeds : [Breed], breedImageSources: [String]) {
        autoreleasepool {
            if breeds.count == 1 {
                guard let breed = breeds.first else { return }
                breed.poochPictures = breedImageSources.map{ PoochPicture(urlString: $0, delegate: breed)}
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
                    breed.poochPictures = subbreedImageSources.map { PoochPicture(urlString: $0, delegate: breed)
                    }
                }
            }
        }
    }
    
}
