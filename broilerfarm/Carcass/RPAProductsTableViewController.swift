//
//  RPAProductsTableViewController.swift
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

protocol sendRPAProductData {
    func rpaProductDataReceived(rpaProduct: RPAProduct)
}


class RPAProductsTableViewCell : UITableViewCell {
    @IBOutlet var productNameLabel: UILabel!
    @IBOutlet var unitLabel: UILabel!
    @IBOutlet var creatorLabel: UILabel!
}

class RPAProductsTableViewController: UITableViewController, UIEmptyStateDataSource, UIEmptyStateDelegate, UISearchResultsUpdating {
    
    var fullName : String = ""
    var loginClass : String = ""
    var pick : Bool = false
    
    var dataArray : [RPAProduct] = [RPAProduct]()
    var filteredDataArray : [RPAProduct] = [RPAProduct]()
    var productNames : [String] = [String]()
    
    var resultSearchController = UISearchController()
    
    var delegate : sendRPAProductData?
    
    //UI Empty State Variables
    var emptyStateTitle: NSAttributedString {
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor(red: 0.882, green: 0.890, blue: 0.859, alpha: 1.00),
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22)]
        return NSAttributedString(string: "No RPA Products Found", attributes: attrs)
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
        let alert = UIAlertController(title: "Add New RPA Product", message: "Please Specify Product Data", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Name"
            textField.keyboardType = .default
            textField.autocapitalizationType = .words
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Unit"
            textField.keyboardType = .default
            textField.autocapitalizationType = .words
        }
        
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            let textField = alert.textFields![0]
            let textField1 = alert.textFields![1]
            
            guard textField.text ?? "" != "" && textField1.text ?? "" != "" else {
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
                print("Provider Already Exists")
                let dialogMessage = UIAlertController(title: "Error Creating Provider!", message: "Provider Already Exists", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            self.createRPAProduct(name: textField.text ?? "", unit: textField1.text ?? "", createdBy: self.fullName)
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
        db.collection("rpaProducts").getDocuments() { (querySnapshot, err) in
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
                    
                    var rpaProduct : RPAProduct = RPAProduct(name: "", unit: "", createdBy: "", timestamp: 0)
                    
                    rpaProduct.name = document.documentID
                    rpaProduct.unit = document.data()["unit"] as! String
                    rpaProduct.createdBy = document.data()["createdBy"] as! String
                    rpaProduct.timestamp = document.data()["timestamp"] as! Double
                    
                    self.dataArray.append(rpaProduct)
                    self.productNames.append(rpaProduct.name)
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
    
    func createRPAProduct(name : String, unit : String, createdBy : String) {
        let doc = Firestore.firestore().collection("rpaProducts").document(name)
        doc.setData([
            "unit" : unit,
            "createdBy" : createdBy,
            "timestamp" : NSDate().timeIntervalSince1970
        ]) { err in
            if let err = err {
                print("Error writing new provider document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error writing New Product Document", style: .danger)
                banner.show()
            } else {
                print("RPA Product successfully Created!")
                self.getDataFromServer(pullDownRefresh : false)
            }
        }
    }
    
    func deleteRPAProduct(data : RPAProduct) {
        if resultSearchController.isActive {
            resultSearchController.isActive = false
        }
        SVProgressHUD.show()
        let doc = Firestore.firestore().collection("rpaProducts").document(data.name)
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
                self.delegate?.rpaProductDataReceived(rpaProduct : filteredDataArray[self.filteredDataArray.count - indexPath.row - 1])
                resultSearchController.isActive = false
                self.navigationController?.popViewController(animated: true)
            }
        }
        else {
            if pick {
                self.delegate?.rpaProductDataReceived(rpaProduct : dataArray[self.dataArray.count - indexPath.row - 1])
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.rowHeight = UITableView.automaticDimension
        
        func createCells(data : RPAProduct) -> RPAProductsTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RPAProductCell", for: indexPath) as! RPAProductsTableViewCell
            
            let date = Date(timeIntervalSince1970: data.timestamp )
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: date)
            
            cell.productNameLabel.text = data.name
            cell.unitLabel.text = "Unit: \(data.unit)"
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
            let dialogMessage = UIAlertController(title: "Confirm", message: "Are you sure you want to Delete this RPA Product?", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
                if (self.resultSearchController.isActive) {
                    self.deleteRPAProduct(data: self.filteredDataArray[self.filteredDataArray.count - indexPath.row - 1])
                }
                else {
                    //Remove Data Array Item
                    self.deleteRPAProduct(data: self.dataArray[self.dataArray.count - indexPath.row - 1])
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
            
            func updateCustomer (data : RPAProduct) {
                if self.resultSearchController.isActive  {
                    self.resultSearchController.isActive = false
                }
                let alert = UIAlertController(title: "Update \(data.name)", message: "Specify New Unit", preferredStyle: .alert)
                
                alert.addTextField { (textField) in
                    textField.placeholder = "Unit"
                    textField.text = data.unit
                    textField.keyboardType = .default
                    textField.autocapitalizationType = .words
                }
                
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                    let textField = alert.textFields![0]
                    
                    guard textField.text ?? "" != "" else {
                        print("Incomplete Data")
                        let dialogMessage = UIAlertController(title: "Incomplete Data", message: "Text Field Empty", preferredStyle: .alert)
                        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                            print("Ok button tapped")
                        })
                        dialogMessage.addAction(ok)
                        self.present(dialogMessage, animated: true, completion: nil)
                        return
                    }
                    self.createRPAProduct(name: data.name, unit: textField.text ?? "", createdBy: self.fullName)
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
