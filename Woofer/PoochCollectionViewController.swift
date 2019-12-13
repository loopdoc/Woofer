//
//  PoochCollectionViewController.swift
//  Woofer
//
//  Created by Chris on 12/12/19.
//  Copyright © 2019 WellKeep. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

protocol PoochCollectionViewControllerDelegate : class {
    var shouldShowPoochPictures : Bool { get }
    var filteredBreeds : [Breed] { get }
}

class PoochCollectionViewController: UICollectionViewController {
    
    enum Section {
        case main
    }

    weak var delegate : PoochCollectionViewControllerDelegate?

    var poochPicturesByBreed : [Breed : [PoochPicture]] = [:]
    
    var poochImageSourcesByBreed : [Breed : [String]] = [:]
    
    var datasource : UICollectionViewDiffableDataSource<Breed, PoochPicture>! = nil
    
    var showPictures : Bool {
        let count = delegate?.filteredBreeds.count ?? 0
        return count > 0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureDataSource()
        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }

}

extension PoochCollectionViewController  {
    // MARK: - Diffable Data Source
    
    private func configureDataSource() {
        datasource = UICollectionViewDiffableDataSource<Breed, PoochPicture>(collectionView: collectionView){
            (collectionView : UICollectionView, indexPath: IndexPath, poochPicture: PoochPicture) -> UICollectionViewCell in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PoochCollectionViewCell.reuseIdentifier, for: indexPath) as! PoochCollectionViewCell
            cell.configure(poochPicture)
            return cell
        }
        // Initial data
        updateSnapshot(animated: false)
    }
    
    func updateSnapshot(animated: Bool){
        guard let delegate = delegate else {
            assertionFailure("No delegate set")
            return
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<Breed, PoochPicture>()
        if delegate.shouldShowPoochPictures == false {
            if snapshot.numberOfItems > 0 || snapshot.numberOfSections > 0 {
                snapshot.deleteAllItems()
                datasource.apply(snapshot, animatingDifferences: animated)
            }
        } else {
            let breeds = delegate.filteredBreeds
            snapshot.appendSections(breeds)
            for breed in breeds {
                let items = breed.poochPictures.sorted()
                snapshot.appendItems(items, toSection: breed)
                datasource.apply(snapshot, animatingDifferences: animated)
            }
        }
    }
    
}
