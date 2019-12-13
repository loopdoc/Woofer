//
//  PoochCollectionViewCell.swift
//  Woofer
//
//  Created by Chris on 12/12/19.
//  Copyright © 2019 WellKeep. All rights reserved.
//

import UIKit

class PoochCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "PoochCollectionViewCell"

    var poochPicture : PoochPicture? {
        didSet {
            imageView.image = poochPicture?.thumbnail
        }
    }
    
    @IBOutlet var imageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        NotificationCenter.default.removeObserver(self, name: PoochPicture.imageFetchedNotificationNotificationName, object: poochPicture?.urlString)
    }
    
    func configure(_ poochPicture: PoochPicture) {
        if poochPicture.thumbnail == nil {
            listenForImageUpdateNotification(poochPicture.urlString)
            poochPicture.fetchImage()
        }
        self.poochPicture = poochPicture
        
    }

    func listenForImageUpdateNotification(_ string: String) {                NotificationCenter.default.addObserver(self, selector: #selector(PoochCollectionViewCell.reloadImage), name: PoochPicture.imageFetchedNotificationNotificationName, object: string)
    }
}

extension PoochCollectionViewCell {
    //MARK: - Image Notification

    @objc func reloadImage() {
        guard Thread.current.isMainThread == true else {
            DispatchQueue.main.async {
                self.reloadImage()
            }
            return
        }
        imageView.image = poochPicture?.thumbnail
    }
}

