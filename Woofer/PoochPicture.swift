//
//  PoochPicture.swift
//  Woofer
//
//  Created by Chris on 12/12/19.
//  Copyright © 2019 WellKeep. All rights reserved.
//

import UIKit

protocol PoochPictureDelegate : class {
    var imageFetchOperationQueue : OperationQueue { get }
}

final class PoochPicture : Comparable, Hashable {

    static let imageFetchedNotificationNotificationString = "PoochPicture.ImageChangeNotificationString"
    static let imageFetchedNotificationNotificationName = Notification.Name(rawValue: PoochPicture.imageFetchedNotificationNotificationString)
    
    static func < (lhs: PoochPicture, rhs: PoochPicture) -> Bool {
        return lhs.imageFetchTimestamp > rhs.imageFetchTimestamp
    }

    static func == (lhs: PoochPicture, rhs: PoochPicture) -> Bool {
        return lhs.urlString == rhs.urlString
    }

    weak var delegate : PoochPictureDelegate?
    
    var urlString : String
    var image : UIImage?
    var thumbnail: UIImage?

    var imageFetchTimestamp = Date.distantFuture
    let identifier = UUID()

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    init(urlString: String, delegate: PoochPictureDelegate) {
        self.urlString = urlString
        self.delegate = delegate
    }
    
}

extension PoochPicture {
    static let storeFullImages = false

    //MARK: - Fetching
    func fetchImage() {
        guard let operationQueue = delegate?.imageFetchOperationQueue else { return }
        operationQueue.addOperation { [unowned self] in
            guard let url = URL(string: self.urlString)
                , let data = try? Data(contentsOf: url) else { return }

            if PoochPicture.storeFullImages == true,
                let image = UIImage(data: data) {
                self.image = image
            }
            self.thumbnail = self.thumbnail(data, size: 95.0)
            self.imageFetchTimestamp = Date()
            self.postImageFetchedNotificationNotification()
        }
    }

    func postImageFetchedNotificationNotification() {
        let notification = Notification(name: PoochPicture.imageFetchedNotificationNotificationName, object: urlString)
        DispatchQueue.main.async {
            NotificationCenter.default.post(notification)
        }
    }
    
    private func thumbnail(_ imageData: Data, size: CGFloat) -> UIImage? {
        guard let imageSource = CGImageSourceCreateWithData((imageData as CFData) , nil) else { return nil }
        let options: [NSString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: size / 2.0,
            kCGImageSourceCreateThumbnailFromImageAlways: true
        ]
        let scaledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary).flatMap { UIImage(cgImage: $0) }
        return scaledImage
    }

}
