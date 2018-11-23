//
//  ViewController.swift
//  CountryPlayers
//
//  Created by Suchetan on 11/23/18.
//  Copyright © 2018 Suchetan. All rights reserved.
//

import UIKit
import Alamofire
import CoreData

class ViewController: UIViewController,NSFetchedResultsControllerDelegate {
    // MARK: - IBOutlet's
    @IBOutlet weak var countriesTableView: UITableView!
    
    // MARK: - Properties
    let playerListSegue = "playerListSegue"
    var countryListObj = [countryList]()
    let crickertCountryURL = "https://demo6869072.mockable.io/cricket/countries"
    var hascountries = false
    private let persistentContainer = NSPersistentContainer(name: "country")
//    var managedObjectContext: NSManagedObjectContext?
    var managedObjectContext: NSManagedObjectContext?
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<Countries> = {
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<Countries> = Countries.fetchRequest()
        
        // Configure Fetch Request
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        
        // Create Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
     // MARK: - View controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.title = "Countries"
        self.managedObjectContext = persistentContainer.viewContext
        persistentContainer.loadPersistentStores { (persistentStoreDescription, error) in
            if let error = error {
                print("Unable to Load Persistent Store")
                print("\(error), \(error.localizedDescription)")
            } else {
                do {
                    try self.fetchedResultsController.performFetch()
                } catch {
                    let fetchError = error as NSError
                    print("Unable to Perform Fetch Request")
                    print("\(fetchError), \(fetchError.localizedDescription)")
                }
                self.updateView()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
     // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destinationViewController = segue.destination as? PlayerListViewController else { return }
        if let indexPath = countriesTableView.indexPathForSelectedRow, segue.identifier == playerListSegue {
            // Configure View Controller
            destinationViewController.managedObjectContext = persistentContainer.viewContext
            if !hascountries{
                    destinationViewController.countryID = self.countryListObj[indexPath.row].id
            }else{
                destinationViewController.countryID = fetchedResultsController.object(at: indexPath).id
            }
        }
    }
    // MARK: - View Methods
    private func updateView() {
        if let countries = fetchedResultsController.fetchedObjects {
            hascountries = countries.count > 0
        }
        if !hascountries{
            self.getCountryListDetails()
        }
//        activityIndicatorView.stopAnimating()
    }
    // MARK: - Network Calls
    func getCountryListDetails(){
        Alamofire.request(crickertCountryURL, method: .get).responseJSON { response in
            if response.result.isFailure {
                return
            }
            if let countryListData = response.result.value as? [[String:AnyObject]] {
                self.countryListObj = countryListData.compactMap { data in
                    guard let id = data["id"] as? String,
                    let name = data["name"] as? String,
                        let image = data["image"] as? String else {return nil}
                    return countryList(id: id, name: name, image: image)
                }
            }
            for country in self.countryListObj{
                guard let managedObjectContext = self.managedObjectContext else {return}
                // Create Countries
                let countries = Countries(context: managedObjectContext)
                // Configure Countries
                countries.id = country.id
                countries.name = country.name
                countries.image = country.image
            }
            do {
                try self.managedObjectContext?.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
            self.countriesTableView.reloadData()
        }
    }

}
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !hascountries{
            return self.countryListObj.count
        }else{
            guard let sectionInfo = fetchedResultsController.sections?[section] else { fatalError("Unexpected Section") }
            return sectionInfo.numberOfObjects
        }
        
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "countryCell", for: indexPath) as? CountryTableViewCell else {
            return UITableViewCell()
        }
        // Fetch countries
        if !hascountries{
            cell.countryNameLabel?.text = self.countryListObj[indexPath.row].name
            return cell
        }else{
            let countries = fetchedResultsController.object(at: indexPath)
            cell.countryNameLabel?.text = countries.name
            return cell
        }
        
    }
}
