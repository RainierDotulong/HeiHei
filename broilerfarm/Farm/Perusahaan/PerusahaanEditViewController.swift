//
//  PerusahaanEditViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/18/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import NotificationBannerSwift

class PerusahaanEditViewController: UIViewController, UITextFieldDelegate {
    
    var fullName : String = ""
    var loginClass : String = ""
    var isEdit : Bool = false

    @IBOutlet var namaPerusahaanTextField: UITextField!
    @IBOutlet var alamatPerusahaanTextField: UITextField!
    @IBOutlet var kontakPerusahaanTextField: UITextField!
    @IBOutlet var noTelpPerusahaanTextField: UITextField!
    
    @IBOutlet var tipePerusahaanButton: UIButton!
    @IBOutlet var finishButton: UIButton!
    
    var tipePerusahaan : String = ""
    
    var selectedData : Perusahaan = Perusahaan(id: "", timestamp: 99999, companyName: "", companyAddress: "", companyType: "", contactName: "", contactPhone: "", createdBy: "  ")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        addDoneButtonOnKeyboard()
        
        if isEdit {
            namaPerusahaanTextField.text = selectedData.companyName
            alamatPerusahaanTextField.text = selectedData.companyAddress
            kontakPerusahaanTextField.text = selectedData.contactName
            noTelpPerusahaanTextField.text = selectedData.contactPhone
            tipePerusahaan = selectedData.companyType
            tipePerusahaanButton.setTitle(" Tipe Perusahaan: \(selectedData.companyType)", for: .normal)
            tipePerusahaanButton.setTitleColor(.black, for: .normal)
            tipePerusahaanButton.tintColor = .black
            finishButton.setTitle(" Update", for: .normal)
        }
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    @IBAction func tipePerusahaanButtonPressed(_ sender: Any) {
        print("Tipe Perusahaan")
        let dialogMessage = UIAlertController(title: "Tipe Perusahaan", message: "Pilih Tipe Perusahaan.", preferredStyle: .alert)
        
        let bakul = UIAlertAction(title: "Bakul", style: .default, handler: { (action) -> Void in
            print("Bakul")
            self.tipePerusahaan = "Bakul"
            self.tipePerusahaanButton.setTitle(" Tipe Perusahaan: Bakul", for: .normal)
            self.tipePerusahaanButton.setTitleColor(.black, for: .normal)
            self.tipePerusahaanButton.tintColor = .black
        })
        
        let rpa = UIAlertAction(title: "RPA", style: .default, handler: { (action) -> Void in
            print("RPA")
            self.tipePerusahaan = "RPA"
            self.tipePerusahaanButton.setTitle(" Tipe Perusahaan: RPA", for: .normal)
            self.tipePerusahaanButton.setTitleColor(.black, for: .normal)
            self.tipePerusahaanButton.tintColor = .black
        })
        
        let broker = UIAlertAction(title: "Broker", style: .default, handler: { (action) -> Void in
            print("Broker")
            self.tipePerusahaan = "Broker"
            self.tipePerusahaanButton.setTitle(" Tipe Perusahaan: Broker", for: .normal)
            self.tipePerusahaanButton.setTitleColor(.black, for: .normal)
            self.tipePerusahaanButton.tintColor = .black
        })
        
        dialogMessage.addAction(bakul)
        dialogMessage.addAction(rpa)
        dialogMessage.addAction(broker)
        
        self.present(dialogMessage, animated: true, completion: nil)
    }
    
    @IBAction func finishButtonPressed(_ sender: Any) {
        guard namaPerusahaanTextField.text != "" else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Invalid Nama Perusahaan", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard alamatPerusahaanTextField.text != "" else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Invalid Alamat Perusahaan", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard kontakPerusahaanTextField.text != "" else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Invalid Kontak Perusahaan", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard noTelpPerusahaanTextField.text != "" else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Invalid No Telp Perusahaan", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard tipePerusahaan != "" else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Invalid Tipe Perusahaan", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        print("Finish")
        if isEdit {
            let isUpdateRecordSuccess = Perusahaan.update(documentId: selectedData.id! ,timestamp: Date().timeIntervalSince1970, companyName: namaPerusahaanTextField.text!, companyAddress: alamatPerusahaanTextField.text!, companyType: tipePerusahaan, contactName: kontakPerusahaanTextField.text!, contactPhone: noTelpPerusahaanTextField.text!, createdBy: fullName)
            
            if isUpdateRecordSuccess {
                let banner = StatusBarNotificationBanner(title: "Perusahaan Update Success!", style: .success)
                banner.show()
                let PerusahaanChangeNotification = Notification.Name("perusahaanChanged")
                NotificationCenter.default.post(name: PerusahaanChangeNotification, object: nil)
                navigationController?.popViewController(animated: true)
            }
            else {
                let banner = StatusBarNotificationBanner(title: "Error Updating Perusahaan!", style: .danger)
                banner.show()
            }
        }
        else {
            let isCreateRecordSuccess = Perusahaan.create(timestamp: Date().timeIntervalSince1970, companyName: namaPerusahaanTextField.text!, companyAddress: alamatPerusahaanTextField.text!, companyType: tipePerusahaan, contactName: kontakPerusahaanTextField.text!, contactPhone: noTelpPerusahaanTextField.text!, createdBy: fullName)
            
            if isCreateRecordSuccess {
                let banner = StatusBarNotificationBanner(title: "Perusahaan Update Success!", style: .success)
                banner.show()
                let PerusahaanChangeNotification = Notification.Name("perusahaanChanged")
                NotificationCenter.default.post(name: PerusahaanChangeNotification, object: nil)
                navigationController?.popViewController(animated: true)
            }
            else {
                let banner = StatusBarNotificationBanner(title: "Error Updating Perusahaan!", style: .danger)
                banner.show()
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
        
        namaPerusahaanTextField.inputAccessoryView = doneToolbar
        alamatPerusahaanTextField.inputAccessoryView = doneToolbar
        kontakPerusahaanTextField.inputAccessoryView = doneToolbar
        noTelpPerusahaanTextField.inputAccessoryView = doneToolbar

    }
    
    @objc func doneButtonAction(){
        namaPerusahaanTextField.resignFirstResponder()
        alamatPerusahaanTextField.resignFirstResponder()
        kontakPerusahaanTextField.resignFirstResponder()
        noTelpPerusahaanTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        namaPerusahaanTextField.resignFirstResponder()
        alamatPerusahaanTextField.resignFirstResponder()
        kontakPerusahaanTextField.resignFirstResponder()
        noTelpPerusahaanTextField.resignFirstResponder()
        return true
    }
}
