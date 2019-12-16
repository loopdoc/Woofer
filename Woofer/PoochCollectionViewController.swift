//
//  PoochCollectionViewController.swift
//  Woofer
//
//  Created by Chris on 12/12/19.
//  Copyright © 2019 WellKeep. All rights reserved.
//

import UIKit

protocol PoochCollectionViewControllerDelegate : class {
    var shouldShowPoochPictures : Bool { get }
    var filteredBreeds : [Breed] { get }
}

class PoochCollectionViewController: UICollectionViewController {
    
    enum Section {
        case main
    }

    weak var delegate : PoochCollectionViewControllerDelegate?
    
    var datasource : UICollectionViewDiffableDataSource<Breed, PoochPicture>! = nil
    
    var currentlyShownBreeds : Set<Breed> = []
    
    var showPictures : Bool {
        let count = delegate?.filteredBreeds.count ?? 0
        return count > 0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureDataSource()
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
            snapshot.deleteAllItems()
            datasource.apply(snapshot, animatingDifferences: animated)
            updateFetching([])
        } else {
            let breeds = delegate.filteredBreeds
            snapshot.appendSections(breeds)
            for breed in breeds {
                let items = breed.poochPictures
                snapshot.appendItems(items, toSection: breed)
                datasource.apply(snapshot, animatingDifferences: animated)
            }
            updateFetching(breeds)
        }
    }
    
    func updateFetching(_ toBeShownBreeds: [Breed]) {
        guard toBeShownBreeds.count > 0 else {
            _ = currentlyShownBreeds.map{ $0.suspendImageFetching() }
            currentlyShownBreeds = []
            return
        }
        let toBeShownBreedsSet = Set(toBeShownBreeds)
        let notBeingShownAnymoreBreeds = currentlyShownBreeds.subtracting(toBeShownBreedsSet)
        _ = notBeingShownAnymoreBreeds.map{ $0.suspendImageFetching() }
        currentlyShownBreeds = toBeShownBreedsSet
        _ = currentlyShownBreeds.map{ $0.resumeImageFetching() }
    }
    
}
