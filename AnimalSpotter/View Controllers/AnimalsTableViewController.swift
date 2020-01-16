//
//  AnimalsTableViewController.swift
//  AnimalSpotter
//
//  Created by Ben Gohlke on 4/16/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import UIKit

class AnimalsTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    let apiController = APIController()
    private var animalNames: [String] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Transition to log in screen if there is no bearer token, meaning you are not logged in
        if apiController.bearer == nil {
            performSegue(withIdentifier: "LoginViewModalSegue", sender: self)
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return animalNames.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AnimalCell", for: indexPath)
        cell.textLabel?.text = animalNames[indexPath.row]

        return cell
    }

    // MARK: - Actions
    
    @IBAction func getAnimals(_ sender: UIBarButtonItem) {
        // If you don't care about the errors returned by the Result type.
//        apiController.fetchAllAnimalNames { result in
//            if let names = try? result.get() {
//                DispatchQueue.main.async {
//                    self.animalNames = names
//                }
//            }
//        }
        
        // If you want to enumerate and show each kind of possible error
        apiController.fetchAllAnimalNames { result in
            do {
                let names = try result.get()
                DispatchQueue.main.async {
                    self.animalNames = names
                }
            } catch {
                if let error = error as? NetworkError {
                    switch error {
                    case .noBearer:
                        print("No bearer exists")
                    case .badData:
                        print("No data received or data corrupted")
                    case .noDecode:
                        print("JSON could not be decoded")
                    default:
                        print("Other error occured, see log")
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "LoginViewModalSegue" {
            if let loginVC = segue.destination as? LoginViewController {
                loginVC.apiController = apiController
            }
        }
        
        else if segue.identifier == "ShowAnimalDetailSegue" {
            if let detailVC = segue.destination as? AnimalDetailViewController,
                let indexPath = tableView.indexPathForSelectedRow {
                detailVC.animalName = animalNames[indexPath.row]
                detailVC.apiController = apiController
            }
        }
    }
}
