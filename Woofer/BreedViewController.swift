//
//  ViewController.swift
//  Woofer
//
//  Created by Chris on 12/12/19.
//  Copyright © 2019 WellKeep. All rights reserved.
//

import UIKit

class BreedViewController: UIViewController, PoochCollectionViewControllerDelegate {

    enum Section {
        case main
    }
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var poochCollectionContainerView: UIView!
    
    let opertionQueue = OperationQueue()
    
    let searchController = UISearchController(searchResultsController: nil)
    var isSearchBarEmpty : Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }

    var poochCollectionViewController : PoochCollectionViewController! = nil
    
    var dataSource : UITableViewDiffableDataSource<Section, Breed>! = nil
    
    var breeds : [Breed] = [] {
        didSet {
            filteredBreeds = breeds
        }
    }
    
    var filteredBreeds : [Breed] = []
    var shouldShowPoochPictures: Bool {
        return !(filteredBreeds.count == 0 || filteredBreeds.count == breeds.count)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSearchController()
        configureDataSource()
        fetchBreeds()
    }

}

extension BreedViewController {
    //MARK: - Fetch
    func fetchBreeds() {
        self.opertionQueue.maxConcurrentOperationCount = 5
        let blockOperation = BlockOperation(){ [unowned self] in
            autoreleasepool {
                do {
                    guard let url = URL(string: Breed.allBreedsListSource) else {
                        assertionFailure("Can't create URL from allBreedsListSource")
                        return
                    }
                    let data = try Data(contentsOf: url)
                    let breedMessageCodeable = try JSONDecoder().decode(BreedMessageCodeable.self, from: data)
                    let processedBreeds = Breed.processNamedBreeds(breedMessageCodeable.message)
                    DispatchQueue.main.async { [unowned self] in
                        self.breeds = processedBreeds.sorted(by: <)
                        // Initial data load
                        self.updateSnapshot(animated: false)
                    }
                } catch {
                    print("\(error)")
                    // TODO: Show an alert informing the user there is a problem
                    assertionFailure()
                }
            }
        }
        opertionQueue.addOperation(blockOperation)
    }
    
}

extension BreedViewController {
    //MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "poochCollectionViewEmbedSegue" {
            guard let destinationVC = segue.destination as? PoochCollectionViewController else {
                return
            }
            poochCollectionViewController = destinationVC
            poochCollectionViewController.delegate = self
        }
    }

}

extension BreedViewController {
    //MARK: Diffable Datasource
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<Section, Breed>(tableView: tableView){
            (tableView: UITableView, indexPath: IndexPath, breed: Breed) -> UITableViewCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel?.text = breed.displayName
            return cell
        }
        tableView.dataSource = dataSource
        // Initial data
        updateSnapshot(animated: false)
    }
    
    func updateSnapshot(animated: Bool){
        var snapshot = NSDiffableDataSourceSnapshot<Section, Breed>()
        snapshot.appendSections([.main])
        snapshot.appendItems(filteredBreeds)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
    
}

extension BreedViewController {
    //MARK: Search

    func configureSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Dog Breeds"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    func filterBreeds(for query: String?) {
        filteredBreeds = breeds.filter { (breed : Breed) -> Bool in
            // Use the contains to get general matching
//            breed.contains(query)
            // However, we can also search by prefix
            breed.hasPrefix(query)
        }
        updateSnapshot(animated: true)
        poochCollectionViewController.updateSnapshot(animated: true)
    }
    
}

extension BreedViewController : UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text
        filterBreeds(for: query)
    }

}

