//
//  PoochPicture.swift
//  Woofer
//
//  Created by Chris on 12/12/19.
//  Copyright © 2019 WellKeep. All rights reserved.
//

import UIKit

class PoochPicture : Comparable, Hashable {

    static let imageFetchedNotificationNotificationString = "PoochPicture.ImageChangeNotificationString"
    static let imageFetchedNotificationNotificationName = Notification.Name(rawValue: PoochPicture.imageFetchedNotificationNotificationString)
    
    static func < (lhs: PoochPicture, rhs: PoochPicture) -> Bool {
        return lhs.imageFetchTimestamp < rhs.imageFetchTimestamp
    }

    static func == (lhs: PoochPicture, rhs: PoochPicture) -> Bool {
        return lhs.urlString == rhs.urlString
    }
    
    var urlString : String
    var image : UIImage? { // TODO: Use thumbnails
        didSet {
            imageFetchTimestamp = Date()
        }
    }

    var imageFetchTimestamp = Date.distantFuture
    let identifier = UUID()

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    init(urlString: String) {
        self.urlString = urlString
    }
    
}

extension PoochPicture {
    //MARK: - Fetching
    func fetchImage() {

        DispatchQueue.global(qos: .userInitiated).async {
            guard let url = URL(string: self.urlString)
                , let data = try? Data(contentsOf: url)
                , let image = UIImage(data: data) else { return }
            // Use the same context we've used all along to do
            // work on the managed object
            self.image = image
            self.postImageFetchedNotificationNotification()
        }
    }

    func postImageFetchedNotificationNotification() {
        let notification = Notification(name: PoochPicture.imageFetchedNotificationNotificationName, object: urlString)
        DispatchQueue.main.async {
            NotificationCenter.default.post(notification)
        }
    }
}
