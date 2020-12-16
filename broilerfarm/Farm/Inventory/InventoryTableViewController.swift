//
//  InventoryTableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 12/30/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import SVProgressHUD
import NotificationBannerSwift
import UIEmptyState

class InventoryTableViewCell : UITableViewCell {
    
    @IBOutlet var namaBarangLabel: UILabel!
    @IBOutlet var jumlahLokasiLabel: UILabel!
    @IBOutlet var lastAuditByLabel: UILabel!
    @IBOutlet var locationImageView: UIImageView!
}

class InventoryTableViewController: UITableViewController,UIEmptyStateDataSource, UIEmptyStateDelegate, UISearchResultsUpdating {
    
    var farmName : String = ""
    var fullName : String = ""
    var cycleNumber : Int  = 0
    var loginClass : String  = ""
    
    var selectedDocumentId : String  = ""
    var selectedJumlahBarang : String  = ""
    var selectedLastAudit : String  = ""
    var selectedReporterName : String = ""
    var selectedLocation : String  = ""
    
    var inventoryDataArray : [[String]] = [[String]]()
    var filteredinventoryDataArray : [[String]] = [[String]]()
    var titleDataArray : [String] = [String]()
    
    var resultSearchController = UISearchController()
    
    //UI Empty State Variables
    var emptyStateTitle: NSAttributedString {
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor(red: 0.882, green: 0.890, blue: 0.859, alpha: 1.00),
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22)]
        return NSAttributedString(string: "No Inventory Data Found!", attributes: attrs)
    }
    
    var emptyStateImage: UIImage? {
        return UIImage(named: "redLogo")
    }

    @IBOutlet var navItem: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        navItem.title = "INVENTORY - \(farmName.uppercased()) \(cycleNumber)"
        
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
        
        // Reload the table
        tableView.reloadData()
        self.reloadEmptyState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getInventoryDataFromServer()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    @IBAction func barButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "goToInventoryEdit", sender: self)
    }
    
    func getInventoryDataFromServer() {
        SVProgressHUD.show()
        let db = Firestore.firestore()
        db.collection("\(farmName)\(cycleNumber)Inventory").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                SVProgressHUD.dismiss()
            } else {
                self.inventoryDataArray.removeAll(keepingCapacity: false)
                self.titleDataArray.removeAll(keepingCapacity: false)
                for document in querySnapshot!.documents {
                    var subArray = [String]()
                    //Create unique title Array
                    self.titleDataArray.append(document.documentID)
                    subArray.append(document.documentID)
                    subArray.append(document.data()["jumlahBarang"] as! String)
                    subArray.append(document.data()["lastAudit"] as! String)
                    subArray.append(document.data()["location"] as! String)
                    subArray.append(document.data()["reporterName"] as! String)
                    self.inventoryDataArray.append(subArray)
                }
                SVProgressHUD.dismiss()
                self.tableView.reloadData()
                self.reloadEmptyState()
                SVProgressHUD.dismiss()
            }
        }
    }
    
    func deleteEntry(collection: String, dataArray : [String], indexPath : Int) {
        let db = Firestore.firestore()
        db.collection(collection).document(dataArray[0]).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error removing document", style: .danger)
                banner.show()
            } else {
                print("Document successfully removed!")
                self.getInventoryDataFromServer()
                let banner = StatusBarNotificationBanner(title: "Document successfully removed!", style: .success)
                banner.show()
            }
            if self.resultSearchController.isActive {
                self.resultSearchController.isActive = false
            }
        }
        tableView.reloadData()
        self.reloadEmptyState()
    }
    
    func auditEntry(collection: String, dataArray : [String], indexPath : Int) {
        let db = Firestore.firestore()
        db.collection(collection).document(dataArray[0]).updateData(["lastAudit" : String(NSDate().timeIntervalSince1970),"reporterName" : fullName]) { err in
            if let err = err {
                print("Error Updating document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error Updating document", style: .danger)
                banner.show()
            } else {
                print("Document successfully updated!")
                self.getInventoryDataFromServer()
                let banner = StatusBarNotificationBanner(title: "Document successfully updated!", style: .success)
                banner.show()
            }
            if self.resultSearchController.isActive {
                self.resultSearchController.isActive = false
            }
            
        }
        tableView.reloadData()
        self.reloadEmptyState()
    }
    
    // Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if  (resultSearchController.isActive) {
            return filteredinventoryDataArray.count
        }
        else {
            return inventoryDataArray.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.rowHeight = UITableView.automaticDimension
        
        func createCells(dataArray : [String]) -> InventoryTableViewCell {
            //Format Date from timestamp
            let date = Date(timeIntervalSince1970: TimeInterval(Double(dataArray[2])!))
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: date)
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "inventoryCell", for: indexPath) as! InventoryTableViewCell
            
            cell.namaBarangLabel.text = dataArray[0]
            cell.jumlahLokasiLabel.text = "Jumlah: \(dataArray[1]) - Lokasi: \(dataArray[3])"
            cell.lastAuditByLabel.text = "Audit: \(stringDate), By: \(dataArray[4])"
            cell.locationImageView.image = UIImage(named: LocationToImage(location: dataArray[3]))
            
            return cell
        }
        
        if (resultSearchController.isActive) {
            return createCells(dataArray: filteredinventoryDataArray[self.filteredinventoryDataArray.count - indexPath.row - 1])
        }
        else {
            return createCells(dataArray: inventoryDataArray[self.inventoryDataArray.count - indexPath.row - 1])
        }
    }
    
    //Add Table Cell Button Actions
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let delete = UIContextualAction(style: .normal, title: "Delete") {  (contextualAction, view, boolValue) in
            if  (self.resultSearchController.isActive) {
                print("Delete " + self.filteredinventoryDataArray[self.filteredinventoryDataArray.count - indexPath.row - 1][0])
                self.deleteEntry(collection: "\(self.farmName)\(self.cycleNumber)Inventory", dataArray: self.filteredinventoryDataArray[self.filteredinventoryDataArray.count - indexPath.row - 1], indexPath : indexPath.row)
            }
            else {
                print("Delete " + self.inventoryDataArray[self.inventoryDataArray.count - indexPath.row - 1][0])
                self.deleteEntry(collection: "\(self.farmName)\(self.cycleNumber)Inventory", dataArray: self.inventoryDataArray[self.inventoryDataArray.count - indexPath.row - 1], indexPath : indexPath.row)
            }
        }
        delete.image = UIImage(systemName: "trash")
        delete.backgroundColor = .systemRed
        
        let audit = UIContextualAction(style: .normal, title: "Audit") {  (contextualAction, view, boolValue) in
            if  (self.resultSearchController.isActive) {
                print("Audit " + self.filteredinventoryDataArray[self.filteredinventoryDataArray.count - indexPath.row - 1][0])
                self.auditEntry(collection: "\(self.farmName)\(self.cycleNumber)Inventory", dataArray: self.filteredinventoryDataArray[self.filteredinventoryDataArray.count - indexPath.row - 1], indexPath : indexPath.row)
            }
            else {
                print("Audit " + self.inventoryDataArray[self.inventoryDataArray.count - indexPath.row - 1][0])
                self.auditEntry(collection: "\(self.farmName)\(self.cycleNumber)Inventory", dataArray: self.inventoryDataArray[self.inventoryDataArray.count - indexPath.row - 1], indexPath : indexPath.row)
            }
        }
        
        if loginClass == "administrator" || loginClass == "superadmin" {
            let swipeActions = UISwipeActionsConfiguration(actions: [audit,delete])
            return swipeActions
        }
        else {
            return nil
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredinventoryDataArray.removeAll(keepingCapacity: false)

        let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchController.searchBar.text!)
        let array = (titleDataArray as NSArray).filtered(using: searchPredicate)
        let filteredTitleDataArray = array as! [String]
        //construct Filtered Data Array
        print(filteredTitleDataArray)
        for data in inventoryDataArray {
            for name in filteredTitleDataArray {
                if data[0] == name {
                    filteredinventoryDataArray.append(data)
                }
            }
        }
        self.tableView.reloadData()
        self.reloadEmptyState()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        func assignSelected(dataArray : [String]) {
            selectedDocumentId = dataArray[0]
            selectedJumlahBarang = dataArray[1]
            selectedLastAudit = dataArray[2]
            selectedLocation = dataArray[3]
            selectedReporterName = dataArray[4]
            if resultSearchController.isActive {
                resultSearchController.isActive = false
            }
            print(selectedDocumentId)
            print(selectedJumlahBarang)
            print(selectedLastAudit)
            print(selectedLocation)
            print(selectedReporterName)
            self.performSegue(withIdentifier: "goToInventoryDetails", sender: self)
        }
        
        if (resultSearchController.isActive) {
            assignSelected(dataArray: self.filteredinventoryDataArray[self.filteredinventoryDataArray.count - indexPath.row - 1])
        }
        else {
            assignSelected(dataArray: self.inventoryDataArray[self.inventoryDataArray.count - indexPath.row - 1])
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is InventoryEditViewController
        {
            let vc = segue.destination as? InventoryEditViewController
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.cycleNumber = cycleNumber
            vc?.loginClass = loginClass
        }
        else if segue.destination is InventoryDetailsViewController
        {
            let vc = segue.destination as? InventoryDetailsViewController
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.cycleNumber = cycleNumber
            vc?.loginClass = loginClass
            vc?.selectedDocumentId = selectedDocumentId
            vc?.selectedJumlahBarang = selectedJumlahBarang
            vc?.selectedLastAudit = selectedLastAudit
            vc?.selectedReporterName = selectedReporterName
            vc?.selectedLocation = selectedLocation
        }
    }
}
