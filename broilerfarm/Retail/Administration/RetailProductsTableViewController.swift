//
//  RetailProductsTableViewController.swift
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

class RetailProductsTableViewCell : UITableViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var pricePerUnitLabel: UILabel!
    @IBOutlet var createdByLabel: UILabel!
}

protocol sendProductData {
    func productDataReceived(product : RetailProduct)
}

class RetailProductsTableViewController: UITableViewController, UIEmptyStateDataSource, UIEmptyStateDelegate, UISearchResultsUpdating {
    
    var loginClass : String = ""
    var fullName : String = ""
    var previousMenu : String = ""
    var delegate : sendProductData?
    
    var dataArray : [RetailProduct] = [RetailProduct]()
    var filteredDataArray : [RetailProduct] = [RetailProduct]()
    var productNames : [String] = [String]()
    
    var resultSearchController = UISearchController()
        
    @IBOutlet var addButton: UIBarButtonItem!
    
    //UI Empty State Variables
    var emptyStateTitle: NSAttributedString {
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor(red: 0.882, green: 0.890, blue: 0.859, alpha: 1.00),
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22)]
        return NSAttributedString(string: "No Products Found", attributes: attrs)
    }
    
    var emptyStateImage: UIImage? {
        return UIImage(named: "redLogo")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        //Enable Add Button for superadmins only
        if loginClass == "superadmin" {
            addButton.isEnabled = true
        }
        else {
            addButton.isEnabled = false
        }
        
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
        let array = (productNames as NSArray).filtered(using: searchPredicate)
        let filteredProductNames = array as! [String]
        //construct Filtered Data Array
        for data in dataArray {
            for productName in filteredProductNames {
                if data.name == productName {
                    filteredDataArray.append(data)
                }
            }
        }
        self.tableView.reloadData()
        self.reloadEmptyState()
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        print("Add")
        let alert = UIAlertController(title: "New Product", message: "Please Specify Product Data", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Product Name"
            textField.keyboardType = .default
            textField.autocapitalizationType = .words
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Description"
            textField.keyboardType = .default
            textField.autocapitalizationType = .words
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Price per Unit"
            textField.keyboardType = .numberPad
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Unit"
            textField.keyboardType = .default
            textField.autocapitalizationType = .allCharacters
        }
        
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            let textField = alert.textFields![0]
            let textField1 = alert.textFields![1]
            let textField2 = alert.textFields![2]
            let textField3 = alert.textFields![3]
            print(textField.text ?? "")
            print(textField1.text ?? "")
            print(textField2.text ?? "")
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
            guard self.productNames.contains(textField.text ?? "") == false else {
                print("Product Already Exists")
                let dialogMessage = UIAlertController(title: "Error Creating Product!", message: "Product Already Exists", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            guard Int(textField2.text ?? "") ?? 0 != 0 else {
                print("Price per Unit is non-numerical")
                let dialogMessage = UIAlertController(title: "Error Creating Product!", message: "Price per Unit is non-numerical", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            
            self.createProduct(name: textField.text ?? "", description: textField1.text ?? "", pricePerUnit: Int(textField2.text ?? "")!, unit: textField3.text ?? "")
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
        db.collection("retailProducts").getDocuments() { (querySnapshot, err) in
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
                self.productNames.removeAll(keepingCapacity: false)
                for document in querySnapshot!.documents {
                    
                    var retailProduct : RetailProduct = RetailProduct(name: "", description: "", pricePerUnit: 0, unit: "", createdBy: "", timestamp: 0)
                    
                    retailProduct.name = document.documentID
                    retailProduct.description = document.data()["description"] as! String
                    retailProduct.pricePerUnit = document.data()["pricePerUnit"] as! Int
                    retailProduct.unit = document.data()["unit"] as! String
                    retailProduct.createdBy = document.data()["createdBy"] as! String
                    retailProduct.timestamp = document.data()["timestamp"] as! Double
                    
                    self.dataArray.append(retailProduct)
                    self.productNames.append(retailProduct.name)
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
    
    func createProduct(name : String, description : String, pricePerUnit : Int, unit : String) {
        let doc = Firestore.firestore().collection("retailProducts").document(name)
        doc.setData([
            "description" : description,
            "pricePerUnit" : pricePerUnit,
            "unit" : unit,
            "createdBy" : fullName,
            "timestamp" : NSDate().timeIntervalSince1970
        ]) { err in
            if let err = err {
                print("Error writing new product document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error writing New Product Document", style: .danger)
                banner.show()
            } else {
                print("Product successfully Created!")
                self.getDataFromServer(pullDownRefresh : false)
            }
        }
    }
    
    func deleteProduct(data : RetailProduct) {
        if resultSearchController.isActive {
            resultSearchController.isActive = false
        }
        SVProgressHUD.show()
        let doc = Firestore.firestore().collection("retailProducts").document(data.name)
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
        
        func createCells(data : RetailProduct) -> RetailProductsTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RetailProductCell", for: indexPath) as! RetailProductsTableViewCell
            
            let date = Date(timeIntervalSince1970: data.timestamp )
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: date)
            
            cell.nameLabel.text = data.name
            cell.descriptionLabel.text = "\(data.description)"
            cell.pricePerUnitLabel.text = "Price/Unit: \(data.pricePerUnit) / \(data.unit)"
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
            let dialogMessage = UIAlertController(title: "Confirm", message: "Are you sure you want to Delete this Product?", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
                if (self.resultSearchController.isActive) {
                    self.deleteProduct(data: self.filteredDataArray[self.filteredDataArray.count - indexPath.row - 1])
                }
                else {
                    //Remove Data Array Item
                    self.deleteProduct(data: self.dataArray[self.dataArray.count - indexPath.row - 1])
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
            
            func updateCustomer (data : RetailProduct) {
                if self.resultSearchController.isActive  {
                    self.resultSearchController.isActive = false
                }
                let alert = UIAlertController(title: "Update Product", message: "Product: \(data.name)", preferredStyle: .alert)
                
                alert.addTextField { (textField) in
                    textField.placeholder = "Description"
                    textField.text = data.description
                    textField.keyboardType = .default
                    textField.autocapitalizationType = .words
                }
                alert.addTextField { (textField) in
                    textField.placeholder = "Price Per Unit"
                    textField.text = String(data.pricePerUnit)
                    textField.keyboardType = .numberPad
                }
                alert.addTextField { (textField) in
                    textField.placeholder = "Unit"
                    textField.text = data.unit
                    textField.keyboardType = .default
                    textField.autocapitalizationType = .allCharacters
                }
                
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                    let textField = alert.textFields![0]
                    let textField1 = alert.textFields![1]
                    let textField2 = alert.textFields![2]
                    guard textField.text ?? "" != "" && textField1.text ?? "" != "" && textField2.text ?? "" != ""else {
                        print("Incomplete Data")
                        let dialogMessage = UIAlertController(title: "Incomplete Data", message: "Text Field Empty", preferredStyle: .alert)
                        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                            print("Ok button tapped")
                        })
                        dialogMessage.addAction(ok)
                        self.present(dialogMessage, animated: true, completion: nil)
                        return
                    }
                    guard Int(textField1.text ?? "") ?? 0 != 0 else {
                        print("Price per Unit is non-numerical")
                        let dialogMessage = UIAlertController(title: "Error Updating Product!", message: "Price per Unit is non-numerical", preferredStyle: .alert)
                        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                            print("Ok button tapped")
                        })
                        dialogMessage.addAction(ok)
                        self.present(dialogMessage, animated: true, completion: nil)
                        return
                    }
                    self.createProduct(name: data.name, description: textField.text ?? "", pricePerUnit: Int(textField1.text ?? "")!, unit: textField2.text ?? "")
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
            if previousMenu == "New Purchase Order" || previousMenu == "Stock Operation" {
                self.delegate?.productDataReceived(product: filteredDataArray[self.filteredDataArray.count - indexPath.row - 1])
                resultSearchController.isActive = false
                self.navigationController?.popViewController(animated: true)
            }
        }
        else {
            print(dataArray[self.dataArray.count - indexPath.row - 1].name)
            if previousMenu == "New Purchase Order" || previousMenu == "Stock Operation" {
                self.delegate?.productDataReceived(product: dataArray[self.dataArray.count - indexPath.row - 1])
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}
