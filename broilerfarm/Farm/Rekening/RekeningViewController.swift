//
//  RekeningViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 9/30/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import TextFieldEffects
import Firebase
import FirebaseFirestore

class RekeningViewController : UIViewController, UITextFieldDelegate {
    var company : String = ""
    var bank : String = ""
    var bankNumber : String = ""
    
    @IBOutlet var companyTextField: AkiraTextField!
    @IBOutlet var bankNameTextField: AkiraTextField!
    @IBOutlet var bankNumberTextField: AkiraTextField!
    
    override func viewDidLoad() {
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        if company == "" {
            companyTextField.isUserInteractionEnabled = true
        }
        else {
            companyTextField.isUserInteractionEnabled = false
        }
        companyTextField.text = company
        bankNameTextField.text = bank
        bankNumberTextField.text = bankNumber
        
        companyTextField.delegate = self
        bankNameTextField.delegate = self
        bankNumberTextField.delegate = self
        
        //Add Done Button On Keyboard
        self.addDoneButtonOnKeyboard()
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
        if companyTextField.text != "" && bankNameTextField.text != "" && bankNumberTextField.text != "" {
            uploadDataToServer()
            navigationController?.popViewController(animated: true)
        }
        else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Incomplete Data", message: "Please Complete Input Data", preferredStyle: .alert)
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
    
    func uploadDataToServer() {
        
        let doc = Firestore.firestore().collection("bankNumberList").document(companyTextField.text!)
        doc.setData([
            "bank" : bankNameTextField.text!,
            "bankNumber" : bankNumberTextField.text!]) { err in
            if let err = err {
                print("Error writing Sampling Document: \(err)")
            } else {
                print("Sampling Document successfully written!")
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
        
        bankNumberTextField.inputAccessoryView = doneToolbar
        
    }
    
    @objc func doneButtonAction(){
        bankNumberTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        companyTextField.resignFirstResponder()
        bankNameTextField.resignFirstResponder()
        bankNumberTextField.resignFirstResponder()
        return true
    }
}
