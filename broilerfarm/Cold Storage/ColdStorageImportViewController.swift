//
//  ColdStorageImportViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 6/29/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import SVProgressHUD
import Firebase
import FirebaseFirestore
import NotificationBannerSwift
import UIEmptyState

class ColdStorageImportTableViewCell : UITableViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var quantityLabel: UILabel!
    @IBOutlet var unitLabel: UILabel!
    
}

class ColdStorageImportViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIEmptyStateDataSource, UIEmptyStateDelegate, sendRPAProductData, sendStorageData {
    
    var fullName : String = ""
    var loginClass : String = ""
    var selectedStorage : String = ""
    var selectedStoragePrice : Int = 0
    var selectedStorageNumberOfFreeDays : Int = 0
    
    var dataArray : [ColdStorageItem] = [ColdStorageItem]()
        
    //UI Empty State Variables
    var emptyStateTitle: NSAttributedString {
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor(red: 0.882, green: 0.890, blue: 0.859, alpha: 1.00),
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22)]
        return NSAttributedString(string: "No Products Selected", attributes: attrs)
    }
    
    var emptyStateImage: UIImage? {
        return UIImage(named: "redLogo")
    }

    @IBOutlet var navItem: UINavigationItem!
    @IBOutlet var finishButton: UIButton!
    @IBOutlet var rightBarButton: UIBarButtonItem!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var totalKgLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light

        // Set the data source and delegate
        self.emptyStateDataSource = self
        self.emptyStateDelegate = self
        
        // Remove seperator lines from empty cells
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        self.tableView.reloadData()
        self.reloadEmptyStateForTableView(self.tableView)
        
        navItem.title = "\(selectedStorage) Import"
    }
    
    func storageDataReceived(storage: StorageProvider) {
        navItem.title = "\(storage.name) Import"
        selectedStorage = storage.name
        selectedStoragePrice = storage.pricePerKgPerDay
        selectedStorageNumberOfFreeDays = storage.numberOfFreeDays
    }
    
    func rpaProductDataReceived(rpaProduct: RPAProduct) {
        var productNames : [String] = [String]()
        for data in dataArray {
            productNames.append(data.name)
        }
        guard productNames.contains(rpaProduct.name) == false else {
            print("Product Already Selected")
            let dialogMessage = UIAlertController(title: "Product Already Selected", message: "Tap on table cell to update quantity", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        var coldStorageItem : ColdStorageItem = ColdStorageItem(batchId: "", name: "", operations: [Bool](), notes: [String](), quantities: [Float](), units: [String](), creators: [String](), timestamps: [Double](), storages: [String](), pricePerKgPerDays: [Int](), numberOfFreeDays: [Int](), additionalCosts: [Int](), additionalCostDescriptions: [String]())
        
        coldStorageItem.name = rpaProduct.name
        coldStorageItem.operations.append(true)
        coldStorageItem.notes.append("")
        coldStorageItem.quantities.append(1.0)
        coldStorageItem.units.append(rpaProduct.unit)
        coldStorageItem.creators.append(fullName)
        coldStorageItem.timestamps.append(NSDate().timeIntervalSince1970)
        coldStorageItem.storages.append(selectedStorage)
        coldStorageItem.pricePerKgPerDays.append(selectedStoragePrice)
        coldStorageItem.numberOfFreeDays.append(selectedStorageNumberOfFreeDays)
        dataArray.append(coldStorageItem)
        updateLabels()
        self.tableView.reloadData()
        self.reloadEmptyStateForTableView(self.tableView)
    }
    
    func updateLabels() {
        var quantities : [Float] = [Float]()
        for data in dataArray {
            quantities.append(data.quantities[0])
        }
        let total = quantities.reduce(0, +)
        totalKgLabel.text = "Total: \(String(format: "%.2f", total)) KG"
    }
    
    @IBAction func rightBarButtonPressed(_ sender: Any) {
        guard selectedStorage != "" else {
            let dialogMessage = UIAlertController(title: "No Storage Selected", message: "Please pick storage provider.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        self.performSegue(withIdentifier: "goToProducts", sender: self)
    }
    
    @IBAction func filterBarButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "goToStorageProviders", sender: self)
    }
    
    @IBAction func finishButtonPressed(_ sender: Any) {
        print("Finish")
        guard selectedStorage != "" else {
            let dialogMessage = UIAlertController(title: "No Storage Selected", message: "Please pick storage provider.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard dataArray.isEmpty == false else {
            let dialogMessage = UIAlertController(title: "No Products to Import", message: "Tap on (+) button to add products)", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        for i in 0..<dataArray.count {
            if i == dataArray.count - 1 {
                createStorageImportDocument(name: dataArray[i].name, operations: dataArray[i].operations, notes: dataArray[i].notes, quantities: dataArray[i].quantities, units: dataArray[i].units, creators: dataArray[i].creators, timestamps: dataArray[i].timestamps, storages: dataArray[i].storages, pricePerKgPerDays: dataArray[i].pricePerKgPerDays, numberOfFreeDays: dataArray[i].numberOfFreeDays, additionalCosts: dataArray[i].additionalCosts, additionalCostDescriptions: dataArray[i].additionalCostDescriptions, lastDoc: true)
            }
            else {
                createStorageImportDocument(name: dataArray[i].name, operations: dataArray[i].operations, notes: dataArray[i].notes, quantities: dataArray[i].quantities, units: dataArray[i].units, creators: dataArray[i].creators, timestamps: dataArray[i].timestamps, storages: dataArray[i].storages, pricePerKgPerDays: dataArray[i].pricePerKgPerDays, numberOfFreeDays: dataArray[i].numberOfFreeDays, additionalCosts: dataArray[i].additionalCosts, additionalCostDescriptions: dataArray[i].additionalCostDescriptions, lastDoc: false)
            }
        }
    }
    
    func createStorageImportDocument (name : String, operations : [Bool], notes : [String], quantities : [Float], units : [String], creators : [String], timestamps : [Double], storages : [String], pricePerKgPerDays : [Int], numberOfFreeDays : [Int], additionalCosts: [Int], additionalCostDescriptions: [String], lastDoc : Bool) {
        
        let doc = Firestore.firestore().collection("coldStorage").document()
        
        doc.setData([
            "batchId" : "Unavailable (Manual Import)",
            "name" : name,
            "operations" : operations,
            "notes" : notes,
            "quantities" : quantities,
            "units" : units,
            "creators" : creators,
            "timestamps" : timestamps,
            "storages" : storages,
            "pricePerKgPerDays" : pricePerKgPerDays,
            "numberOfFreeDays" : numberOfFreeDays,
            "additionalCosts" : additionalCosts,
            "additionalCostDescriptions" : additionalCostDescriptions
        ]) { err in
            if let err = err {
                print("Error writing document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error writing Document", style: .danger)
                banner.show()
            } else {
                print("Document successfully Created!")
                if lastDoc {
                    let ColdStorageDataChangeNotification = Notification.Name("coldStorageDataChanged")
                    NotificationCenter.default.post(name: ColdStorageDataChangeNotification, object: nil)
                    let banner = StatusBarNotificationBanner(title: "Documents Successfully Created", style: .success)
                    banner.show()
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    //MARK: Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        func createSelectedProductCells(data : ColdStorageItem) -> ColdStorageImportTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ColdStorageImportCell", for: indexPath) as! ColdStorageImportTableViewCell
            
            cell.nameLabel.text = "\(data.name)"
            cell.quantityLabel.text = "\(data.quantities[0])"
            cell.unitLabel.text = "\(data.units[0])"
        
            return cell
        }
        
        return createSelectedProductCells(data: dataArray[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let alert = UIAlertController(title: "Specify Quantity", message: "\(dataArray[indexPath.row].name) (\(dataArray[indexPath.row].units[0]))", preferredStyle: .alert)
        
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
                print("Invalid Data")
                let dialogMessage = UIAlertController(title: "Invalid Data", message: "Text Field Empty or non-floating number", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            
            self.dataArray[indexPath.row].quantities[0] = Float(textField.text!)!
            self.dataArray[indexPath.row].notes[0] = textField2.text ?? ""
            self.updateLabels()
            self.tableView.reloadData()
            self.reloadEmptyStateForTableView(self.tableView)
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            print("Cancel button tapped")
        }
        
        alert.addAction(ok)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToProducts" {
            let vc = segue.destination as? RPAProductsTableViewController
            vc?.delegate = self
            vc?.pick = true
        }
        else if segue.identifier == "goToStorageProviders" {
            let vc = segue.destination as? StorageProvidersTableViewController
            vc?.delegate = self
            vc?.pick = true
        }
    }
}
