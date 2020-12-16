//
//  ColdStorageHomepageViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 6/28/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import SVProgressHUD
import Firebase
import FirebaseFirestore
import NotificationBannerSwift
import UIEmptyState

class ColdStorageHomepageTableViewCell : UITableViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var quantityLabel: UILabel!
    @IBOutlet var batchIdLabel: UILabel!
    @IBOutlet var currentStorageProviderLabel: UILabel!
    @IBOutlet var currentHppLabel: UILabel!
}

class ColdStorageHomepageViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIEmptyStateDataSource, UIEmptyStateDelegate, UISearchResultsUpdating {
    
    var fullName : String = ""
    var email : String = ""
    var loginClass : String = ""
    
    var dataArray : [ColdStorageItem] = [ColdStorageItem]()
    var filteredDataArray : [ColdStorageItem] = [ColdStorageItem]()
    
    var selectedData : ColdStorageItem = ColdStorageItem(batchId: "", name: "", operations: [Bool](), notes: [String](), quantities: [Float](), units: [String](), creators: [String](), timestamps: [Double](), storages: [String](), pricePerKgPerDays: [Int](), numberOfFreeDays: [Int](), additionalCosts: [Int](), additionalCostDescriptions: [String]())
    
    var itemNames : [String] = [String]()
    
    var resultSearchController = UISearchController()
    
    //UI Empty State Variables
    var emptyStateTitle: NSAttributedString {
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor(red: 0.882, green: 0.890, blue: 0.859, alpha: 1.00),
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22)]
        return NSAttributedString(string: "No Items Available", attributes: attrs)
    }
    
    var emptyStateImage: UIImage? {
        return UIImage(named: "redLogo")
    }
    
    @IBOutlet var navItem: UINavigationItem!
    @IBOutlet var rightBarButton: UIBarButtonItem!
    @IBOutlet var addBarButton: UIBarButtonItem!
    
    @IBOutlet var tableView: UITableView!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light

        // Set the data source and delegate
        self.emptyStateDataSource = self
        self.emptyStateDelegate = self
        
        // Remove seperator lines from empty cells
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        //SearchBar
        resultSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.obscuresBackgroundDuringPresentation = false
            controller.searchBar.sizeToFit()

            tableView.tableHeaderView = controller.searchBar

            return controller
        })()
        
        //Pull to Refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:  #selector(refresh), for: .valueChanged)
        self.tableView.refreshControl = refreshControl
        
        getDataFromServer(pullDownRefresh: false)
        
        let ColdStorageDataChangeNotification = Notification.Name("coldStorageDataChanged")
        NotificationCenter.default.addObserver(self, selector: #selector(coldStorageDataChanged(_:)), name: ColdStorageDataChangeNotification, object: nil)
        
    }
    
    @objc func refresh() {
        print("Refresh")
        getDataFromServer(pullDownRefresh : true)
    }
    
    @objc func coldStorageDataChanged(_ notification:Notification) {
        getDataFromServer(pullDownRefresh : false)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredDataArray.removeAll(keepingCapacity: false)

        let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchController.searchBar.text!)
        let array = (itemNames as NSArray).filtered(using: searchPredicate)
        let filteredItemNameArray = array as! [String]
        //construct Filtered Data Array
        for data in dataArray {
            for itemName in filteredItemNameArray {
                if data.name == itemName && filteredDataArray.contains(data) == false {
                    filteredDataArray.append(data)
                }
            }
        }
        self.tableView.reloadData()
        self.reloadEmptyStateForTableView(self.tableView)
    }
    
    @IBAction func rightBarButtonPressed(_ sender: Any) {
        print("Right Bar Button Pressed")
        getDataFromServer(pullDownRefresh : false)
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "goToImport", sender: self)
    }
    
    func getDataFromServer(pullDownRefresh : Bool) {
        if pullDownRefresh == false {
            SVProgressHUD.show()
        }
        Firestore.firestore().collection("coldStorage").addSnapshotListener { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
              print("No documents")
              if pullDownRefresh == true {
                self.tableView.refreshControl?.endRefreshing()
              }
              else {
                  SVProgressHUD.dismiss()
              }
              return
            }
            
            self.dataArray = documents.compactMap { queryDocumentSnapshot -> ColdStorageItem? in
              return try? queryDocumentSnapshot.data(as: ColdStorageItem.self)
            }
            print(self.dataArray.count)
            
            self.itemNames.removeAll(keepingCapacity: false)
            for data in self.dataArray {
                self.itemNames.append(data.name)
            }
            
            if pullDownRefresh == true {
                self.tableView.refreshControl?.endRefreshing()
            }
            else {
                SVProgressHUD.dismiss()
            }
            self.tableView.reloadData()
            self.reloadEmptyStateForTableView(self.tableView)
        }
    }
    
    func exportItem () {
        let alert = UIAlertController(title: "Export Item", message: "Specify Quantity & Notes for \(selectedData.name) export", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "100.5"
            textField.keyboardType = .decimalPad
        }
        
        alert.addTextField { (textField) in
            textField.placeholder = "Notes"
            textField.keyboardType = .default
            textField.autocapitalizationType = .sentences
        }
        
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            let textField = alert.textFields![0]
            let textField2 = alert.textFields![1]
            
            guard Float(textField.text?.replacingOccurrences(of: ",", with: ".") ?? "0") ?? 0 != 0 else {
                let dialogMessage = UIAlertController(title: "Invalid Data", message: "QuantityText Field Empty or non-floating number", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            
            guard textField2.text != "" else {
                let dialogMessage = UIAlertController(title: "Invalid Data", message: "Notes Text Field Empty", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            
            //Update Data
            self.selectedData.operations.append(false)
            self.selectedData.notes.append(textField2.text!)
            self.selectedData.quantities.append(Float(textField.text!)!)
            self.selectedData.units.append("KG")
            self.selectedData.creators.append(self.fullName)
            
            let isUpdateSuccess = ColdStorageItem.update(coldStorage: self.selectedData)
            if isUpdateSuccess {
                let banner = StatusBarNotificationBanner(title: "Cold Storage Record Updated!", style: .success)
                banner.show()
            }
            else {
                let banner = StatusBarNotificationBanner(title: "Error Updating Cold Storage Record!", style: .danger)
                banner.show()
            }
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            print("Cancel button tapped")
        }
        
        alert.addAction(ok)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if  (resultSearchController.isActive) {
            return filteredDataArray.count
        }
        else {
            return dataArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        func createProductCell(data : ColdStorageItem) -> ColdStorageHomepageTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ColdStorageHomepageCell", for: indexPath) as! ColdStorageHomepageTableViewCell
            
            let currentQuantity = ColdStorageCalculations().calculateCurrentQuantity(operations: data.operations, quantities: data.quantities)
            let currentHpp = ColdStorageCalculations().calculateCurrentHPP(additionalCosts: data.additionalCosts, numberOfFreeDays: data.numberOfFreeDays, pricePerKgPerDays: data.pricePerKgPerDays, timestamps: data.timestamps)
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            let formattedCurrentHpp = numberFormatter.string(from: NSNumber(value: currentHpp))
            
            cell.nameLabel.text = "\(data.name)"
            cell.quantityLabel.text = "Quantity: \(String(format: "%.2f", currentQuantity)) KG"
            cell.batchIdLabel.text = "Batch ID: \(data.batchId)"
            cell.currentStorageProviderLabel.text = "Storage: \(data.storages.last ?? "")"
            cell.currentHppLabel.text = "Current HPP: Rp. \(formattedCurrentHpp!)/KG"
        
            return cell
        }
        if (resultSearchController.isActive) {
            return createProductCell(data: filteredDataArray[indexPath.row])
        }
        else {
            return createProductCell(data: dataArray[indexPath.row])
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: Table Cell Button Actions
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let info = UIContextualAction(style: .normal, title: "Info") {  (contextualAction, view, boolValue) in
            
            if (self.resultSearchController.isActive) {
                self.selectedData = self.filteredDataArray[indexPath.row]
                self.resultSearchController.isActive = false
                self.performSegue(withIdentifier: "goToInfo", sender: self)
            }
            else {
                self.selectedData = self.dataArray[indexPath.row]
                self.performSegue(withIdentifier: "goToInfo", sender: self)
            }
        }
        
        info.image = UIImage(systemName: "info.circle.fill")
        info.backgroundColor = .systemYellow
        
        let export = UIContextualAction(style: .normal, title: "Export") {  (contextualAction, view, boolValue) in
            
            if (self.resultSearchController.isActive) {
                self.selectedData = self.filteredDataArray[indexPath.row]
                self.exportItem()
                self.resultSearchController.isActive = false
            }
            else {
                self.selectedData = self.dataArray[indexPath.row]
                self.exportItem()
            }
        }
        
        export.image = UIImage(systemName: "arrow.up.circle.fill")
        export.backgroundColor = .systemRed
        
        let transfer = UIContextualAction(style: .normal, title: "Transfer") {  (contextualAction, view, boolValue) in
            
            if (self.resultSearchController.isActive) {
                self.selectedData = self.filteredDataArray[indexPath.row]
                self.resultSearchController.isActive = false
                self.performSegue(withIdentifier: "goToTransfer", sender: self)
            }
            else {
                self.selectedData = self.dataArray[indexPath.row]
                self.performSegue(withIdentifier: "goToTransfer", sender: self)
            }
        }
        
        transfer.image = UIImage(systemName: "arrow.right.arrow.left.circle.fill")
        transfer.backgroundColor = .systemGray
        
        let edit = UIContextualAction(style: .normal, title: "Edit") {  (contextualAction, view, boolValue) in
            
            if (self.resultSearchController.isActive) {
                self.selectedData = self.filteredDataArray[indexPath.row]
                print("Edit \(self.selectedData.batchId)")
                self.performSegue(withIdentifier: "goToEdit", sender: self)
            }
            else {
                self.selectedData = self.dataArray[indexPath.row]
                print("Edit \(self.selectedData.batchId)")
                self.performSegue(withIdentifier: "goToEdit", sender: self)
            }
        }
        
        edit.image = UIImage(systemName: "square.and.pencil")
        edit.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [info, export, transfer, edit])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToImport" {
            let vc = segue.destination as? ColdStorageImportViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
        }
        else if segue.identifier == "goToInfo" {
            let vc = segue.destination as? ColdStorageHomepageInfoViewController
            vc?.selectedData = selectedData
        }
        else if segue.identifier == "goToTransfer" {
            let vc = segue.destination as? ColdStorageTransferViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.selectedData = selectedData
        }
        else if segue.identifier == "goToEdit" {
            let vc = segue.destination as? ColdStorageEditViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.selectedData = selectedData
        }
    }
}
