//
//  SignatureViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/10/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import TextFieldEffects

protocol sendToDeliveryPermitVC {
    
    func dataReceivedFromSignatureVC(signImage : UIImage, name : String, signatureIdentifier: String)
    
}

class SignatureViewController : UIViewController, YPSignatureDelegate, UITextFieldDelegate {
    
    var signatureIdentifier: String = ""
    var delegate : sendToDeliveryPermitVC?
    
    @IBOutlet var nameTextField: JiroTextField!
    @IBOutlet var signatureView: YPDrawSignatureView!
    
    override func viewDidLoad() {
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        nameTextField.delegate = self
        // Delegate the signature view
        signatureView.delegate = self
        
        //Shift elements up when keyboard comes out
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelSignature(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func clearSignature(_ sender: Any) {
        self.signatureView.clear()
    }
    @IBAction func saveSignature(_ sender: Any) {
        // Getting the Signature Image from self.drawSignatureView using the method getSignature().
        
        guard nameTextField.text != "" else {
            let dialogMessage = UIAlertController(title: "Invalid Data", message: "Atas nama TTD belum terisi", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        if let signedImage = self.signatureView.getSignature(scale: 5) {
            
            delegate?.dataReceivedFromSignatureVC(signImage : signedImage, name : nameTextField.text ?? "Nama", signatureIdentifier: signatureIdentifier)
            
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func didStart(_ view: YPDrawSignatureView) {
        print("Started Drawing Signature")
    }
    
    func didFinish(_ view: YPDrawSignatureView) {
        print("Finished Drawing Signature")
    }
    
    @objc func doneButtonAction(){
        nameTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        nameTextField.resignFirstResponder()
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
}
