//
//  PriceListViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 10/30/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import TextFieldEffects
import Firebase
import FirebaseFirestore
import SVProgressHUD
import NotificationBannerSwift


class PriceListViewController : UIViewController, UIPickerViewDelegate,UIPickerViewDataSource, UITextFieldDelegate {
    
    var fullName : String = ""
    var loginClass : String = ""
    
    var newFlag : Bool = false
    var selectedName : String = ""
    var selectedPricePerUnit : String = ""
    var selectedUnit : String = ""
    var selectedCategory : String = ""
    var selectedFullName : String = ""
    var selectedTimestamp : String = ""
    
    var category : String = ""
    var categoryPickerData : [String] = [String]()
    
    @IBOutlet var nameTextField: AkiraTextField!
    @IBOutlet var pricePerUnitTextField: AkiraTextField!
    @IBOutlet var unitTextField: AkiraTextField!
    @IBOutlet var categoryTextField: AkiraTextField!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    
    @IBOutlet var pickerView: UIPickerView!
    
    override func viewDidLoad() {
        
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        addDoneButtonOnKeyboard()
        nameTextField.delegate = self
        pricePerUnitTextField.delegate = self
        unitTextField.delegate = self
        categoryTextField.delegate = self
        
        pickerView.delegate = self
        
        categoryPickerData = ["ATK","Dapur","Herbal","Obat","Pakan", "Sanitasi", "Utility","Vaksin","Vitamin","Tenaga Kerja","Humas","DOC","Lain-Lain"]
        
        if newFlag == false {
            nameTextField.text = selectedName
            nameTextField.isUserInteractionEnabled = false
            pricePerUnitTextField.text = selectedPricePerUnit
            unitTextField.text = selectedUnit
            categoryTextField.text = selectedCategory
            
            //Set Author Label
            let date = Date(timeIntervalSince1970: Double(selectedTimestamp) ?? 0)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .medium
            let stringDate = dateFormatter.string(from: date)
            nameLabel.text = "Last Update By: " + selectedFullName
            dateLabel.text = "On " + stringDate
        }
        else {
            nameLabel.text = ""
            dateLabel.text = ""
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    @IBAction func finishButtonPressed(_ sender: Any) {
        if nameTextField.text != "" && pricePerUnitTextField.text != "" && unitTextField.text != "" && categoryTextField.text != "" {
            uploadDataToServer()
        }
    }
    func uploadDataToServer() {
        SVProgressHUD.show()
        let doc = Firestore.firestore().collection("priceList").document(nameTextField.text!)
        doc.setData([
            "pricePerUnit" : pricePerUnitTextField.text!,
            "unit" : unitTextField.text!,
            "category" : categoryTextField.text!,
            "fullName" : fullName,
            "timestamp" : String(NSDate().timeIntervalSince1970)]) { err in
            if let err = err {
                print("Error writing Price List Document: \(err)")
                SVProgressHUD.dismiss()
                let banner = StatusBarNotificationBanner(title: "Error Writing Price List", style: .danger)
                banner.show()
            } else {
                print("Price List Document successfully written!")
                SVProgressHUD.dismiss()
                let banner = StatusBarNotificationBanner(title: "Price List successfully written", style: .success)
                banner.show()
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categoryPickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categoryPickerData[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print(categoryPickerData[row])
        categoryTextField.text = categoryPickerData[row]
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
        
        nameTextField.inputAccessoryView = doneToolbar
        pricePerUnitTextField.inputAccessoryView = doneToolbar
        unitTextField.inputAccessoryView = doneToolbar
        categoryTextField.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction(){
        nameTextField.resignFirstResponder()
        pricePerUnitTextField.resignFirstResponder()
        unitTextField.resignFirstResponder()
        categoryTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        nameTextField.resignFirstResponder()
        pricePerUnitTextField.resignFirstResponder()
        unitTextField.resignFirstResponder()
        categoryTextField.resignFirstResponder()
        return true
    }
}
