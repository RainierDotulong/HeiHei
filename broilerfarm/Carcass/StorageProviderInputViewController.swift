//
//  StorageProviderInputViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 6/25/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import SVProgressHUD
import Firebase
import FirebaseFirestore
import NotificationBannerSwift
import TextFieldEffects

class StorageProviderInputViewController: UIViewController, sendPlaceData, UITextFieldDelegate {
    
    var loginClass : String = ""
    var fullName : String = ""
    var storageNames : [String] = [String]()
    var selectedStorageProvider : StorageProvider = StorageProvider(name: "", address: "", latitude: 0, longitude: 0, contactPerson: "", contactPhone: "", pricePerKgPerDay: 0, numberOfFreeDays: 0, createdBy: "", timestamp: 0)
    var edit : Bool = false

    @IBOutlet var nameTextField: AkiraTextField!
    @IBOutlet var addressTextField: AkiraTextField!
    @IBOutlet var contactPersonTextField: AkiraTextField!
    @IBOutlet var contactPhoneTextField: AkiraTextField!
    @IBOutlet var pricePerKgPerDayTextField: AkiraTextField!
    @IBOutlet var numberOfFreeDaysTextField: AkiraTextField!
    @IBOutlet var latitudeLabel: UILabel!
    @IBOutlet var longitudeLabel: UILabel!
    @IBOutlet var finishButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
               
        //Done Button on keyboard
        addDoneButtonOnKeyboard()
        
        if edit {
            finishButton.setTitle(" Update", for: .normal)
            nameTextField.text = selectedStorageProvider.name
            addressTextField.text = selectedStorageProvider.address
            contactPersonTextField.text = selectedStorageProvider.contactPerson
            contactPhoneTextField.text = selectedStorageProvider.contactPhone
            pricePerKgPerDayTextField.text = String(selectedStorageProvider.pricePerKgPerDay)
            numberOfFreeDaysTextField.text = String(selectedStorageProvider.numberOfFreeDays)
            latitudeLabel.text = String(selectedStorageProvider.latitude)
            longitudeLabel.text = String(selectedStorageProvider.longitude)
        }
    }
    
    func placeDataReceived(address: String, latitude: String, longitude: String) {
        self.latitudeLabel.text = latitude
        self.longitudeLabel.text = longitude
    }
    
    @IBAction func mapsButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "goToGoogleMaps", sender: self)
    }
    
    @IBAction func finishButtonPressed(_ sender: Any) {
        guard nameTextField.text != "" else {
            let dialogMessage = UIAlertController(title: "Name Text Field Empty", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        if edit == false {
            guard storageNames.contains(nameTextField.text!) == false else {
                let dialogMessage = UIAlertController(title: "Storage Already Exists", message: "", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
        }
        guard addressTextField.text != "" else {
            let dialogMessage = UIAlertController(title: "Address Text Field Empty", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard contactPersonTextField.text != "" else {
            let dialogMessage = UIAlertController(title: "Contact Person Text Field Empty", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard contactPhoneTextField.text != "" else {
            let dialogMessage = UIAlertController(title: "Contact Phone Text Field Empty", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard Int(pricePerKgPerDayTextField.text ?? "") ?? 0 != 0 else {
            let dialogMessage = UIAlertController(title: "Harga Per KG per Hari Invalid", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard Int(numberOfFreeDaysTextField.text ?? "") ?? 0 != 0 else {
            let dialogMessage = UIAlertController(title: "Hari Gratis Text Field Invalid", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard latitudeLabel.text != "Latitude" && longitudeLabel.text != "Longitude" else {
            let dialogMessage = UIAlertController(title: "Coordinates Missing!", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        //MARK: Create Storage Document
        createStorage(name: nameTextField.text!, address: addressTextField.text!, latitude: Double(latitudeLabel.text!)!, longitude: Double(longitudeLabel.text!)!, contactPerson: contactPersonTextField.text!, contactPhone: contactPhoneTextField.text!, pricePerKgPerDay: Int(pricePerKgPerDayTextField.text!)!, numberOfFreeDays: Int(numberOfFreeDaysTextField.text!)!, createdBy: self.fullName)
    }
    
    func createStorage(name : String, address : String, latitude : Double, longitude: Double, contactPerson : String, contactPhone : String, pricePerKgPerDay : Int, numberOfFreeDays : Int, createdBy : String) {
        finishButton.isEnabled = false
        let doc = Firestore.firestore().collection("storageProviders").document(name)
        doc.setData([
            "name" : name,
            "address" : address,
            "latitude" : latitude,
            "longitude" : longitude,
            "contactPerson" : contactPerson,
            "contactPhone" : contactPhone,
            "pricePerKgPerDay" : pricePerKgPerDay,
            "numberOfFreeDays" : numberOfFreeDays,
            "createdBy" : createdBy,
            "timestamp" : NSDate().timeIntervalSince1970
        ]) { err in
            if let err = err {
                print("Error writing new Storage document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error writing New Storage Document", style: .danger)
                banner.show()
                self.finishButton.isEnabled = true
            } else {
                print("Storage successfully Created!")
                let StorageProviderCreationNotification = Notification.Name("storageProviderCreated")
                NotificationCenter.default.post(name: StorageProviderCreationNotification, object: nil)
                let banner = StatusBarNotificationBanner(title: "Storage successfully Created!", style: .success)
                banner.show()
                self.finishButton.isEnabled = true
                self.navigationController?.popViewController(animated: true)
            }
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
        
        nameTextField.inputAccessoryView = doneToolbar
        addressTextField.inputAccessoryView = doneToolbar
        contactPersonTextField.inputAccessoryView = doneToolbar
        contactPhoneTextField.inputAccessoryView = doneToolbar
        pricePerKgPerDayTextField.inputAccessoryView = doneToolbar
        numberOfFreeDaysTextField.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction(){
        nameTextField.resignFirstResponder()
        addressTextField.resignFirstResponder()
        contactPersonTextField.resignFirstResponder()
        contactPhoneTextField.resignFirstResponder()
        pricePerKgPerDayTextField.resignFirstResponder()
        numberOfFreeDaysTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        nameTextField.resignFirstResponder()
        addressTextField.resignFirstResponder()
        contactPersonTextField.resignFirstResponder()
        contactPhoneTextField.resignFirstResponder()
        pricePerKgPerDayTextField.resignFirstResponder()
        numberOfFreeDaysTextField.resignFirstResponder()
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is GoogleMapsViewController
        {
            let vc = segue.destination as? GoogleMapsViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.previousMenu = "Storage"
            vc?.delegate = self
        }
    }
}
