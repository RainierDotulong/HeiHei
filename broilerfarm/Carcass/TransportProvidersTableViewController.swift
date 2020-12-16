//
//  TransportProvidersTableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 6/22/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import UIEmptyState
import SVProgressHUD
import Firebase
import FirebaseFirestore
import NotificationBannerSwift

protocol sendTransportProviderData {
    func transportProviderDataReceived(transportProvider: TransportProvider)
}

class TransportProvidersTableViewCell : UITableViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var bankDetailsLabel: UILabel!
    @IBOutlet var creatorLabel: UILabel!
}

class TransportProvidersTableViewController: UITableViewController, UIEmptyStateDataSource, UIEmptyStateDelegate, UISearchResultsUpdating {
    
    var loginClass : String = ""
    var fullName : String = ""
    var delegate : sendTransportProviderData?
    var pick : Bool = false
    
    var dataArray : [TransportProvider] = [TransportProvider]()
    var filteredDataArray : [TransportProvider] = [TransportProvider]()
    var providerNames : [String] = [String]()
    var selectedData : TransportProvider = TransportProvider(name: "", bank: "", bankNumber: "", bankName: "", paymentTerm: "", createdBy: "", timestamp: 0)
    
    var resultSearchController = UISearchController()
    
    //UI Empty State Variables
    var emptyStateTitle: NSAttributedString {
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor(red: 0.882, green: 0.890, blue: 0.859, alpha: 1.00),
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22)]
        return NSAttributedString(string: "No Transport Providers Found", attributes: attrs)
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
        
        getDataFromServer(pullDownRefresh : false)
        
    }
    
    @objc func refresh() {
        print("Refresh")
        getDataFromServer(pullDownRefresh : true)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredDataArray.removeAll(keepingCapacity: false)

        let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchController.searchBar.text!)
        let array = (providerNames as NSArray).filtered(using: searchPredicate)
        let filteredProviderArray = array as! [String]
        //construct Filtered Data Array
        for data in dataArray {
            for provider in filteredProviderArray {
                if data.name == provider {
                    filteredDataArray.append(data)
                }
            }
        }
        self.tableView.reloadData()
        self.reloadEmptyState()
    }

    @IBAction func addButtonPressed(_ sender: Any) {
        print("Add")
        let alert = UIAlertController(title: "Add New Tranport Provider", message: "Please Specify Provider Data", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Name"
            textField.keyboardType = .default
            textField.autocapitalizationType = .words
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Bank Name"
            textField.keyboardType = .default
            textField.autocapitalizationType = .words
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Bank Holder Name"
            textField.keyboardType = .default
            textField.autocapitalizationType = .words
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Bank Number"
            textField.keyboardType = .numberPad
            textField.autocapitalizationType = .words
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Payment Term"
            textField.keyboardType = .default
            textField.autocapitalizationType = .words
        }
        
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            let textField = alert.textFields![0]
            let textField1 = alert.textFields![1]
            let textField2 = alert.textFields![2]
            let textField3 = alert.textFields![3]
            let textField4 = alert.textFields![4]
            
            guard textField.text ?? "" != "" && textField1.text ?? "" != "" && textField2.text ?? "" != "" && textField3.text ?? "" != "" && textField4.text ?? "" != "" else {
                print("Incomplete Data")
                let dialogMessage = UIAlertController(title: "Incomplete Data", message: "Text Field Empty", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            guard self.providerNames.contains(textField.text ?? "") == false else {
                print("Provider Already Exists")
                let dialogMessage = UIAlertController(title: "Error Creating Provider!", message: "Provider Already Exists", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            self.createTransportProvider(name: textField.text ?? "", bank: textField1.text ?? "", bankNumber: textField3.text ?? "", bankName: textField2.text ?? "", paymentTerm: textField4.text ?? "", createdBy: self.fullName)
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            print("Cancel button tapped")
        }
        
        alert.addAction(ok)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func getDataFromServer(pullDownRefresh : Bool) {
        if pullDownRefresh == false {
            SVProgressHUD.show()
        }
        let db = Firestore.firestore()
        db.collection("transportProviders").getDocuments() { (querySnapshot, err) in
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
                self.providerNames.removeAll(keepingCapacity: false)
                for document in querySnapshot!.documents {
                    
                    var trasportProvider : TransportProvider = TransportProvider(name: "", bank: "", bankNumber: "", bankName: "", paymentTerm: "", createdBy: "", timestamp: 0)
                    
                    trasportProvider.name = document.documentID
                    trasportProvider.bank = document.data()["bank"] as! String
                    trasportProvider.bankNumber = document.data()["bankNumber"] as! String
                    trasportProvider.bankName = document.data()["bankName"] as! String
                    trasportProvider.paymentTerm = document.data()["paymentTerm"] as! String
                    trasportProvider.createdBy = document.data()["createdBy"] as! String
                    trasportProvider.timestamp = document.data()["timestamp"] as! Double
                    
                    self.dataArray.append(trasportProvider)
                    self.providerNames.append(trasportProvider.name)
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
    
    func createTransportProvider(name : String, bank : String, bankNumber : String, bankName : String, paymentTerm : String, createdBy : String) {
        let doc = Firestore.firestore().collection("transportProviders").document(name)
        doc.setData([
            "bank" : bank,
            "bankNumber" : bankNumber,
            "bankName" : bankName,
            "paymentTerm" : paymentTerm,
            "createdBy" : createdBy,
            "timestamp" : NSDate().timeIntervalSince1970
        ]) { err in
            if let err = err {
                print("Error writing new provider document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error writing New provider Document", style: .danger)
                banner.show()
            } else {
                print("Customer successfully Created!")
                self.getDataFromServer(pullDownRefresh : false)
            }
        }
    }
    
    func deleteProvider(data : TransportProvider) {
        if resultSearchController.isActive {
            resultSearchController.isActive = false
        }
        SVProgressHUD.show()
        let doc = Firestore.firestore().collection("transportProviders").document(data.name)
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if  (resultSearchController.isActive) {
            if pick {
                self.delegate?.transportProviderDataReceived(transportProvider: filteredDataArray[self.filteredDataArray.count - indexPath.row - 1])
                resultSearchController.isActive = false
                self.navigationController?.popViewController(animated: true)
            }
        }
        else {
            if pick {
                self.delegate?.transportProviderDataReceived(transportProvider: dataArray[self.dataArray.count - indexPath.row - 1])
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.rowHeight = UITableView.automaticDimension
        
        func createCells(data : TransportProvider) -> TransportProvidersTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TransportProviderCell", for: indexPath) as! TransportProvidersTableViewCell
            
            let date = Date(timeIntervalSince1970: data.timestamp )
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: date)
            
            cell.nameLabel.text = data.name
            cell.bankDetailsLabel.text = "Rek: \(data.bank) - \(data.bankName) - \(data.bankNumber)"
            cell.creatorLabel.text = "Created By: \(data.createdBy) on \(stringDate)"
            
            return cell
        }
        
        if (resultSearchController.isActive) {
            return createCells(data: filteredDataArray[self.filteredDataArray.count - indexPath.row - 1])
        }
        else {
            return createCells(data: dataArray[self.dataArray.count - indexPath.row - 1])
        }
    }
    
    //MARK: Table Cell Button Actions
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let delete = UIContextualAction(style: .normal, title: "Delete") {  (contextualAction, view, boolValue) in
            
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Confirm", message: "Are you sure you want to Delete this Transport Provider?", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
                if (self.resultSearchController.isActive) {
                    self.deleteProvider(data: self.filteredDataArray[self.filteredDataArray.count - indexPath.row - 1])
                }
                else {
                    //Remove Data Array Item
                    self.deleteProvider(data: self.dataArray[self.dataArray.count - indexPath.row - 1])
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
            
            func updateCustomer (data : TransportProvider) {
                if self.resultSearchController.isActive  {
                    self.resultSearchController.isActive = false
                }
                let alert = UIAlertController(title: "Update \(data.name)", message: "Please Specify Provider Data", preferredStyle: .alert)
                
                alert.addTextField { (textField) in
                    textField.placeholder = "Bank Name"
                    textField.text = data.bank
                    textField.keyboardType = .default
                    textField.autocapitalizationType = .words
                }
                alert.addTextField { (textField) in
                    textField.placeholder = "Bank Holder Name"
                    textField.text = data.bankName
                    textField.keyboardType = .default
                    textField.autocapitalizationType = .words
                }
                alert.addTextField { (textField) in
                    textField.placeholder = "Bank Number"
                    textField.text = data.bankNumber
                    textField.keyboardType = .numberPad
                    textField.autocapitalizationType = .words
                }
                alert.addTextField { (textField) in
                    textField.placeholder = "Payment Term"
                    textField.text = data.paymentTerm
                    textField.keyboardType = .default
                }
                
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                    let textField = alert.textFields![0]
                    let textField1 = alert.textFields![1]
                    let textField2 = alert.textFields![2]
                    let textField3 = alert.textFields![3]
                    
                    guard textField.text ?? "" != "" && textField1.text ?? "" != "" && textField2.text ?? "" != "" && textField3.text ?? "" != "" && textField3.text ?? "" != "" else {
                        print("Incomplete Data")
                        let dialogMessage = UIAlertController(title: "Incomplete Data", message: "Text Field Empty", preferredStyle: .alert)
                        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                            print("Ok button tapped")
                        })
                        dialogMessage.addAction(ok)
                        self.present(dialogMessage, animated: true, completion: nil)
                        return
                    }
                    self.createTransportProvider(name: data.name, bank: textField.text ?? "", bankNumber: textField2.text ?? "", bankName: textField1.text ?? "", paymentTerm: textField3.text ?? "", createdBy: self.fullName)
                })
                
                let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
                    print("Cancel button tapped")
                }
                
                alert.addAction(ok)
                alert.addAction(cancel)
                
                self.present(alert, animated: true, completion: nil)
            }
            if (self.resultSearchController.isActive) {
                updateCustomer(data: self.filteredDataArray[self.filteredDataArray.count - indexPath.row - 1])
            }
            else {
                updateCustomer(data: self.dataArray[self.dataArray.count - indexPath.row - 1])
            }
            
        }
        
        edit.image = UIImage(systemName: "square.and.pencil")
        edit.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [delete, edit])
    }
}
