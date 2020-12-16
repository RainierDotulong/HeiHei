//
//  StorageHIstoryEditViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 11/3/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import TextFieldEffects
import Firebase
import FirebaseFirestore
import NotificationBannerSwift

class StorageHistoryEditViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var farmName : String = ""
    var fullName : String = ""
    var cycleNumber : Int  = 0
    var selectedDocumentId : String = ""
    var selectedCategory : String = ""
    var selectedJumlah : String = ""
    var selectedNamaBarang : String = ""
    var selectedReporterName : String = ""
    var selectedSatuan : String = ""
    var selectedAction : String = ""
    var selectedNomorSuratJalan : String = ""
    
    var pickerData : [String] = [String]()

    @IBOutlet var namaBarangTextField: AkiraTextField!
    @IBOutlet var jumlahTextField: AkiraTextField!
    @IBOutlet var satuanTextField: AkiraTextField!
    @IBOutlet var nomorSuratJalanTextField: AkiraTextField!
    @IBOutlet var actionLabel: UILabel!
    
    @IBOutlet var pickerView: UIPickerView!
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        addDoneButtonOnKeyboard()
        if selectedAction == "Storage Export" {
            pickerView.isUserInteractionEnabled = true
            pickerView.isHidden = false
            switch farmName {
            case "pinantik":
                pickerData = ["Umum","Lantai 1","Lantai 2"]
            case "kejayan":
                pickerData = ["Umum","Lantai 1","Lantai 2","Lantai 3"]
            default:
                pickerData = ["Umum","Lantai 1","Lantai 2","Lantai 3","Lantai 4","Lantai 5","Lantai 6"]
            }
            nomorSuratJalanTextField.placeholder = "Lantai"
        }
        actionLabel.text = selectedAction
        namaBarangTextField.text = selectedNamaBarang
        jumlahTextField.text = selectedJumlah
        satuanTextField.text = selectedSatuan
        nomorSuratJalanTextField.text = selectedNomorSuratJalan
    }
    
    @IBAction func updateButtonPressed(_ sender: Any) {
        if jumlahTextField.text != "" {
            if farmName == "Main" {
                uploadDataToServer(collection: "MainStorage", namaBarang: selectedNamaBarang, jumlah: selectedJumlah, satuan: selectedSatuan, category: selectedCategory, nomorSuratJalan: selectedNomorSuratJalan, action: selectedAction, reporterName: fullName)
            }
            uploadDataToServer(collection: "\(farmName)\(cycleNumber)Storage",namaBarang: selectedNamaBarang, jumlah: selectedJumlah, satuan: selectedSatuan, category: selectedCategory, nomorSuratJalan: selectedNomorSuratJalan, action: selectedAction, reporterName: fullName)
        }
        else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Incomplete Data", message: "Please Fill out all Text Fields", preferredStyle: .alert)
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
    
    func uploadDataToServer(collection: String, namaBarang : String, jumlah : String, satuan : String, category : String, nomorSuratJalan: String, action : String, reporterName : String) {
        let doc = Firestore.firestore().collection(collection).document(selectedDocumentId)
        doc.setData([
            "namaBarang" : namaBarang,
            "jumlah" : jumlahTextField.text!,
            "satuan" : satuan,
            "category" : category,
            "nomorSuratJalan" : nomorSuratJalan,
            "action" : action,
            "reporterName" : reporterName
        ]) { err in
            if let err = err {
                print("Error writing Storage Document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error writing Storage Document", style: .danger)
                banner.show()
            } else {
                print("Storage Document successfully Updated!")
                let banner = StatusBarNotificationBanner(title: "Storage Document successfully Updated!", style: .success)
                banner.show()
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    //Picker View Methods
    // Number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    // The data to return fopr the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    //This method is triggered whenever the user makes a change to the picker selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print("SELECTED: " + pickerData[row])
        nomorSuratJalanTextField.text = pickerData[row]
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
    }
    
    @objc func doneButtonAction(){
        jumlahTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        jumlahTextField.resignFirstResponder()
        return true
    }

}
