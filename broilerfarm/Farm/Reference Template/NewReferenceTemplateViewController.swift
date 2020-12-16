//
//  NewReferenceTemplateViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 12/21/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import TextFieldEffects
import Firebase
import FirebaseFirestore
import SVProgressHUD
import NotificationBannerSwift

class NewReferenceTableViewCell : UITableViewCell {
    @IBOutlet var ageLabel: UILabel!
    @IBOutlet var dataTextField: UITextField!
    
}

class NewReferenceTemplateViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    var fullName : String = ""
    var newFlag : Bool = true
    var selectedTemplateArray : [String] = [String]()
    var selectedTemplateDataArray : [String] = [String]()
    
    var tableViewData : [String] = [String]()
    var pickerData : [String] = ["Category","bw", "adg", "deplesi", "pakan", "fcr", "effTemp","populasi","ip"]

    @IBOutlet var templateNameTextField: AkiraTextField!
    @IBOutlet var categoryLabel: UILabel!
    @IBOutlet var referenceDataTableView: UITableView!
    @IBOutlet var barButton: UIBarButtonItem!
    
    var activeField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        if newFlag == true {
            tableViewData = Array(repeating: "Data", count: 46)
        }
        else {
            let template = selectedTemplateArray[0].components(separatedBy: "-")
            templateNameTextField.text = template[0]
            categoryLabel.text = template[1]
            tableViewData = selectedTemplateDataArray
        }
        referenceDataTableView.reloadData()
        
        registerForKeyboardNotifications()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        uploadReferenceData()
    }
    
    func uploadReferenceData() {
        guard templateNameTextField.text != "" else {
            print("Template Name Empty")
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Incomplete Data", message: "Template Name Empty", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard categoryLabel.text != "CATEGORY" else {
            print("Category Selection Empty")
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Incomplete Data", message: "Category Selection Empty", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard tableViewData.contains("Data") == false else {
            print("Incomplete Data")
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Incomplete Data", message: "Data Field Empty", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        //Upload Data to Server
        barButton.isEnabled = false
        let doc = Firestore.firestore().collection("referenceTemplate").document("\(templateNameTextField.text!.replacingOccurrences(of: "-", with: " "))-\(categoryLabel.text!)")
        doc.setData([
            "data" : tableViewData,
            "fullName" : fullName,
            "timestamp" : String(NSDate().timeIntervalSince1970)
        ],merge: true) { err in
            if let err = err {
                print("Error writing Reference Template Document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error writing Reference Template Document", style: .danger)
                banner.show()
                self.barButton.isEnabled = true
            } else {
                print("Reference Template Document successfully written!")
                let banner = StatusBarNotificationBanner(title: "Reference Template Update Success", style: .success)
                banner.show()
                self.barButton.isEnabled = true
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    //TableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.rowHeight = UITableView.automaticDimension
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "referenceDataTableViewCell", for: indexPath) as! NewReferenceTableViewCell
        
        cell.ageLabel.text = String(indexPath.row)
        cell.dataTextField.delegate = self
        cell.dataTextField.tag = indexPath.row
        cell.dataTextField.text = tableViewData[indexPath.row]
        
        //Add Done BUtton on Keyboard
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonAction))

        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()

        cell.dataTextField.inputAccessoryView = doneToolbar
        cell.dataTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        return cell
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        tableViewData[textField.tag] = textField.text ?? "Data"
    }
    
    @objc func doneButtonAction(){
        self.view.endEditing(true)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(tableViewData[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    //PickerView Data Source
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row].uppercased()
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        categoryLabel.text = pickerData[row].uppercased()
        print(pickerData[row])
    }
    
    func registerForKeyboardNotifications(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func textFieldDidBeginEditing(_ textField: UITextField){
        activeField = textField
    }

    func textFieldDidEndEditing(_ textField: UITextField){
        activeField = nil
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if activeField != templateNameTextField {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= 155
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if activeField != templateNameTextField {
            if self.view.frame.origin.y != 0 {
                self.view.frame.origin.y = 0
            }
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        templateNameTextField.resignFirstResponder()
        return true
    }
}
