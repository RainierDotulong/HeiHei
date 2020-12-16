//
//  RetailCustomersTableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 4/22/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import UIEmptyState
import Firebase
import FirebaseFirestore
import SVProgressHUD
import NotificationBannerSwift
import QuickLook

class RetailCustomersTableViewCell : UITableViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var phoneNumberLabel: UILabel!
    @IBOutlet var createdByLabel: UILabel!
}

protocol sendRetailCustomerData {
    func retailCustomerDataReceived(customer : RetailCustomer)
}

class RetailCustomersTableViewController: UITableViewController, UIEmptyStateDataSource, UIEmptyStateDelegate, UISearchResultsUpdating, QLPreviewControllerDataSource {
    
    var loginClass : String = ""
    var fullName : String = ""
    var previousMenu : String = ""
    var delegate : sendRetailCustomerData?
    
    var dataArray : [RetailCustomer] = [RetailCustomer]()
    var filteredDataArray : [RetailCustomer] = [RetailCustomer]()
    var customerNames : [String] = [String]()
    
    var resultSearchController = UISearchController()
        
    //UI Empty State Variables
    var emptyStateTitle: NSAttributedString {
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor(red: 0.882, green: 0.890, blue: 0.859, alpha: 1.00),
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22)]
        return NSAttributedString(string: "No Customers Found", attributes: attrs)
    }
    
    var emptyStateImage: UIImage? {
        return UIImage(named: "redLogo")
    }
    
    var csvPath : URL = URL(string: "https://www.globalxtreme.net")!

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
        let array = (customerNames as NSArray).filtered(using: searchPredicate)
        let filteredCompanyNameArray = array as! [String]
        //construct Filtered Data Array
        for data in dataArray {
            for perusahaan in filteredCompanyNameArray {
                if data.name == perusahaan {
                    filteredDataArray.append(data)
                }
            }
        }
        self.tableView.reloadData()
        self.reloadEmptyState()
    }
    
    func getDataFromServer(pullDownRefresh : Bool) {
        if pullDownRefresh == false {
            SVProgressHUD.show()
        }
        let db = Firestore.firestore()
        db.collection("retailCustomers").getDocuments() { (querySnapshot, err) in
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
                self.customerNames.removeAll(keepingCapacity: false)
                for document in querySnapshot!.documents {
                    
                    var retailCustomer : RetailCustomer = RetailCustomer(name: "", address: "", phone: "", marketing: "", fullAddress: "", latitude: 0, longitude: 0, createdBy: "", timestamp: 0)
                    
                    retailCustomer.name = document.documentID
                    retailCustomer.address = document.data()["address"] as! String
                    retailCustomer.phone = document.data()["phone"] as! String
                    retailCustomer.marketing = document.data()["marketing"] as? String ?? ""
                    retailCustomer.fullAddress = document.data()["fullAddress"] as? String ?? ""
                    retailCustomer.latitude = document.data()["latitude"] as? Double ?? 0
                    retailCustomer.longitude = document.data()["longitude"] as? Double ?? 0
                    retailCustomer.createdBy = document.data()["createdBy"] as! String
                    retailCustomer.timestamp = document.data()["timestamp"] as! Double
                    
                    self.dataArray.append(retailCustomer)
                    self.customerNames.append(retailCustomer.name)
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
    
    func createCustomer(name : String, address : String, phone : String, marketing : String) {
        let doc = Firestore.firestore().collection("retailCustomers").document(name)
        doc.setData([
            "address" : address,
            "phone" : phone,
            "marketing" : marketing,
            "createdBy" : fullName,
            "timestamp" : NSDate().timeIntervalSince1970
        ]) { err in
            if let err = err {
                print("Error writing new customer document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error writing New Cutomer Document", style: .danger)
                banner.show()
            } else {
                print("Customer successfully Created!")
                self.getDataFromServer(pullDownRefresh : false)
            }
        }
    }
    
    func deleteCustomer(data : RetailCustomer) {
        if resultSearchController.isActive {
            resultSearchController.isActive = false
        }
        SVProgressHUD.show()
        let doc = Firestore.firestore().collection("retailCustomers").document(data.name)
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
    
    @IBAction func shareButtonPressed(_ sender: Any) {
        let fileName : String = "Retail-Customers.csv"
        
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        var csvText = "Name,Address,Phone,Marketing,Latitude,Longitude,Created By\n"
        
        let count = dataArray.count
        if count > 0 {
            for i in 0..<dataArray.count {
                let newLine = "\(dataArray[i].name),\((dataArray[i].address).replacingOccurrences(of: ",", with: " ")),\(dataArray[i].phone),\(dataArray[i].marketing),\(dataArray[i].latitude),\(dataArray[i].longitude),\(dataArray[i].createdBy)\n"
                csvText.append(newLine)
            }
                
            do {
                try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
                
                csvPath = path!
                let previewController = QLPreviewController()
                previewController.dataSource = self
                present(previewController, animated: true)
            }
            catch {
                
                print("Failed to create file")
                print("\(error)")
            }
        }
        else {
            print("No data to export")
        }
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        print("Add")
        let alert = UIAlertController(title: "Add New Customer", message: "Please Specify Customer Data", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Name"
            textField.keyboardType = .default
            textField.autocapitalizationType = .words
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Address"
            textField.keyboardType = .default
            textField.autocapitalizationType = .words
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Contact Number"
            textField.keyboardType = .phonePad
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Marketing"
            textField.keyboardType = .default
            textField.autocapitalizationType = .words
        }
        
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            let textField = alert.textFields![0]
            let textField1 = alert.textFields![1]
            let textField2 = alert.textFields![2]
            let textField3 = alert.textFields![3]
            
            guard textField.text ?? "" != "" && textField1.text ?? "" != "" && textField2.text ?? "" != "" && textField3.text ?? "" != "" else {
                print("Incomplete Data")
                let dialogMessage = UIAlertController(title: "Incomplete Data", message: "Text Field Empty", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            guard self.customerNames.contains(textField.text ?? "") == false else {
                print("Customer Already Exists")
                let dialogMessage = UIAlertController(title: "Error Creating Customer!", message: "Customer Already Exists", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            self.createCustomer(name: textField.text ?? "", address: textField1.text ?? "", phone: textField2.text ?? "", marketing: textField3.text ?? "")
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            print("Cancel button tapped")
        }
        
        alert.addAction(ok)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
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
        
        func createCells(data : RetailCustomer) -> RetailCustomersTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RetailCustomerCell", for: indexPath) as! RetailCustomersTableViewCell
            
            let date = Date(timeIntervalSince1970: data.timestamp )
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: date)
            
            cell.nameLabel.text = data.name
            cell.addressLabel.text = "Address: \(data.address)"
            cell.phoneNumberLabel.text = "Phone: \(data.phone)"
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
    
    //MARK: Table Cell Button Actions
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let delete = UIContextualAction(style: .normal, title: "Delete") {  (contextualAction, view, boolValue) in
            
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Confirm", message: "Are you sure you want to Delete this Customer?", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
                if (self.resultSearchController.isActive) {
                    self.deleteCustomer(data: self.filteredDataArray[self.filteredDataArray.count - indexPath.row - 1])
                }
                else {
                    //Remove Data Array Item
                    self.deleteCustomer(data: self.dataArray[self.dataArray.count - indexPath.row - 1])
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
            
            func updateCustomer (data : RetailCustomer) {
                if self.resultSearchController.isActive  {
                    self.resultSearchController.isActive = false
                }
                let alert = UIAlertController(title: "Update Customer", message: "Customer: \(data.name)", preferredStyle: .alert)
                
                alert.addTextField { (textField) in
                    textField.placeholder = "Address"
                    textField.text = data.address
                    textField.keyboardType = .default
                    textField.autocapitalizationType = .words
                }
                alert.addTextField { (textField) in
                    textField.placeholder = "Contact Number"
                    textField.text = data.phone
                    textField.keyboardType = .phonePad
                }
                alert.addTextField { (textField) in
                    textField.placeholder = "Marketing"
                    textField.text = data.marketing
                    textField.keyboardType = .default
                    textField.autocapitalizationType = .words
                }
                
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                    let textField = alert.textFields![0]
                    let textField1 = alert.textFields![1]
                    let textField2 = alert.textFields![2]

                    guard textField.text ?? "" != "" && textField1.text ?? "" != "" && textField2.text ?? "" != "" else {
                        print("Incomplete Data")
                        let dialogMessage = UIAlertController(title: "Incomplete Data", message: "Text Field Empty", preferredStyle: .alert)
                        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                            print("Ok button tapped")
                        })
                        dialogMessage.addAction(ok)
                        self.present(dialogMessage, animated: true, completion: nil)
                        return
                    }
                    self.createCustomer(name: data.name, address: textField.text ?? "", phone: textField1.text ?? "", marketing: textField2.text ?? "")
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (resultSearchController.isActive) {
            print(filteredDataArray[self.filteredDataArray.count - indexPath.row - 1].name)
            if previousMenu == "New Purchase Order" {
                self.delegate?.retailCustomerDataReceived(customer: filteredDataArray[self.filteredDataArray.count - indexPath.row - 1])
                resultSearchController.isActive = false
                self.navigationController?.popViewController(animated: true)
            }
        }
        else {
            print(dataArray[self.dataArray.count - indexPath.row - 1].name)
            if previousMenu == "New Purchase Order" {
                self.delegate?.retailCustomerDataReceived(customer: dataArray[self.dataArray.count - indexPath.row - 1])
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    //QLPreviewController Methods
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return csvPath as QLPreviewItem
    }
}
