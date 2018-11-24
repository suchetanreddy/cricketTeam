//
//  PlayerListViewController.swift
//  CountryPlayers
//
//  Created by Suchetan on 11/23/18.
//  Copyright © 2018 Suchetan. All rights reserved.
//

import UIKit
import CoreData
class PlayerListViewController: UIViewController {
    // MARK: - Properties
    private let addPlayerSegue = "addPlayerSegue"
    private let editPlayerSegue = "editPlayerSegue"
    var countryID : String?
    var countryName : String?
    var managedObjectContext: NSManagedObjectContext?
    private let persistentContainer = NSPersistentContainer(name: "country")
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<Players> = {
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<Players> = Players.fetchRequest()
        
        // Configure Fetch Request
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Players.playerName), ascending: true)]
        let filterCountryID = countryID
        let predicate = NSPredicate(format: "countryID = %@", filterCountryID ?? "")
        fetchRequest.predicate = predicate
        
        // Create Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.persistentContainer.viewContext, sectionNameKeyPath: #keyPath(Players.playerName), cacheName: nil)
        
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    // MARK: - IBOutlet's
    @IBOutlet weak var playersTableView: UITableView!
    @IBOutlet weak var messageLabel: UILabel!
    // MARK: - View controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = countryName
        // Do any additional setup after loading the view.
        persistentContainer.loadPersistentStores { (persistentStoreDescription, error) in
            if let error = error {
                print("Unable to Load Persistent Store")
                print("\(error), \(error.localizedDescription)")
                
            } else {
                self.setupView()
                
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
        guard let destinationViewController = segue.destination as? AddNewPlayerViewController else { return }
        
        // Configure View Controller
        destinationViewController.managedObjectContext = persistentContainer.viewContext
        
        if let indexPath = playersTableView.indexPathForSelectedRow, segue.identifier == editPlayerSegue {
            // Configure View Controller
            destinationViewController.countryID = fetchedResultsController.object(at: indexPath).countryID
            destinationViewController.player = fetchedResultsController.object(at: indexPath)
        }else if segue.identifier == addPlayerSegue {
            destinationViewController.countryID = countryID
        }
    }
    // MARK: - View Methods
    private func setupView() {
        setupMessageLabel()
        updateView()
    }
    fileprivate func updateView() {
        var hasQuotes = false
        if let quotes = fetchedResultsController.fetchedObjects {
            hasQuotes = quotes.count > 0
        }
        self.playersTableView.tableFooterView = UIView()
        self.playersTableView.isHidden = !hasQuotes
        self.messageLabel.isHidden = hasQuotes
    }
    private func setupMessageLabel() {
        messageLabel.text = "You don't have any player yet."
    }

    // MARK: - Notification Handling
    
    @objc func applicationDidEnterBackground(_ notification: Notification) {
        do {
            try persistentContainer.viewContext.save()
        } catch {
            print("Unable to Save Changes")
            print("\(error), \(error.localizedDescription)")
        }
    }
    // MARK: - Button IBAction methods
    @IBAction func backButtonTapped(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
}
extension PlayerListViewController : NSFetchedResultsControllerDelegate{
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        playersTableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        playersTableView.endUpdates()
        
        updateView()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
        case .insert:
            if let indexPath = newIndexPath {
                playersTableView.insertRows(at: [indexPath], with: .fade)
            }
            break;
        case .delete:
            if let indexPath = indexPath {
                playersTableView.deleteRows(at: [indexPath], with: .fade)
            }
            break;
        case .update:
            if let indexPath = indexPath, let cell = playersTableView.cellForRow(at: indexPath) as? PlayerTableViewCell {
                configure(cell, at: indexPath)
            }
            break;
        case .move:
            if let indexPath = indexPath {
                playersTableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            if let newIndexPath = newIndexPath {
                playersTableView.insertRows(at: [newIndexPath], with: .fade)
            }
            break;
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            playersTableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            playersTableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            break;
        }
    }
}
extension PlayerListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let sections = fetchedResultsController.sections else { return 0 }
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = fetchedResultsController.sections?[section] else { fatalError("Unexpected Section") }
        return sectionInfo.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionInfo = fetchedResultsController.sections?[section] else { fatalError("Unexpected Section") }
        return sectionInfo.name
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "playerCell", for: indexPath) as? PlayerTableViewCell else {
            fatalError("Unexpected Index Path")
        }
        
        // Configure Cell
        configure(cell, at: indexPath)
        
        return cell
    }
    
    func configure(_ cell: PlayerTableViewCell, at indexPath: IndexPath) {
        // Fetch Quote
        let player = fetchedResultsController.object(at: indexPath)
        
        // Configure Cell
        cell.playerNameLabel.text = player.playerName
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Fetch palyer
            let player = fetchedResultsController.object(at: indexPath)
            // Delete palyer
            player.managedObjectContext?.delete(player)
            do {
                try player.managedObjectContext?.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
