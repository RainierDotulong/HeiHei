//
//  TallyViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 7/1/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import TextFieldEffects

protocol sendTallyData {
    func tallyDataReceived(productNames: [String], productQuantities: [Float], productUnits : [String] )
}

class TallyTableViewCell : UITableViewCell {
    @IBOutlet var noLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var quantityLabel: UILabel!
    @IBOutlet var weightLabel: UILabel!
}

class TallyViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, sendRPAProductData {
    
    var nameArray : [String] = ["Nama Barang"]
    var quantityArray : [String] = ["Jumlah"]
    var weightArray : [String] = ["Berat"]

    @IBOutlet var finishBarButton: UIBarButtonItem!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var productNameButton: UIButton!
    @IBOutlet var jumlahTextField: AkiraTextField!
    @IBOutlet var beratTextField: AkiraTextField!
    @IBOutlet var jumlahLabel: UILabel!
    @IBOutlet var beratLabel: UILabel!
    
    var selectedProduct : String = ""
    
    var delegate : sendTallyData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        // Remove seperator lines from empty cells
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        self.tableView.reloadData()
        
        //Add Done Button on Keyboard
        addDoneButtonOnKeyboard()
        
        //Shift elements up when keyboard comes out
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func rpaProductDataReceived(rpaProduct: RPAProduct) {
        selectedProduct = rpaProduct.name
        productNameButton.setTitle(" \(rpaProduct.name)", for: .normal)
        productNameButton.setTitleColor(.black, for: .normal)
        productNameButton.tintColor = .black
    }
    
    func updateLabels() {
        let quantityInt = quantityArray.compactMap(Int.init)
        let weightFloat = weightArray.compactMap(Float.init)
        let totalQuantity = quantityInt.reduce(0,+)
        let totalWeight = weightFloat.reduce(0,+)
        jumlahLabel.text = "Jumlah: \(totalQuantity)"
        beratLabel.text = "Berat: \(String(format: "%.2f", totalWeight)) KG"
    }
    
    @IBAction func finishButtonPressed(_ sender: Any) {
        print("Finish")
        
        //Declare Alert message
        let dialogMessage = UIAlertController(title: "Confirm", message: "Are you sure you want to Finish this Tally?", preferredStyle: .alert)
        // Create OK button with action handler
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            self.finishTally()
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
    
    func finishTally() {
        guard nameArray.count > 1 else {
            let dialogMessage = UIAlertController(title: "No Product Selected", message: "Tap on product button to select a product", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        var uniqueNames = [String]()
        var quantities = [Int]()
        var weights = [Float]()
        var units = [String]()
        
        //Get Uniqe Name Array
        for i in 1..<nameArray.count {
            if uniqueNames.contains(nameArray[i]) == false {
                uniqueNames.append(nameArray[i])
            }
        }
        print(uniqueNames)
        for uniqueName in uniqueNames {
            var totalQuantity : [Int] = [Int]()
            var totalWeight : [Float] = [Float]()
            for i in 1..<nameArray.count {
                if uniqueName == nameArray[i] {
                    totalQuantity.append(Int(quantityArray[i])!)
                    totalWeight.append(Float(weightArray[i])!)
                }
            }
            quantities.append(totalQuantity.reduce(0,+))
            weights.append(totalWeight.reduce(0,+))
            units.append("KG")
        }
        print(quantities)
        print(weights)
        print(units)
        
        self.delegate?.tallyDataReceived(productNames: uniqueNames, productQuantities: weights, productUnits: units)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        
        guard selectedProduct != "" else {
            let dialogMessage = UIAlertController(title: "No Product Selected", message: "Tap on product button to select a product", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard Int(jumlahTextField.text ?? "0") ?? 0 != 0 else {
            let dialogMessage = UIAlertController(title: "Jumlah Text Field Invalid", message: "Quantity non-integer or empty.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard Float(beratTextField.text ?? "0") ?? 0 != 0 else {
            let dialogMessage = UIAlertController(title: "Berat Text Field Invalid", message: "Weight non-floating or empty.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        nameArray.append(selectedProduct)
        quantityArray.append(jumlahTextField.text!)
        weightArray.append(beratTextField.text!)
        
        beratTextField.text = ""
        
        self.tableView.reloadData()
        updateLabels()
    }
    
    @IBAction func productNameButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "goToProducts", sender: self)
    }
    
    //MARK: Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        func createTallyCells(name : String, quantity: String, weight: String) -> TallyTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "tallyCell", for: indexPath) as! TallyTableViewCell
            
            if indexPath.row == 0 {
                cell.noLabel.text = "No"
            }
            else {
                cell.noLabel.text = "\(indexPath.row)"
            }
            cell.nameLabel.text = "\(name)"
            cell.quantityLabel.text = "\(quantity)"
            cell.weightLabel.text = "\(weight)"
        
            return cell
        }
        
        return createTallyCells(name: nameArray[indexPath.row], quantity: quantityArray[indexPath.row], weight: weightArray[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: Table Cell Button Actions
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let delete = UIContextualAction(style: .normal, title: "Delete") {  (contextualAction, view, boolValue) in
            
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Confirm", message: "Are you sure you want to Delete this Entry?", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
                self.nameArray.remove(at: indexPath.row)
                self.quantityArray.remove(at: indexPath.row)
                self.weightArray.remove(at: indexPath.row)
                self.tableView.reloadData()
                self.updateLabels()
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
        
        //Exception for first row
        if indexPath.row == 0 {
            return UISwipeActionsConfiguration(actions: [])
        }
        else {
            return UISwipeActionsConfiguration(actions: [delete])
        }
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
        
        jumlahTextField.inputAccessoryView = doneToolbar
        beratTextField.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction(){
        jumlahTextField.resignFirstResponder()
        beratTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        jumlahTextField.resignFirstResponder()
        beratTextField.resignFirstResponder()
        return true
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                let keyboardShift = keyboardSize.height
                self.view.frame.origin.y -= keyboardShift
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToProducts" {
            let vc = segue.destination as? RPAProductsTableViewController
            vc?.delegate = self
            vc?.pick = true
        }
    }
}
