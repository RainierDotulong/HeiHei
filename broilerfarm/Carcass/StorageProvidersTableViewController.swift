//
//  StorageProvidersTableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 6/24/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import UIEmptyState
import SVProgressHUD
import Firebase
import FirebaseFirestore
import NotificationBannerSwift

protocol sendStorageData {
    func storageDataReceived(storage: StorageProvider)
}

class StorageProviderTableViewCell : UITableViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var contactPersonLabel: UILabel!
    @IBOutlet var createdByLabel: UILabel!
}

class StorageProvidersTableViewController: UITableViewController, UIEmptyStateDataSource, UIEmptyStateDelegate, UISearchResultsUpdating {
    
    var loginClass : String = ""
    var fullName : String = ""
    var delegate : sendStorageData?
    var pick : Bool = false
    
    var dataArray : [StorageProvider] = [StorageProvider]()
    var filteredDataArray : [StorageProvider] = [StorageProvider]()
    var storageNames : [String] = [String]()
    var selectedStorageProvider : StorageProvider = StorageProvider(name: "", address: "", latitude: 0, longitude: 0, contactPerson: "", contactPhone: "", pricePerKgPerDay: 0, numberOfFreeDays: 0, createdBy: "", timestamp: 0)
    var edit : Bool = false
    
    var resultSearchController = UISearchController()
    
    //UI Empty State Variables
    var emptyStateTitle: NSAttributedString {
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor(red: 0.882, green: 0.890, blue: 0.859, alpha: 1.00),
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22)]
        return NSAttributedString(string: "No Storage Providers Found", attributes: attrs)
    }
    
    var emptyStateImage: UIImage? {
        return UIImage(named: "redLogo")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
                
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        // Set the data source and delegate
        self.emptyStateDataSource = self
        self.emptyStateDelegate = self
        
        // Remove seperator lines from empty cells
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        //Pull to Refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:  #selector(refresh), for: .valueChanged)
        self.refreshControl = refreshControl
        
        //SearchBar
        resultSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.obscuresBackgroundDuringPresentation = false
            controller.searchBar.sizeToFit()

            tableView.tableHeaderView = controller.searchBar

            return controller
        })()
        
        let StorageProviderCreationNotification = Notification.Name("storageProviderCreated")
        NotificationCenter.default.addObserver(self, selector: #selector(storageProviderCreated(_:)), name: StorageProviderCreationNotification, object: nil)
        
        getDataFromServer(pullDownRefresh : false)
    }
    
    @objc func storageProviderCreated(_ notification:Notification) {
        print("Stroage Provider Successfully Created.")
        getDataFromServer(pullDownRefresh : false)
    }
    
    @objc func refresh() {
        print("Refresh")
        getDataFromServer(pullDownRefresh : true)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredDataArray.removeAll(keepingCapacity: false)

        let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchController.searchBar.text!)
        let array = (storageNames as NSArray).filtered(using: searchPredicate)
        let filteredStorageNames = array as! [String]
        //construct Filtered Data Array
        for data in dataArray {
            for storageName in filteredStorageNames {
                if data.name == storageName {
                    filteredDataArray.append(data)
                }
            }
        }
        self.tableView.reloadData()
        self.reloadEmptyState()
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        edit = false
        self.performSegue(withIdentifier: "goToStorageProviderInput", sender: self)
    }
    
    func getDataFromServer(pullDownRefresh : Bool) {
        if pullDownRefresh == false {
            SVProgressHUD.show()
        }
        let db = Firestore.firestore()
        db.collection("storageProviders").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                if pullDownRefresh == true {
                    self.refreshControl?.endRefreshing()
                }
                else {
                    SVProgressHUD.dismiss()
                }
                let banner = StatusBarNotificationBanner(title: "Error getting documents", style: .danger)
                banner.show()
            } else {
                self.dataArray.removeAll(keepingCapacity: false)
                self.storageNames.removeAll(keepingCapacity: false)
                for document in querySnapshot!.documents {
                    
                    var storageProvider : StorageProvider = StorageProvider(name: "", address: "", latitude: 0, longitude: 0, contactPerson: "", contactPhone: "", pricePerKgPerDay: 0, numberOfFreeDays: 0, createdBy: "", timestamp: 0)
                    
                    storageProvider.name = document.documentID
                    storageProvider.address = document.data()["address"] as! String
                    storageProvider.latitude = document.data()["latitude"] as! Double
                    storageProvider.longitude = document.data()["longitude"] as! Double
                    storageProvider.contactPerson = document.data()["contactPerson"] as! String
                    storageProvider.contactPhone = document.data()["contactPhone"] as! String
                    storageProvider.pricePerKgPerDay = document.data()["pricePerKgPerDay"] as! Int
                    storageProvider.numberOfFreeDays = document.data()["numberOfFreeDays"] as! Int
                    storageProvider.createdBy = document.data()["createdBy"] as! String
                    storageProvider.timestamp = document.data()["timestamp"] as! Double
                    
                    self.dataArray.append(storageProvider)
                    self.storageNames.append(storageProvider.name)
                }
                if pullDownRefresh == true {
                    self.refreshControl?.endRefreshing()
                }
                else {
                    SVProgressHUD.dismiss()
                }
                self.tableView.reloadData()
                self.reloadEmptyState()
            }
        }
    }
    
    func deleteStorageProvider(data : StorageProvider) {
        if resultSearchController.isActive {
            resultSearchController.isActive = false
        }
        SVProgressHUD.show()
        let doc = Firestore.firestore().collection("rpa").document(data.name)
        doc.delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
                SVProgressHUD.dismiss()
                let banner = StatusBarNotificationBanner(title: "Error removing document", style: .danger)
                banner.show()
            } else {
                print("Document successfully removed!")
                SVProgressHUD.dismiss()
                let banner = StatusBarNotificationBanner(title: "Document successfully removed!", style: .success)
                banner.show()
                self.getDataFromServer(pullDownRefresh: false)
            }
        }
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if  (resultSearchController.isActive) {
            return filteredDataArray.count
        }
        else {
            return dataArray.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.rowHeight = UITableView.automaticDimension
        
        func createCells(data : StorageProvider) -> StorageProviderTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "storageProviderCell", for: indexPath) as! StorageProviderTableViewCell
            
            let date = Date(timeIntervalSince1970: data.timestamp )
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: date)
            
            cell.nameLabel.text = data.name
            cell.addressLabel.text = data.address
            cell.contactPersonLabel.text = "Contact: \(data.contactPerson) - \(data.contactPhone)"
            cell.createdByLabel.text = "Created By: \(data.createdBy) on \(stringDate)"
            
            return cell
        }
        
        if (resultSearchController.isActive) {
            return createCells(data: filteredDataArray[self.filteredDataArray.count - indexPath.row - 1])
        }
        else {
            return createCells(data: dataArray[self.dataArray.count - indexPath.row - 1])
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if  (resultSearchController.isActive) {
            if pick {
                self.delegate?.storageDataReceived(storage: filteredDataArray[self.filteredDataArray.count - indexPath.row - 1])
                resultSearchController.isActive = false
                self.navigationController?.popViewController(animated: true)
            }
        }
        else {
            if pick {
                self.delegate?.storageDataReceived(storage: dataArray[self.dataArray.count - indexPath.row - 1])
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    //MARK: Table Cell Button Actions
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let delete = UIContextualAction(style: .normal, title: "Delete") {  (contextualAction, view, boolValue) in
            
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Confirm", message: "Are you sure you want to Delete this RPA?", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
                if (self.resultSearchController.isActive) {
                    self.deleteStorageProvider(data: self.filteredDataArray[self.filteredDataArray.count - indexPath.row - 1])
                }
                else {
                    //Remove Data Array Item
                    self.deleteStorageProvider(data: self.dataArray[self.dataArray.count - indexPath.row - 1])
                }
            })
            // Create Cancel button with action handlder
            let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
                print("Cancel button tapped")
            }
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            dialogMessage.addAction(cancel)
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)
            
        }
        
        delete.image = UIImage(systemName: "trash")
        delete.backgroundColor = .systemRed
        
        let edit = UIContextualAction(style: .normal, title: "Edit") {  (contextualAction, view, boolValue) in
            
            if (self.resultSearchController.isActive) {
                self.selectedStorageProvider = self.filteredDataArray[indexPath.row]
                self.edit = true
                self.performSegue(withIdentifier: "goToStorageProviderInput", sender: self)
            }
            else {
                self.selectedStorageProvider = self.dataArray[indexPath.row]
                self.edit = true
                self.performSegue(withIdentifier: "goToStorageProviderInput", sender: self)
            }
            
        }
        
        edit.image = UIImage(systemName: "square.and.pencil")
        edit.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [delete, edit])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is StorageProviderInputViewController
        {
            let vc = segue.destination as? StorageProviderInputViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.storageNames = storageNames
            vc?.selectedStorageProvider = selectedStorageProvider
            vc?.edit = edit
        }
    }
}
