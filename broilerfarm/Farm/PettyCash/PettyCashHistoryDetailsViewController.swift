//
//  PettyCashHistoryDetailsViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 11/13/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import TextFieldEffects
import SVProgressHUD
import Firebase
import FirebaseStorage
import FirebaseFirestore
import NotificationBannerSwift

class PettyCashHistoryDetailsViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var farmName : String = ""
    var fullName : String = ""
    var loginClass : String = ""
    var cycleNumber : Int = 0
    var selectedTimestamp : String = ""
    var selectedAction : String = ""
    var selectedChecked : String = ""
    var selectedNominal : String = ""
    var selectedCategory : String = ""
    var selectedReporterName : String = ""

    @IBOutlet var nominalTextField: AkiraTextField!
    @IBOutlet var categoryTextField: AkiraTextField!
    @IBOutlet var checkImageView: UIImageView!
    @IBOutlet var actionImageView: UIImageView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var updateButton: UIButton!
    @IBOutlet var pickerView: UIPickerView!
    
    var nominal : String = ""
    var categoryData : [String] = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        if loginClass == "administrator" || loginClass == "superadmin" {
            updateButton.isEnabled = true
            nominalTextField.isUserInteractionEnabled = true
            pickerView.isUserInteractionEnabled = true
        }
        else {
            updateButton.isEnabled = false
            nominalTextField.isUserInteractionEnabled = false
            pickerView.isUserInteractionEnabled = false
        }
        
        addDoneButtonOnKeyboard()
        
        nominal = selectedNominal
        
        //Format Nominal
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let formattedNominal = numberFormatter.string(from: NSNumber(value:Int(selectedNominal)!))
        nominalTextField.text = formattedNominal
        categoryTextField.text = selectedCategory
        
        if selectedAction == "Cash In" {
            categoryData = ["Cash", "Transfer"]
            downloadFile(imageRef: "\(farmName)\(cycleNumber)PettyCashInImages/\(selectedTimestamp).jpeg")
            actionImageView.image = UIImage(named : "moneyIn")
        }
        else if selectedAction == "Cash Out" {
            categoryData = ["Bongkar kristal","Humas bulanan","Indomie","Makan borongan panen","Makan borongan bongkar","Operasional kandang","Tabur sekam","Uang makan","Lain-lain"]
            downloadFile(imageRef: "\(farmName)\(cycleNumber)PettyCashOutImages/\(selectedTimestamp).jpeg")
            actionImageView.image = UIImage(named : "moneyOut")
        }
        
        if selectedChecked == "false" {
            checkImageView.image = UIImage(named : "error")
        }
        else if selectedChecked == "true" {
            checkImageView.image = UIImage(named : "success")
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
    
    @IBAction func updateButtonPressed(_ sender: Any) {
        if nominalTextField.text != "" {
            let doc = Firestore.firestore().collection("\(farmName)\(cycleNumber)PettyCash").document(selectedTimestamp)
            doc.setData([
                "nominal" : nominal,
                "action" : selectedAction,
                "category" : selectedCategory,
                "checked" : selectedChecked,
                "reporterName" : fullName
                
            ]) { err in
                if let err = err {
                    print("Error updating Petty Cash Document: \(err)")
                    let banner = StatusBarNotificationBanner(title: "Error updating Petty Cash Document", style: .danger)
                    banner.show()
                } else {
                    print("Petty Cash Document successfully updated!")
                    self.navigationController?.popViewController(animated: true)
                    let banner = StatusBarNotificationBanner(title: "Petty Cash Document Successfully updated", style: .success)
                    banner.show()
                }
            }
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
    
    func downloadFile(imageRef : String) {
        SVProgressHUD.show()
        let storageRef = Storage.storage().reference()
        // Create a reference to the file we want to download
        let imageRef = storageRef.child(imageRef)

        // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
        let downloadTask = imageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
          if let error = error {
            // Uh-oh, an error occurred!
            print(error)
          } else {
            // Data for "images/island.jpg" is returned
            let image = UIImage(data: data!)
            self.imageView.image = image
          }
        }

        // Observe changes in status
        downloadTask.observe(.resume) { snapshot in
          // Download resumed, also fires when the download starts
        }

        downloadTask.observe(.pause) { snapshot in
          // Download paused
        }

        downloadTask.observe(.progress) { snapshot in
          // Download reported progress
          let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
            / Double(snapshot.progress!.totalUnitCount)
            print(percentComplete)
            SVProgressHUD.showProgress(Float(percentComplete))
        }

        downloadTask.observe(.success) { snapshot in
          // Download completed successfully
            SVProgressHUD.dismiss()
        }

        // Errors only occur in the "Failure" case
        downloadTask.observe(.failure) { snapshot in
            guard let errorCode = (snapshot.error as NSError?)?.code else {
            return
          }
          guard let error = StorageErrorCode(rawValue: errorCode) else {
            return
          }
          switch (error) {
          case .objectNotFound:
            // File doesn't exist
            SVProgressHUD.dismiss()
            print("File doesn't exist")
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "File doesn't exist", message: "File Could not be found in Server", preferredStyle: .alert)
            
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)
            break
          case .unauthorized:
            SVProgressHUD.dismiss()
            // User doesn't have permission to access file
            print("User doesn't have permission to access file")
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Permission Error", message: "User doesn't have permission to access file", preferredStyle: .alert)
            
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)
            break
          case .cancelled:
            SVProgressHUD.dismiss()
            // User cancelled the download
            print("User cancelled the download")
            break

          /* ... */

          case .unknown:
            SVProgressHUD.dismiss()
            // Unknown error occurred, inspect the server response
            print("Unknown error occurred, inspect the server responsed")
            break
          default:
            SVProgressHUD.dismiss()
            // Another error occurred. This is a good place to retry the download.
            break
          }
        }
    }
    
    //Initialize Picker View
    // Number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categoryData.count
    }
    
    // The data to return fopr the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categoryData[row]
    }
    
    //This method is triggered whenever the user makes a change to the picker selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        categoryTextField.text = categoryData[row]
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if nominalTextField.text != "" {
            nominal = nominalTextField.text!
            //Format Nominal
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            let formattedNominal = numberFormatter.string(from: NSNumber(value:Int(nominalTextField.text!)!))
            nominalTextField.text = formattedNominal
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if nominalTextField.text != "" {
            nominalTextField.text = nominal
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
        
        nominalTextField.inputAccessoryView = doneToolbar
        
    }
    
    @objc func doneButtonAction(){
        nominalTextField.resignFirstResponder()
    }

}
