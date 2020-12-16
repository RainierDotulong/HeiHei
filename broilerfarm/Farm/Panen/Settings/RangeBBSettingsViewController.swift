//
//  RangeBBSettingsViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/21/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import SVProgressHUD
import NotificationBannerSwift

class RangeBBSettingsViewController: UIViewController {

    @IBOutlet var afkirBawahTextField: UITextField!
    @IBOutlet var afkirAtasTextField: UITextField!
    @IBOutlet var kecilBawahTextField: UITextField!
    @IBOutlet var kecilAtasTextField: UITextField!
    @IBOutlet var mediumBawahTextField: UITextField!
    @IBOutlet var mediumAtasTextField: UITextField!
    @IBOutlet var jumboBawahTextField: UITextField!
    @IBOutlet var jumboAtasTextField: UITextField!
    @IBOutlet var updateButton: UIButton!
    
    var afkirBawah : Float = 0
    var afkirAtas : Float = 0
    var kecilBawah : Float = 0
    var kecilAtas : Float = 0
    var mediumBawah : Float = 0
    var mediumAtas : Float = 0
    var jumboBawah : Float = 0
    var jumboAtas : Float = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        addDoneButtonOnKeyboard()
        
        getRangeBBData()
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    func getRangeBBData() {
        //Get Cycle Number from Firebase
        let rangeBBRef = Firestore.firestore().collection("panenSettings").document("rangeBB")
        
        SVProgressHUD.show()
        rangeBBRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let dataDescription = document.data()
                
                self.afkirBawah = (dataDescription!["afkirBawah"] as! NSNumber).floatValue
                self.afkirAtas = (dataDescription!["afkirAtas"] as! NSNumber).floatValue
                self.kecilBawah = (dataDescription!["kecilBawah"] as! NSNumber).floatValue
                self.kecilAtas = (dataDescription!["kecilAtas"] as! NSNumber).floatValue
                self.mediumBawah = (dataDescription!["mediumBawah"] as! NSNumber).floatValue
                self.mediumAtas = (dataDescription!["mediumAtas"] as! NSNumber).floatValue
                self.jumboBawah = (dataDescription!["jumboBawah"] as! NSNumber).floatValue
                self.jumboAtas = (dataDescription!["jumboAtas"] as! NSNumber).floatValue
                
                self.afkirBawahTextField.text = "\(self.afkirBawah)"
                self.afkirAtasTextField.text = "\(self.afkirAtas)"
                self.kecilBawahTextField.text = "\(self.kecilBawah)"
                self.kecilAtasTextField.text = "\(self.kecilAtas)"
                self.mediumBawahTextField.text = "\(self.mediumBawah)"
                self.mediumAtasTextField.text = "\(self.mediumAtas)"
                self.jumboBawahTextField.text = "\(self.jumboBawah)"
                self.jumboAtasTextField.text = "\(self.jumboAtas)"
                
                SVProgressHUD.dismiss()
                
            } else {
                SVProgressHUD.dismiss()
                //Declare Alert message
                let dialogMessage = UIAlertController(title: "Current Range BB  Document does not exist", message: "Please Contact Administrator or Create a New One", preferredStyle: .alert)
                
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
    
    func updateRangeBBDocument() {
        let doc = Firestore.firestore().collection("panenSettings").document("rangeBB")
        doc.setData([
            "afkirBawah" : Float(self.afkirBawahTextField.text!)!,
            "afkirAtas" : Float(self.afkirAtasTextField.text!)!,
            "kecilBawah" : Float(self.kecilBawahTextField.text!)!,
            "kecilAtas" : Float(self.kecilAtasTextField.text!)!,
            "mediumBawah" : Float(self.mediumBawahTextField.text!)!,
            "mediumAtas" : Float(self.mediumAtasTextField.text!)!,
            "jumboBawah" : Float(self.jumboBawahTextField.text!)!,
            "jumboAtas" : Float(self.jumboAtasTextField.text!)!
        ]) { err in
            if let err = err {
                print("Error writing Range BB Document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error Writing Range BB Document", style: .danger)
                banner.show()
            } else {
                print("Range BB Document successfully written!")
                let banner = StatusBarNotificationBanner(title: "Range BB Successfully Updated!", style: .success)
                banner.show()
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
        
        afkirBawahTextField.inputAccessoryView = doneToolbar
        afkirAtasTextField.inputAccessoryView = doneToolbar
        kecilBawahTextField.inputAccessoryView = doneToolbar
        kecilAtasTextField.inputAccessoryView = doneToolbar
        mediumBawahTextField.inputAccessoryView = doneToolbar
        mediumAtasTextField.inputAccessoryView = doneToolbar
        jumboBawahTextField.inputAccessoryView = doneToolbar
        jumboAtasTextField.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction(){
        afkirBawahTextField.resignFirstResponder()
        afkirAtasTextField.resignFirstResponder()
        kecilBawahTextField.resignFirstResponder()
        kecilAtasTextField.resignFirstResponder()
        mediumBawahTextField.resignFirstResponder()
        mediumAtasTextField.resignFirstResponder()
        jumboBawahTextField.resignFirstResponder()
        jumboAtasTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        afkirBawahTextField.resignFirstResponder()
        afkirAtasTextField.resignFirstResponder()
        kecilBawahTextField.resignFirstResponder()
        kecilAtasTextField.resignFirstResponder()
        mediumBawahTextField.resignFirstResponder()
        mediumAtasTextField.resignFirstResponder()
        jumboBawahTextField.resignFirstResponder()
        jumboAtasTextField.resignFirstResponder()
        return true
    }
    
    @IBAction func updateButtonPressed(_ sender: Any) {
        
        guard Float(afkirBawahTextField.text ?? "99999") ?? 99999 != 99999 && Float(afkirAtasTextField.text ?? "99999") ?? 99999 != 99999 && Float(kecilBawahTextField.text ?? "99999") ?? 99999 != 99999 && Float(kecilAtasTextField.text ?? "99999") ?? 99999 != 99999 && Float(mediumBawahTextField.text ?? "99999") ?? 99999 != 99999 && Float(mediumAtasTextField.text ?? "99999") ?? 99999 != 99999 && Float(jumboBawahTextField.text ?? "99999") ?? 99999 != 99999 && Float(jumboAtasTextField.text ?? "99999") ?? 99999 != 99999 else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Invalid Data", message: "one or more field is non-floating value", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        print("Update")
        updateRangeBBDocument()
    }
}
