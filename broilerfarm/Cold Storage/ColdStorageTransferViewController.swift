//
//  ColdStorageTransferViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 6/30/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import NotificationBannerSwift

class ColdStorageTransferViewController: UIViewController, sendStorageData{
    
    var fullName : String = ""
    var loginClass : String = ""
    var selectedData : ColdStorageItem = ColdStorageItem(batchId: "", name: "", operations: [Bool](), notes: [String](), quantities: [Float](), units: [String](), creators: [String](), timestamps: [Double](), storages: [String](), pricePerKgPerDays: [Int](), numberOfFreeDays: [Int](), additionalCosts: [Int](), additionalCostDescriptions: [String]())

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var quantityUnitLabel: UILabel!
    @IBOutlet var currentStorageLabel: UILabel!
    @IBOutlet var destinationStorageButton: UIButton!
    @IBOutlet var transferButton: UIButton!
    @IBOutlet var pricePerKgPerDayLabel: UILabel!
    @IBOutlet var numberOfFreeDaysLabel: UILabel!
    
    var destinationStorage : String = ""
    var destinationPrice : Int = 0
    var destinationNumberOfFreeDays : Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameLabel.text = selectedData.name
        let currentQuantity = ColdStorageCalculations().calculateCurrentQuantity(operations: selectedData.operations, quantities: selectedData.quantities)
        quantityUnitLabel.text = "Quantity: \(String(format: "%.2f", currentQuantity)) \(selectedData.units.last!)"
        currentStorageLabel.text = " Current Storage: \(selectedData.storages.last!)"
    }
    
    func storageDataReceived(storage: StorageProvider) {
        
        guard storage.name != selectedData.storages.last! else {
            let dialogMessage = UIAlertController(title: "Invalid Storage", message: "Item is already in chosen storage.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        destinationStorage = storage.name
        destinationPrice = storage.pricePerKgPerDay
        destinationNumberOfFreeDays = storage.numberOfFreeDays
        
        destinationStorageButton.setTitle(" Storage: \(storage.name)", for: .normal)
        destinationStorageButton.setTitleColor(.black, for: .normal)
        destinationStorageButton.tintColor = .black
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let formattedPricePerKgPerDay = numberFormatter.string(from: NSNumber(value: storage.pricePerKgPerDay))
        pricePerKgPerDayLabel.text = "Price/KG/Day: Rp. \(formattedPricePerKgPerDay!)"
        numberOfFreeDaysLabel.text = "Number of Free Day(s): \(storage.numberOfFreeDays)"
    }
    
    @IBAction func destinationStorageButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "goToStorageProviders", sender: self)
    }
    
    @IBAction func transferButtonPressed(_ sender: Any) {
        guard destinationStorage != "" else {
            let dialogMessage = UIAlertController(title: "Invalid Destination", message: "Please pick destination storage.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        var timestamps = selectedData.timestamps
        timestamps.append(NSDate().timeIntervalSince1970)
        var storages = selectedData.storages
        storages.append(destinationStorage)
        var pricePerKgPerDays = selectedData.pricePerKgPerDays
        pricePerKgPerDays.append(destinationPrice)
        var numberOfFreeDays = selectedData.numberOfFreeDays
        numberOfFreeDays.append(destinationNumberOfFreeDays)
        updateStorageExportDocument(itemData: selectedData, timestamps: timestamps, storages: storages, pricePerKgPerDays: pricePerKgPerDays, numberOfFreeDays: numberOfFreeDays)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToStorageProviders" {
            let vc = segue.destination as? StorageProvidersTableViewController
            vc?.delegate = self
            vc?.pick = true
        }
    }
    
    func updateStorageExportDocument (itemData : ColdStorageItem, timestamps : [Double], storages : [String], pricePerKgPerDays : [Int], numberOfFreeDays : [Int]) {
        transferButton.isEnabled = false
        
        let doc = Firestore.firestore().collection("coldStorage").document(itemData.id!)
        
        doc.updateData([
            "timestamps" : timestamps,
            "storages" : storages,
            "pricePerKgPerDays" : pricePerKgPerDays,
            "numberOfFreeDays" : numberOfFreeDays
        ]) { err in
            if let err = err {
                print("Error writing document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error writing Document", style: .danger)
                banner.show()
            } else {
                print("Document successfully Created!")
                let ColdStorageDataChangeNotification = Notification.Name("coldStorageDataChanged")
                NotificationCenter.default.post(name: ColdStorageDataChangeNotification, object: nil)
                let banner = StatusBarNotificationBanner(title: "Documents Successfully Created", style: .success)
                banner.show()
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}
