//
//  RetailPreparationTicketViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 4/23/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import SVProgressHUD
import NotificationBannerSwift

class RetailPreparationTicketTableViewCell : UITableViewCell {
    //RetailPreparationTicketCell
    @IBOutlet var productNameLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var notesLabel: UILabel!
    @IBOutlet var quantityLabel: UILabel!
    @IBOutlet var updatedImageView: UIImageView!
}

class RetailPreparationTicketViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var loginClass : String = ""
    var fullName : String = ""
    var purchaseOrder : RetailPurchaseOrder!
    
    var items : [RetailProduct] = [RetailProduct]()
    var itemNotes : [String] = [String]()
    var itemQuantities : [Float] = [Float]()
    var updated : [Bool] = [Bool]()

    @IBOutlet var purchaseOrderNumberLabel: UILabel!
    @IBOutlet var deliveryByLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var finishButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        purchaseOrderNumberLabel.text = purchaseOrder.purchaseOrderNumber
        
        let deliveryByDate = Date(timeIntervalSince1970: purchaseOrder.deliverByDate )
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let stringDeliveryByDate = dateFormatter.string(from: deliveryByDate)
        
        deliveryByLabel.text = "\(purchaseOrder.name) - Deliver By \(stringDeliveryByDate)"
        
        items = purchaseOrder.orderedItems
        itemNotes = purchaseOrder.orderedItemNotes
        itemQuantities = (purchaseOrder.orderedItemQuantities).compactMap(Float.init)
        updated = [Bool](repeating: false, count: items.count)
        self.tableView.reloadData()
    }
    
    @IBAction func finishButtonPressed(_ sender: Any) {
        print("Finish")
        guard items.isEmpty == false else {
            print("No Items")
            let dialogMessage = UIAlertController(title: "Error Finishing Preparation!", message: "No Items.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard updated == [Bool](repeating: true, count: items.count) else {
            print("Missing Real Value")
            let dialogMessage = UIAlertController(title: "Missing Real Value!", message: "One or more items have not been updated with real values.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        //MARK: Check for Stock Document Existance
        for i in 0..<items.count {
            var currentQuantity : Float = 0
            let cycle = Firestore.firestore().collection("retailStock").document(items[i].name)
            
            cycle.getDocument { (document, error) in
                if let document = document, document.exists {
                    print("Stock Document exists")
                    currentQuantity = document.data()!["quantity"] as! Float
                    //Decrement Stock Document
                    var newQuantity : Float = 0
                    newQuantity = currentQuantity - self.itemQuantities[i]
                    self.updateStock(productName: self.items[i].name, quantity: newQuantity)
                    
                } else {
                    print("Stock Document does not exist")
                    currentQuantity = 0
                    self.createNewStock(productName: self.items[i].name, quantity: 0 - self.itemQuantities[i], unit: self.items[i].unit)
                }
            }
            
            //MARK: Create Stock Operation Document
            self.createStockOperation(add: false, productName: self.items[i].name, quantity: self.itemQuantities[i], unit: self.items[i].unit, notes: "AUTO (\(purchaseOrder.purchaseOrderNumber) Prepared)")
        }
        
        //MARK: Update Purchase Order with Real Values
        updatePurchaseOrder()
    }
    
    func updatePurchaseOrder () {
        print("Update Purchase Order")
        finishButton.isEnabled = false
        var realRetailProductNames : [String] = [String]()
        var realRetailProductDescriptions : [String] = [String]()
        var realRetailProductPricePerUnits : [Int] = [Int]()
        var realRetailProductUnits : [String] = [String]()
        var realRetailProductCreatedBys : [String] = [String]()
        var realRetailProductTimestamps : [Double] = [Double]()
        for i in 0..<items.count {
            realRetailProductNames.append(items[i].name)
            realRetailProductDescriptions.append(items[i].description)
            realRetailProductPricePerUnits.append(items[i].pricePerUnit)
            realRetailProductUnits.append(items[i].unit)
            realRetailProductCreatedBys.append(items[i].createdBy)
            realRetailProductTimestamps.append(items[i].timestamp)
        }
        let doc = Firestore.firestore().collection("retailPurchaseOrders").document(purchaseOrder.purchaseOrderNumber)
        doc.updateData([
            "realRetailProductNames" : realRetailProductNames,
            "realRetailProductDescriptions" : realRetailProductDescriptions,
            "realRetailProductPricePerUnits" : realRetailProductPricePerUnits,
            "realRetailProductUnits" : realRetailProductUnits,
            "realRetailProductCreatedBys" : realRetailProductCreatedBys,
            "realRetailProductTimestamps" : realRetailProductTimestamps,
            "realItemNotes" : itemNotes,
            "realItemQuantities" : itemQuantities,
            "status" : "Prepped",
            "preppedBy" : fullName,
        ]) { err in
            if let err = err {
                print("Error writing new product document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error writing Updated Purchase Order Document", style: .danger)
                banner.show()
                self.finishButton.isEnabled = true
            } else {
                print("Purchase Order successfully Created!")
                self.finishButton.isEnabled = true
                //Post Notification for finished purchase order creation
                let PurchaseOrderCreationNotification = Notification.Name("purchaseOrderCreated")
                NotificationCenter.default.post(name: PurchaseOrderCreationNotification, object: nil)
                let banner = StatusBarNotificationBanner(title: "Purchase Order Successfully Updated!", style: .success)
                banner.show()
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func updateStock(productName : String, quantity : Float) {
        let doc = Firestore.firestore().collection("retailStock").document(productName)
        doc.updateData([
            "quantity" : quantity,
            "createdBy" : fullName,
            "timestamp" : NSDate().timeIntervalSince1970
        ]) { err in
            if let err = err {
                print("Error updating stock: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error Performing Stock Update", style: .danger)
                banner.show()
            } else {
                print("Stock successfully Updated!")
                let RetailStockChangeNotification = Notification.Name("retailStockChanged")
                NotificationCenter.default.post(name: RetailStockChangeNotification, object: nil)
            }
        }
    }
    
    func createNewStock(productName : String, quantity : Float, unit : String) {
        let doc = Firestore.firestore().collection("retailStock").document(productName)
        doc.setData([
            "quantity" : quantity,
            "unit" : unit,
            "createdBy" : fullName,
            "timestamp" : NSDate().timeIntervalSince1970
        ]) { err in
            if let err = err {
                print("Error writing new stock document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error Performing Stock Creation", style: .danger)
                banner.show()
            } else {
                print("Stock Document successfully Created!")
                let RetailStockChangeNotification = Notification.Name("retailStockChanged")
                NotificationCenter.default.post(name: RetailStockChangeNotification, object: nil)
            }
        }
    }
    
    func createStockOperation(add : Bool, productName : String, quantity : Float, unit : String, notes : String) {
        let doc = Firestore.firestore().collection("retailStockOperations").document()
        doc.setData([
            "add" : add,
            "isCancelled" : false,
            "isAutomaticallyGenerated" : true,
            "productName" : productName,
            "quantity" : quantity,
            "unit" : unit,
            "notes" : notes,
            "createdBy" : fullName,
            "timestamp" : NSDate().timeIntervalSince1970
        ]) { err in
            if let err = err {
                print("Error writing new product document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error Performing Operation", style: .danger)
                banner.show()
            } else {
                print("Stock Operation Document successfully Created!")
            }
        }
    }
    
    //MARK: Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        func createItemsCell(data : RetailProduct, notes: String, quantity: Float, updated: Bool, index : Int) -> RetailPreparationTicketTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RetailPreparationTicketCell", for: indexPath) as! RetailPreparationTicketTableViewCell
            
            cell.productNameLabel.text = data.name
            cell.descriptionLabel.text = data.description
            cell.notesLabel.text = "Notes: \(notes)"
            cell.quantityLabel.text = "Qty: \(quantity) \(data.unit)"
            if updated {
                cell.updatedImageView.image = UIImage(named: "success")
            }
            else {
                cell.updatedImageView.image = UIImage(named: "error")
            }
            return cell
        }
        
        return createItemsCell(data: items[indexPath.row], notes: itemNotes[indexPath.row], quantity: itemQuantities[indexPath.row], updated: updated[indexPath.row], index: indexPath.row)
    }
    
    //MARK: Table Cell Button Actions
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let delete = UIContextualAction(style: .normal, title: "Delete") {  (contextualAction, view, boolValue) in
            
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Confirm", message: "Are you sure you want to Delete this item?", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
                self.items.remove(at: indexPath.row)
                self.itemNotes.remove(at: indexPath.row)
                self.itemQuantities.remove(at: indexPath.row)
                self.updated.remove(at: indexPath.row)
                self.tableView.reloadData()
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
        
        return UISwipeActionsConfiguration(actions: [delete])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(items[indexPath.row].name)
        print(itemNotes[indexPath.row])
        let alert = UIAlertController(title: "Real Quantity", message: "Please Specify Real Product Quantity", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Quantity"
            textField.keyboardType = .decimalPad
        }
        
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            let textField = alert.textFields![0]
            print(textField.text ?? "")
            let textFieldContents = (textField.text ?? "").replacingOccurrences(of: ",", with: ".")
            guard textFieldContents != "" else {
                print("Incomplete Data")
                let dialogMessage = UIAlertController(title: "Incomplete Data", message: "Text Field Empty", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            guard Float(textFieldContents) ?? 0 != 0 else {
                print("Quantity is non-numerical")
                let dialogMessage = UIAlertController(title: "Error Updating Item!", message: "Quantity is non-numerical", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            self.itemQuantities[indexPath.row] = Float(textFieldContents)!
            self.updated[indexPath.row] = true
            self.tableView.reloadData()
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            print("Cancel button tapped")
        }
        
        alert.addAction(ok)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }

}
