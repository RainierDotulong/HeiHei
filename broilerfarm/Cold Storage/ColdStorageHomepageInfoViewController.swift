//
//  ColdStorageHomepageInfoViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 6/29/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class ColdStorageHomepageInfoViewController: UIViewController {
    
    var selectedData : ColdStorageItem = ColdStorageItem(batchId: "", name: "", operations: [Bool](), notes: [String](), quantities: [Float](), units: [String](), creators: [String](), timestamps: [Double](), storages: [String](), pricePerKgPerDays: [Int](), numberOfFreeDays: [Int](), additionalCosts: [Int](), additionalCostDescriptions: [String]())
    
    var payload : String = ""

    @IBOutlet var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        payload.append("Document ID : \(selectedData.id!)\n")
        payload.append("Batch ID : \(selectedData.batchId)\n\n")
        payload.append("Name : \(selectedData.name)\n")
        payload.append("-----------------------------\n")
        payload.append("Operation History:\n")
        for i in 0..<selectedData.operations.count {
            var operation : String = ""
            if selectedData.operations[i] {
                operation = "Import"
            }
            else {
                operation = "Export"
            }
            payload.append("\(String(format: "%.2f", selectedData.quantities[i])) \(selectedData.units[i]) \(operation)\n")
            payload.append("\(selectedData.notes[i])\n")
            payload.append("Created By: \(selectedData.creators[i])\n\n")
        }
        let currentQuantity = ColdStorageCalculations().calculateCurrentQuantity(operations: selectedData.operations, quantities: selectedData.quantities)
        payload.append("Current Quantity --> \(String(format: "%.2f", currentQuantity)) KG\n\n")
        payload.append("Storage History:\n")
        for i in 0..<selectedData.storages.count {
            let date = Date(timeIntervalSince1970: selectedData.timestamps[i] )
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: date)
            payload.append("\(selectedData.storages[i]) since \(stringDate)\n")
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            let formattedPricePerKgPerDay = numberFormatter.string(from: NSNumber(value: selectedData.pricePerKgPerDays[i]))
            payload.append("Price/KG/Day: Rp. \(formattedPricePerKgPerDay!)\n")
            payload.append("Number of Free Day(s): \(selectedData.numberOfFreeDays[i])\n\n")
        }
        let numberFormatter = NumberFormatter()
        let storageCosts = ColdStorageCalculations().calculateStorageCosts(numberOfFreeDays: selectedData.numberOfFreeDays, pricePerKgPerDays: selectedData.pricePerKgPerDays, timestamps: selectedData.timestamps)
        let formattedStorageCosts = numberFormatter.string(from: NSNumber(value: storageCosts))
        payload.append("Total Storage Cost --> Rp. \(formattedStorageCosts!)\n\n")
        
        payload.append("Additional Costs:\n")
        for i in 0..<selectedData.additionalCosts.count {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            let formattedAdditionalCost = numberFormatter.string(from: NSNumber(value: selectedData.additionalCosts[i]))
            payload.append("\(selectedData.additionalCostDescriptions[i]) --> Rp. \(formattedAdditionalCost!)\n")
        }
        payload.append("\n")
        let currentHPP = ColdStorageCalculations().calculateCurrentHPP(additionalCosts: selectedData.additionalCosts, numberOfFreeDays: selectedData.numberOfFreeDays, pricePerKgPerDays: selectedData.pricePerKgPerDays, timestamps: selectedData.timestamps)
        numberFormatter.numberStyle = .decimal
        let formattedCurrentHPP = numberFormatter.string(from: NSNumber(value: currentHPP))
        
        payload.append("Current HPP --> Rp. \(formattedCurrentHPP!)")
        
        textView.text = payload
        
        getBatchData(batchId: selectedData.batchId)
    }
    
    func getBatchData(batchId : String) {
        //Get User Profile from Firebase
        let docRef = Firestore.firestore().collection("carcassProduction").document(batchId)
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                
                var carcassProduction : CarcassProduction = CarcassProduction(hargaBeliAyam: 0, transportName: "", transportBank: "", transportBankNumber: "", transportBankName: "", transportPaymentTerm: "", amountDueForTransport: 0, licensePlateNumber: "", sourceFarm: "", escort: "", transportedWeight: 0, transportedQuantity: 0, transportCreatedBy: "", transportCreatedTimestamp: 0, rpaName: "", rpaAddress: "", rpaLatitude: 0, rpaLongitude: 0, rpaNoNkv: "", rpaPerhitunganBiaya: "", rpaPaymentTerm: "", rpaSideProduct: false, rpaContactPerson: "", rpaContactPhone: "", rpaBank: "", rpaBankName: "", rpaBankNumber: "", slaughterTimestamp: 0, typeOfWork: "", receivedWeight: 0, receivedQuantity: 0, receivedDeadWeight: 0, receivedDeadQuantity: 0, rpaInputCreatedBy: "", rpaInputCreatedTimestamp: 0, yieldedWeight: 0, yieldedProductNames: [String](), yieldedProductUnits: [String](), yieldedProductQuantities: [Float](), initialStorageProvider: "", rpaOutputCreatedBy: "", rpaOutputCreatedTimestamp: 0, rpaHargaPerKG: 0)
                
                carcassProduction.id = document.documentID
                carcassProduction.hargaBeliAyam = document.data()?["hargaBeliAyam"] as? Int ?? 0
                carcassProduction.transportName = document.data()?["transportName"] as? String ?? ""
                carcassProduction.transportBank = document.data()?["transportBank"] as? String ?? ""
                carcassProduction.transportBankNumber = document.data()?["transportBankNumber"] as? String ?? ""
                carcassProduction.transportBankName = document.data()?["transportBankName"] as? String ?? ""
                carcassProduction.transportPaymentTerm = document.data()?["transportPaymentTerm"] as? String ?? ""
                carcassProduction.amountDueForTransport = document.data()?["amountDueForTransport"] as? Int ?? 0
                carcassProduction.sourceFarm = document.data()?["sourceFarm"] as? String ?? ""
                carcassProduction.escort = document.data()?["escort"] as? String ?? ""
                carcassProduction.transportedWeight = document.data()?["transportedWeight"] as? Float ?? 0
                carcassProduction.transportedQuantity = document.data()?["transportedQuantity"] as? Int ?? 0
                carcassProduction.transportCreatedBy = document.data()?["transportCreatedBy"] as? String ?? ""
                carcassProduction.transportCreatedTimestamp = document.data()?["transportCreatedTimestamp"] as? Double ?? 0
                carcassProduction.rpaName = document.data()?["rpaName"] as? String ?? ""
                carcassProduction.rpaAddress = document.data()?["rpaAddress"] as? String ?? ""
                carcassProduction.rpaLatitude = document.data()?["rpaLatitude"] as? Double ?? 0
                carcassProduction.rpaLongitude = document.data()?["rpaLongitude"] as? Double ?? 0
                carcassProduction.rpaNoNkv = document.data()?["rpaNoNkv"] as? String ?? ""
                carcassProduction.rpaPerhitunganBiaya = document.data()?["rpaPerhitunganBiaya"] as? String ?? ""
                carcassProduction.rpaHargaPerKG = document.data()?["rpaHargaPerKG"] as? Int ?? 0
                carcassProduction.rpaPaymentTerm = document.data()?["rpaPaymentTerm"] as? String ?? ""
                carcassProduction.rpaSideProduct = document.data()?["rpaSideProduct"] as? Bool ?? false
                carcassProduction.rpaContactPerson = document.data()?["rpaContactPerson"] as? String ?? ""
                carcassProduction.rpaContactPhone = document.data()?["rpaContactPhone"] as? String ?? ""
                carcassProduction.rpaBank = document.data()?["rpaBank"] as? String ?? ""
                carcassProduction.rpaBankName = document.data()?["rpaBankName"] as? String ?? ""
                carcassProduction.rpaBankNumber = document.data()?["rpaBankNumber"] as? String ?? ""
                carcassProduction.slaughterTimestamp = document.data()?["slaughterTimestamp"] as? Double ?? 0
                carcassProduction.typeOfWork = document.data()?["typeOfWork"] as? String ?? ""
                carcassProduction.receivedWeight = document.data()?["receivedWeight"] as? Float ?? 0
                carcassProduction.receivedQuantity = document.data()?["receivedQuantity"] as? Int ?? 0
                carcassProduction.receivedDeadWeight = document.data()?["receivedDeadWeight"] as? Float ?? 0
                carcassProduction.receivedDeadQuantity = document.data()?["receivedDeadQuantity"] as? Int ?? 0
                carcassProduction.rpaInputCreatedBy = document.data()?["rpaInputCreatedBy"] as? String ?? ""
                carcassProduction.rpaInputCreatedTimestamp = document.data()?["rpaInputCreatedTimestamp"] as? Double ?? 0
                carcassProduction.yieldedWeight = document.data()?["yieldedWeight"] as? Float ?? 0
                carcassProduction.yieldedProductNames = document.data()?["yieldedProductNames"] as? [String] ?? [String]()
                carcassProduction.yieldedProductUnits = document.data()?["yieldedProductUnits"] as? [String] ?? [String]()
                carcassProduction.yieldedProductQuantities = document.data()?["yieldedProductQuantities"] as? [Float] ?? [Float]()
                carcassProduction.initialStorageProvider = document.data()?["initialStorageProvider"] as? String ?? ""
                carcassProduction.rpaOutputCreatedBy = document.data()?["rpaOutputCreatedBy"] as? String ?? ""
                carcassProduction.rpaOutputCreatedTimestamp = document.data()?["rpaOutputCreatedTimestamp"] as? Double ?? 0
                
                
                self.textView.text.append("\n\nBatch Details\n")
                self.textView.text.append("-----------------------------\n")
                self.textView.text.append("Transport:\n")
                self.textView.text.append("\(carcassProduction.transportName)\n")
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .decimal
                let formattedAmountDueForTransport = numberFormatter.string(from: NSNumber(value: carcassProduction.amountDueForTransport))
                self.textView.text.append("Amount Due: Rp. \(formattedAmountDueForTransport!)\n")
                self.textView.text.append("Source Farm: \(carcassProduction.sourceFarm)\n")
                self.textView.text.append("Escort: \(carcassProduction.escort)\n")
                self.textView.text.append("Transported Weight: \(String(format:"%.2f",carcassProduction.transportedWeight)) KG\n")
                self.textView.text.append("Transported Quantity: \(carcassProduction.transportedQuantity)\n\n")
                self.textView.text.append("RPA:\n")
                self.textView.text.append("\(carcassProduction.rpaName)\n")
                self.textView.text.append("\(carcassProduction.rpaAddress)\n")
                self.textView.text.append("Type of Work: \(carcassProduction.typeOfWork.capitalized)\n")
                self.textView.text.append("Received Weight: \(String(format: "%.2f",carcassProduction.receivedWeight)) KG\n")
                self.textView.text.append("Received Quantity: \(carcassProduction.receivedQuantity)\n\n")
                self.textView.text.append("Total Yielded Weight: \(String(format: "%.2f", carcassProduction.yieldedWeight)) KG\n\n")
                self.textView.text.append("Yielded Products:\n")
                for i in 0..<carcassProduction.yieldedProductNames.count {
                    self.textView.text.append("\(carcassProduction.yieldedProductNames[i]) -- \(String(format:"%.2f",carcassProduction.yieldedProductQuantities[i])) \(carcassProduction.yieldedProductUnits[i])\n")
                }
                self.textView.text.append("\nInitial Storage Provider: \(carcassProduction.initialStorageProvider)\n")
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short
                let stringDate = dateFormatter.string(from: Date(timeIntervalSince1970: carcassProduction.rpaOutputCreatedTimestamp))
                self.textView.text.append("RPA Output Date: \(stringDate)\n")
            } else {
                print("Current Cycle Document does not exist")
                //Declare Alert message
                let dialogMessage = UIAlertController(title: "Current Cycle Document does not exist", message: "Please Contact Administrator", preferredStyle: .alert)
                
                // Create OK button with action handler
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                
                //Add OK and Cancel button to dialog message
                dialogMessage.addAction(ok)
                
                // Present dialog message to user
                self.present(dialogMessage, animated: true, completion: nil)
            }
        }
    }
}
