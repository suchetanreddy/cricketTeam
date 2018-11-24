//
//  AddNewPlayerViewController.swift
//  CountryPlayers
//
//  Created by Suchetan on 11/23/18.
//  Copyright © 2018 Suchetan. All rights reserved.
//

import UIKit
import CoreData
class AddNewPlayerViewController: UIViewController,UITextFieldDelegate {
    // MARK: - IBOutlet's
    @IBOutlet weak var playerNameTextField: UITextField!
    // MARK: - Properties
    var player: Players?
    var countryID: String?
    var managedObjectContext: NSManagedObjectContext?
    // MARK: - View controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let player = player {
            playerNameTextField.text = player.playerName
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        playerNameTextField.becomeFirstResponder()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    // MARK: - Button IBAction methods
    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
        if (playerNameTextField.text?.isEmpty)!{
            let alert = UIAlertController(title: "Alert", message: "Please enter player name", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }else{
            guard let managedObjectContext = managedObjectContext else { return }
            
            if player == nil {
                // Create player
                let newplayer = Players(context: managedObjectContext)
                // Set player
                player = newplayer
            }
            
            if let player = player {
                // Configure player
                player.playerName = playerNameTextField.text
                player.countryID = countryID
            }
            do {
                try managedObjectContext.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
            // Pop View Controller
            _ = navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func backButtonTapped(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    // MARK: - UITextField Delegate Method
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
