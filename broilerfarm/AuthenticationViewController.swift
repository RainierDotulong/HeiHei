//
//  AuthenticationViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 6/26/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import TextFieldEffects
import SVProgressHUD
import Firebase
import FirebaseAuth
import FirebaseFirestore
import CoreData

class AuthenticationViewController: UIViewController {
    
    @IBOutlet var emailTextField: JiroTextField!
    @IBOutlet var passwordTextField: JiroTextField!
    @IBOutlet weak var versionLabel: UILabel!
    
    //Profile Variables
    var farmName : String = ""
    var fullName : String = ""
    var loginClass : String = ""
    
    //Cycle Data Variables
    var cycleNumber : Int  = 0
    var numberOfFloors : Int  = 0
    var hargaPerKwh : Float = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light

        setupKeyboardDismissRecognizer()
        //Shift elements up when keyboard comes out
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        //Set Version Label
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        versionLabel.text = "v" + String(appVersion!)
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
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    @IBAction func signInButtonPressed(_ sender: Any) {
        
        if emailTextField.text != "" && passwordTextField.text != ""{
            
            SVProgressHUD.show()
            
            Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) { (user, error) in
                
                if error != nil {
                    
                    print(error!)
                    
                    //Declare Alert message
                    let dialogMessage = UIAlertController(title: "Login Error", message: error?.localizedDescription, preferredStyle: .alert)
                    
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
                    print("Log in successful!")
                    
                    //Get User Profile from Firebase
                    let usersProf = Firestore.firestore().collection("userProfiles").document(self.emailTextField.text!)
                    
                    usersProf.getDocument { (document, error) in
                        if let document = document, document.exists {
                            let dataDescription = document.data()
                            self.farmName = dataDescription!["farmName"] as! String
                            self.loginClass = dataDescription!["class"] as! String
                            self.fullName = dataDescription!["fullName"] as! String
                            
                            //Get Cycle Number from Firebase
                            let cycle = Firestore.firestore().collection(self.farmName + "Details").document("farmDetail")
                            
                            cycle.getDocument { (document, error) in
                                if let document = document, document.exists {
                                    let dataDescription = document.data()
                                    self.cycleNumber = dataDescription!["currentCycleNumber"] as! Int
                                    self.numberOfFloors = dataDescription!["numberOfFloors"] as! Int
                                    self.hargaPerKwh = dataDescription!["hargaPerKwh"] as! Float
                                    
                                    //Save Login Data to Core Data
                                    self.saveLoginData()
                                    
                                } else {
                                    print("Current Cycle Document does not exist")
                                    //Declare Alert message
                                    let dialogMessage = UIAlertController(title: "Current Cycle Document does not exist", message: "Please Contact Administrator", preferredStyle: .alert)
                                    
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

                         else {
                            print("Profile Document does not exist")
                            //Declare Alert message
                            let dialogMessage = UIAlertController(title: "Profile Document does not exist", message: "Please Contact Administrator", preferredStyle: .alert)
                            
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
            }
        }
        
        else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Text Field's Empty", message: "Please Input Email and Password", preferredStyle: .alert)
            
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
    
    @IBAction func resetPasswordButtonPressed(_ sender: Any) {
        if emailTextField.text != "" {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Reset Password?", message: "Tap OK to send password reset link to Email", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
                Auth.auth().sendPasswordReset(withEmail: self.emailTextField.text!) { error in
                    if error == nil {
                        //Declare Alert message
                        let dialogMessage = UIAlertController(title: "Password Reset Success", message: "Please Check Your Email", preferredStyle: .alert)
                        // Create OK button with action handler
                        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                            print("Ok button tapped")
                        })
                        //Add OK and Cancel button to dialog message
                        dialogMessage.addAction(ok)
                        // Present dialog message to user
                        self.present(dialogMessage, animated: true, completion: nil)
                    }
                    else{
                        //Declare Alert message
                        let dialogMessage = UIAlertController(title: "Password Reset Failed", message: error?.localizedDescription, preferredStyle: .alert)
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
        else{
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Email Text Field Empty", message: "Please Input Your Email Address", preferredStyle: .alert)
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
    
    func saveLoginData() {
        //Core Data Context
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        //Specify CoreData Entity for Profile Data
        let profile = UserProfile(context: context)
        
        profile.email = self.emailTextField.text!
        profile.fullName = self.fullName
        profile.loginClass = self.loginClass
        profile.farmName = self.farmName
        profile.numberOfFloors = Int16(self.numberOfFloors)
        profile.cycleNumber = Int16(self.cycleNumber)
        
        do {
            try context.save()
            print("Data Saved")
            SVProgressHUD.dismiss()
            self.performSegue(withIdentifier: "goToHomepageFromSignIn", sender: self)
            
        } catch {
            print ("Error Saving Context \(error)")
            SVProgressHUD.dismiss()
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Error Saving Login Data", message: "Error Saving Context \(error)", preferredStyle: .alert)
            
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
        if segue.destination is UITabBarController {
            let barViewControllers = segue.destination as! UITabBarController
            let navVC1 = barViewControllers.viewControllers?[0] as! UINavigationController
            let vc1 = navVC1.topViewController as? HomepageViewController
            vc1?.farmName = self.farmName
            vc1?.fullName = self.fullName
            vc1?.email = self.emailTextField.text!
            vc1?.loginClass = self.loginClass
            vc1?.cycleNumber = self.cycleNumber
            vc1?.numberOfFloors = self.numberOfFloors
            
            // access the third tab bar
            let navVC2 = barViewControllers.viewControllers?[1] as! UINavigationController
            let vc2 = navVC2.topViewController as? RetailHomepageViewController
            vc2?.fullName = self.fullName
            vc2?.email = self.emailTextField.text!
            vc2?.loginClass = self.loginClass
            
            // access the fourth tab bar
            let navVC3 = barViewControllers.viewControllers?[2] as! UINavigationController
            let vc3 = navVC3.topViewController as? CarcassHomepageTableViewController
            vc3?.fullName = self.fullName
            vc3?.email = self.emailTextField.text!
            vc3?.loginClass = self.loginClass
            
            // access the fifth tab bar
            let navVC4 = barViewControllers.viewControllers?[3] as! UINavigationController
            let vc4 = navVC4.topViewController as? ColdStorageHomepageViewController
            vc4?.fullName = self.fullName
            vc4?.email = self.emailTextField.text!
            vc4?.loginClass = self.loginClass
            
        }
    }
    
}


