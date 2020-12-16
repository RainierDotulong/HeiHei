//
//  OutputRPAViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 6/26/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import SVProgressHUD
import Firebase
import FirebaseFirestore
import NotificationBannerSwift
import TextFieldEffects
import UIEmptyState

class OutputRPAProductsTableViewCell : UITableViewCell {
    @IBOutlet var productNameLabel: UILabel!
    @IBOutlet var quantityLabel: UILabel!
    @IBOutlet var unitLabel: UILabel!
}

class OutputRPAViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIEmptyStateDataSource, UIEmptyStateDelegate, sendRPAProductData, sendStorageData, sendTallyData {
    
    var fullName : String = ""
    var loginClass : String = ""
    var selectedData : CarcassProduction = CarcassProduction(hargaBeliAyam: 0, transportName: "", transportBank: "", transportBankNumber: "", transportBankName: "", transportPaymentTerm: "", amountDueForTransport: 0, licensePlateNumber: "", sourceFarm: "", escort: "", transportedWeight: 0, transportedQuantity: 0, transportCreatedBy: "", transportCreatedTimestamp: 0, rpaName: "", rpaAddress: "", rpaLatitude: 0, rpaLongitude: 0, rpaNoNkv: "", rpaPerhitunganBiaya: "", rpaPaymentTerm: "", rpaSideProduct: false, rpaContactPerson: "", rpaContactPhone: "", rpaBank: "", rpaBankName: "", rpaBankNumber: "", slaughterTimestamp: 0, typeOfWork: "", receivedWeight: 0, receivedQuantity: 0, receivedDeadWeight: 0, receivedDeadQuantity: 0, rpaInputCreatedBy: "", rpaInputCreatedTimestamp: 0, yieldedWeight: 0, yieldedProductNames: [String](), yieldedProductUnits: [String](), yieldedProductQuantities: [Float](), initialStorageProvider: "", rpaOutputCreatedBy: "", rpaOutputCreatedTimestamp: 0, rpaHargaPerKG: 0)
    var edit : Bool = false
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var initialStorageButton: UIButton!
    @IBOutlet var totalKgLabel: UILabel!
    @IBOutlet var rendemenRpaLabel: UILabel!
    @IBOutlet var rendemenKandangLabel: UILabel!
    @IBOutlet var hargaPerKgTextField: AkiraTextField!
    @IBOutlet var amountDueLabel: UILabel!
    @IBOutlet var timeFinishedButton: UIButton!
    @IBOutlet var finishButton: UIButton!
    
    var yieldedProductNames : [String] = [String]()
    var yieldedProductUnits : [String] = [String]()
    var yieldedProductQuantities : [Float] = [Float]()
    
    var totalWeight : Float = 0
    var initialStorage : String = ""
    var initialStoragePrice : Int = 0
    var intialStorageFreeDays : Int = 0
    
    var timeFinished = NSDate().timeIntervalSince1970
    
    //UI Empty State Variables
    var emptyStateTitle: NSAttributedString {
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor(red: 0.882, green: 0.890, blue: 0.859, alpha: 1.00),
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22)]
        return NSAttributedString(string: "Add Products --> Top Right Corner Button", attributes: attrs)
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
        
        self.tableView.reloadData()
        self.reloadEmptyStateForTableView(self.tableView)
        
        //Add Done Button on Keyboard
        addDoneButtonOnKeyboard()
        
        //Shift elements up when keyboard comes out
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    func rpaProductDataReceived(rpaProduct: RPAProduct) {
        guard yieldedProductNames.contains(rpaProduct.name) == false else {
            print("Product Already Selected")
            let dialogMessage = UIAlertController(title: "Product Already Selected", message: "Tap on table cell to update quantity", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        yieldedProductNames.append(rpaProduct.name)
        yieldedProductUnits.append(rpaProduct.unit)
        yieldedProductQuantities.append(1.0)
        self.tableView.reloadData()
        self.reloadEmptyStateForTableView(self.tableView)
        updateLabels()
        calculateAmountDue()
    }
    
    func storageDataReceived(storage: StorageProvider) {
        initialStorage = storage.name
        initialStoragePrice = storage.pricePerKgPerDay
        intialStorageFreeDays = storage.numberOfFreeDays
        initialStorageButton.setTitle(" Initial Storage: \(storage.name)", for: .normal)
        initialStorageButton.setTitleColor(.black, for: .normal)
        initialStorageButton.tintColor = .black
    }
    
    func tallyDataReceived(productNames: [String], productQuantities: [Float], productUnits: [String]) {
        yieldedProductNames = productNames
        yieldedProductUnits = productUnits
        yieldedProductQuantities = productQuantities
        self.tableView.reloadData()
        self.reloadEmptyStateForTableView(self.tableView)
        updateLabels()
        calculateAmountDue()
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func tallyButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "goToTally", sender: self)
    }
    
    @IBAction func initialStorageButtonPressed(_ sender: Any) {
        print("Initial Storage")
        self.performSegue(withIdentifier: "goToStorageProviders", sender: self)
    }
    
    @IBAction func timeFinishedButtonPressed(_ sender: Any) {
        print("Time Finished Button Pressed")
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        
        let alert = UIAlertController(title: "\n\n\n\n\n\n\n\n\n\n\n", message: nil, preferredStyle: .actionSheet)
        alert.view.addSubview(datePicker)
        
        datePicker.snp.makeConstraints { (make) in
            make.centerX.equalTo(alert.view)
            make.top.equalTo(alert.view).offset(8)
        }
        
        let ok = UIAlertAction(title: "OK", style: .default) { (action) in
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: datePicker.date)
            self.timeFinished = datePicker.date.timeIntervalSince1970
            self.timeFinishedButton.setTitle(" \(stringDate)", for: .normal)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        alert.addAction(ok)
        alert.addAction(cancel)
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
        alert.popoverPresentationController?.permittedArrowDirections = []
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func finishButtonPressed(_ sender: Any) {
        guard yieldedProductNames.isEmpty == false else {
            let dialogMessage = UIAlertController(title: "No Products Added", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard Int(hargaPerKgTextField.text ?? "0") ?? 0 != 0 else {
            print("Invalid harga per KG")
            let dialogMessage = UIAlertController(title: "Invalid harga per KG", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard initialStorage != "" else {
            print("Initial Storage Unspecified")
            let dialogMessage = UIAlertController(title: "Initial Storage Unspecified", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        print("Finish")
        //TODO: Cross Check Harga per KG with reference price in RPA DB
        self.finishButton.isEnabled = false
        selectedData.rpaHargaPerKG = Int(hargaPerKgTextField.text!)!
        selectedData.yieldedWeight = totalWeight
        selectedData.yieldedProductNames = yieldedProductNames
        selectedData.yieldedProductUnits = yieldedProductUnits
        selectedData.yieldedProductQuantities = yieldedProductQuantities
        selectedData.initialStorageProvider = initialStorage
        
        let isUpdateSuccess = CarcassProduction.update(carcass: selectedData)
        if isUpdateSuccess {
            let banner = StatusBarNotificationBanner(title: "Carcass Record Updated!", style: .success)
            banner.show()
        }
        else {
            let banner = StatusBarNotificationBanner(title: "Error Updating Carcass Record!", style: .danger)
            banner.show()
        }
        
        for i in 0..<yieldedProductNames.count {
            let transportCostPerKG : Int = Int(Float(selectedData.amountDueForTransport)/totalWeight)
            let hargaBeliAyamPerKG : Int = Int(Float(selectedData.hargaBeliAyam)/totalWeight)
            if i == yieldedProductNames.count - 1 {
                createStorageImportDocument(batchId: selectedData.id!, name: yieldedProductNames[i], operations: [true], notes: ["Auto-Generated from Carcass Production"], quantities: [yieldedProductQuantities[i]], units: [yieldedProductUnits[i]], creators: [fullName], timestamps: [timeFinished], storages: [initialStorage], pricePerKgPerDays: [initialStoragePrice], numberOfFreeDays: [intialStorageFreeDays], additionalCosts: [hargaBeliAyamPerKG,transportCostPerKG,Int(hargaPerKgTextField.text!)!], additionalCostDescriptions: ["Harga Beli Ayam","Ongkos Transport","Ongkos RPA"], lastDoc: true)
            }
            else {
                createStorageImportDocument(batchId: selectedData.id!, name: yieldedProductNames[i], operations: [true], notes: ["Auto-Generated from Carcass Production"], quantities: [yieldedProductQuantities[i]], units: [yieldedProductUnits[i]], creators: [fullName], timestamps: [timeFinished], storages: [initialStorage], pricePerKgPerDays: [initialStoragePrice], numberOfFreeDays: [intialStorageFreeDays], additionalCosts: [hargaBeliAyamPerKG,transportCostPerKG,Int(hargaPerKgTextField.text!)!], additionalCostDescriptions: ["Harga Beli Ayam", "Ongkos Transport","Ongkos RPA"], lastDoc: false)
            }
        }
    }
    func updateLabels() {
        var quantities : [Float] = [Float]()
        for quantity in yieldedProductQuantities {
            quantities.append(quantity)
        }
        let total = quantities.reduce(0, +)
        totalKgLabel.text = "Total: \(String(format: "%.2f", total)) KG"
        totalWeight = total
        
        let farmYield = selectedData.receivedWeight / selectedData.transportedWeight * 100
        rendemenKandangLabel.text = "Farm Yield: \(String(format: "%.2f", farmYield))%"
        
        let rpaYield = total / selectedData.receivedWeight * 100
        rendemenRpaLabel.text = "RPA Yield: \(String(format: "%.2f", rpaYield))%"
        
    }
    
    func calculateAmountDue() {
        guard Int(hargaPerKgTextField.text ?? "0") ?? 0 != 0 else {
            print("Invalid harga per KG")
            return
        }
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let formattedAmountDue = numberFormatter.string(from: NSNumber(value: Int(Float(hargaPerKgTextField.text!)! * totalWeight)))
        amountDueLabel.text = "Rp. \(formattedAmountDue!)"
    }
    
    func createStorageImportDocument (batchId : String, name : String, operations : [Bool], notes : [String], quantities : [Float], units : [String], creators : [String], timestamps : [Double], storages : [String], pricePerKgPerDays : [Int], numberOfFreeDays : [Int], additionalCosts: [Int], additionalCostDescriptions: [String], lastDoc : Bool) {
        
        let doc = Firestore.firestore().collection("coldStorage").document()
        
        doc.setData([
            "batchId" : batchId,
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
        return yieldedProductNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        func createSelectedProductCells(product : String, quantity: Float, unit: String) -> OutputRPAProductsTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "outputRpaProductCell", for: indexPath) as! OutputRPAProductsTableViewCell
            
            cell.productNameLabel.text = "\(product)"
            cell.quantityLabel.text = "\(quantity)"
            cell.unitLabel.text = "\(unit)"
        
            return cell
        }
        
        return createSelectedProductCells(product: yieldedProductNames[indexPath.row], quantity: yieldedProductQuantities[indexPath.row], unit: yieldedProductUnits[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let alert = UIAlertController(title: "Specify Quantity", message: "\(yieldedProductNames[indexPath.row]) (\(yieldedProductUnits[indexPath.row]))", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "100.5"
            textField.keyboardType = .decimalPad
        }
        
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            let textField = alert.textFields![0]
            
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
            
            self.yieldedProductQuantities[indexPath.row] = Float(textField.text!.replacingOccurrences(of: ",", with: "."))!
            self.tableView.reloadData()
            self.reloadEmptyStateForTableView(self.tableView)
            self.updateLabels()
            self.calculateAmountDue()
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            print("Cancel button tapped")
        }
        
        alert.addAction(ok)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: Table Cell Button Actions
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let delete = UIContextualAction(style: .normal, title: "Delete") {  (contextualAction, view, boolValue) in
            
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Confirm", message: "Are you sure you want to Delete this RPA?", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
                self.yieldedProductNames.remove(at: indexPath.row)
                self.yieldedProductUnits.remove(at: indexPath.row)
                self.yieldedProductQuantities.remove(at: indexPath.row)
                self.tableView.reloadData()
                self.reloadEmptyStateForTableView(self.tableView)
                self.updateLabels()
                self.calculateAmountDue()
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
    
    //Add Done Button on Keyboard
    func addDoneButtonOnKeyboard(){
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))
        
        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        hargaPerKgTextField.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction(){
        hargaPerKgTextField.resignFirstResponder()
        calculateAmountDue()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        hargaPerKgTextField.resignFirstResponder()
        calculateAmountDue()
        return true
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        finishButton.isEnabled = false
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                let keyboardShift = keyboardSize.height
                self.view.frame.origin.y -= keyboardShift
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        finishButton.isEnabled = true
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToStorageProviders" {
            let vc = segue.destination as? StorageProvidersTableViewController
            vc?.delegate = self
            vc?.pick = true
        }
        else if segue.identifier == "goToTally" {
            let vc = segue.destination as? TallyViewController
            vc?.delegate = self
        }
    }
}
