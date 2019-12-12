//
//  ViewController.swift
//  Woofer
//
//  Created by Chris on 12/12/19.
//  Copyright © 2019 WellKeep. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    enum Section {
        case main
    }
    
    @IBOutlet var tableView: UITableView!
    
    let searchController = UISearchController(searchResultsController: nil)
    var isSearchBarEmpty : Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    var dataSource : UITableViewDiffableDataSource<Section, Breed>! = nil
    
    var breeds : [Breed] = [] {
        didSet {
            filteredBreeds = breeds
        }
    }
    
    
    var filteredBreeds : [Breed] = []

    var didLayout = false

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSearchController()
        configureDataSource()
        fetchBreeds()
    }

}

extension ViewController {
    //MARK: - Fetch
    func fetchBreeds() {
        DispatchQueue.global(qos: .userInteractive).async {
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

}

extension ViewController {
    //MARK: Diffable Datasource
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<Section, Breed>(tableView: tableView){
            (tableView: UITableView, indexPath: IndexPath, breed: Breed) -> UITableViewCell in
//            let cell = tableView.dequeueReusableCell(withIdentifier: BreedTableViewCell.reuseIdentifier, for: indexPath) as! BreedTableViewCell
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

extension ViewController {
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
            breed.contains(query: query)
        }
        if query == nil {
            // Clear previous search
        }
        updateSnapshot(animated: true)
    }
    
}

extension ViewController : UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text
        filterBreeds(for: query)
    }

}
