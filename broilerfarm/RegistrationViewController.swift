//
//  RegistrationViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 6/28/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import TextFieldEffects
import SVProgressHUD
import FirebaseAuth
import FirebaseFirestore
import NotificationBannerSwift

class RegistrationViewController: UIViewController {
    
    @IBOutlet var fullNameTextField: JiroTextField!
    @IBOutlet var emailTextField: JiroTextField!
    @IBOutlet var passwordTextField: JiroTextField!
    
    var farmName : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        setupKeyboardDismissRecognizer()
        //Shift elements up when keyboard comes out
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        //Add Done Button on Keyboard
        addDoneButtonOnKeyboard()
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        //Dismiss Keyboard when view appears
        dismissKeyboard()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //Empty Text Fields
        emailTextField.text = ""
        passwordTextField.text = ""
        self.view.endEditing(true)
    }
    
    @IBAction func signUpButtonPressed(_ sender: Any) {
        
        if emailTextField.text != "" && passwordTextField.text != "" && fullNameTextField.text != ""{
            
            SVProgressHUD.show()
            
            //Set up a new user on our Firebase database
            
            Auth.auth().createUser(withEmail: emailTextField.text!, password: passwordTextField.text!) { (user, error) in
                
                if error != nil {
                    
                    print(error!)
                    //Declare Alert message
                    let dialogMessage = UIAlertController(title: "Registration Error", message: error?.localizedDescription, preferredStyle: .alert)
                    
                    // Create OK button with action handler
                    let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                        print("Ok button tapped")
                    })
                    
                    //Add OK and Cancel button to dialog message
                    dialogMessage.addAction(ok)
                    
                    // Present dialog message to user
                    self.present(dialogMessage, animated: true, completion: nil)
                    
                    SVProgressHUD.dismiss()
                    
                } else {
                    print("Registration Successful!")
                    let usersProf = Firestore.firestore().collection("userProfiles").document(self.emailTextField.text!)
                    usersProf.setData([
                        "fullName": self.fullNameTextField.text!,
                        "class": "PENDING APPROVAL",
                        "farmName": "UNASSIGNED",
                        "password": self.passwordTextField.text!
                    ]) { err in
                        if let err = err {
                            print("Error writing document: \(err)")
                        } else {
                            print("Document successfully written!")
                            self.sendNotificationToAdministrators()
                        }
                    }
                    
                    SVProgressHUD.dismiss()
                    
                    self.navigationController?.popViewController(animated: true)
                    
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
        
        else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Text Field's Empty", message: "Please Input Data", preferredStyle: .alert)
            
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
    
    func sendNotificationToAdministrators() {
        let db = Firestore.firestore()
        db.collection("userProfiles").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                SVProgressHUD.dismiss()
                let banner = StatusBarNotificationBanner(title: "Error getting documents", style: .danger)
                banner.show()
            } else {
                for document in querySnapshot!.documents {
                    //print("\(document.documentID) => \(document.data())")
                    if document.data()["class"] as! String == "superadmin" || document.data()["class"] as! String == "administrator"{
                        
                        let sender = PushNotificationSender()
                        let fcmToken = document.data()["fcmToken"] as? String ?? ""
                        if fcmToken != "" {
                            sender.sendPushNotification(to: fcmToken, title: "User Pending Approval", body: self.fullNameTextField.text! + " needs approval to use App")
                        }
                    }
                }
            }
        }
    }
    
    //Tap anywhere to dismiss keyboard function
    func setupKeyboardDismissRecognizer(){
        let tapRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(AuthenticationViewController.dismissKeyboard))
        
        self.view.addGestureRecognizer(tapRecognizer)
    }
    
    @objc func dismissKeyboard(){
        view.endEditing(true)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                let keyboardShift = keyboardSize.height
                self.view.frame.origin.y -= keyboardShift - 120
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is HomepageViewController
        {
            let vc = segue.destination as? HomepageViewController
            vc?.farmName = self.farmName
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
        
        fullNameTextField.inputAccessoryView = doneToolbar
        emailTextField.inputAccessoryView = doneToolbar
        passwordTextField.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction(){
        fullNameTextField.resignFirstResponder()
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
}
