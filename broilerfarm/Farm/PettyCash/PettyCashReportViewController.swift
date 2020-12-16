//
//  PettyCashReportViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 11/13/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage
import SVProgressHUD
import NotificationBannerSwift
import TextFieldEffects
import Fusuma

class PettyCashReportViewController: UIViewController, UITextFieldDelegate, FusumaDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var farmName : String = ""
    var fullName : String = ""
    var loginClass : String = ""
    var cycleNumber : Int = 0
    var action : String  = ""
    
    var nominal : String = ""
    var timestamp : String = ""
    var categoryData : [String] = [String]()

    
    @IBOutlet var nominalTextField: AkiraTextField!
    @IBOutlet var categoryTextField: AkiraTextField!
    @IBOutlet var navItem: UINavigationItem!
    @IBOutlet var pickerView: UIPickerView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var finishButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        switch action{
        case "Cash In":
            navItem.title = "Top Up Petty Cash"
            imageView.isUserInteractionEnabled = true
            categoryData = ["Cash", "Transfer"]
        case "Cash Out":
            navItem.title = "Lapor Pemakaian"
            imageView.isUserInteractionEnabled = true
            categoryData = ["Bongkar kristal","Humas bulanan","Indomie","Makan borongan panen","Makan borongan bongkar","Operasional kandang","Tabur sekam","Uang makan","Lain-lain"]
        default:
            navItem.title = "DEFAULT"
        }
        
        addDoneButtonOnKeyboard()

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    @IBAction func imageViewTapped(_ sender: Any) {
        launchImagePicker()
    }
    
    @IBAction func finishButtonPressed(_ sender: Any) {
        timestamp = String(NSDate().timeIntervalSince1970)
        switch action{
        case "Cash In":
            if nominal != "" && imageView.image != nil && categoryTextField.text != "" {
                print("UPLOAD CASH IN REPORT")
                uploadDataToServer(collection: "\(farmName)\(cycleNumber)PettyCash", nominal: nominal, category : categoryTextField.text!, action: action, timestamp: timestamp, reporterName: fullName, checked: "true")
                uploadImagetoFirebaseStorage(imageRef: "\(farmName)\(cycleNumber)PettyCashInImages/" + timestamp + ".jpeg")
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
        case "Cash Out":
            if nominal != "" && imageView.image != nil && categoryTextField.text != "" {
                print("UPLOAD CASH OUT REPORT")
                uploadDataToServer(collection: "\(farmName)\(cycleNumber)PettyCash", nominal: nominal, category : categoryTextField.text!, action: action, timestamp: timestamp, reporterName: fullName, checked: "false")
                uploadImagetoFirebaseStorage(imageRef: "\(farmName)\(cycleNumber)PettyCashOutImages/" + timestamp + ".jpeg")
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
        default:
            navItem.title = "DEFAULT"
        }
    }
    
    func uploadDataToServer(collection : String, nominal : String, category : String, action : String, timestamp : String, reporterName : String, checked : String) {
        finishButton.isEnabled = false
        SVProgressHUD.show()
        let doc = Firestore.firestore().collection(collection).document(timestamp)
        doc.setData([
            "nominal" : nominal,
            "action" : action,
            "category" : category,
            "checked" : checked,
            "reporterName" : reporterName
            
        ]) { err in
            if let err = err {
                print("Error writing Petty Cash Document: \(err)")
                self.finishButton.isEnabled = true
                SVProgressHUD.dismiss()
                let banner = StatusBarNotificationBanner(title: "Error writing Petty Cash Document", style: .danger)
                banner.show()
            } else {
                print("Petty Cash Document successfully written!")
                self.finishButton.isEnabled = true
                SVProgressHUD.dismiss()
                let banner = StatusBarNotificationBanner(title: "Petty Cash Document Successfully Written", style: .success)
                banner.show()
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func uploadImagetoFirebaseStorage(imageRef : String) {
        //Upload to Firebase Storage
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child(imageRef)
        // Create the file metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Upload file and metadata to the object
        let jpegData = imageView.image!.jpegData(compressionQuality: 0.0)!
        let uploadTask = imageRef.putData(jpegData, metadata: metadata)
        // Listen for state changes, errors, and completion of the upload.
        uploadTask.observe(.resume) { snapshot in
          // Upload resumed, also fires when the upload starts
        }
        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error as NSError? {
            switch (StorageErrorCode(rawValue: error.code)!) {
            case .objectNotFound:
              // File doesn't exist
                //Declare Alert message
                let dialogMessage = UIAlertController(title: "Error in Uploading Image", message: "File does not exist", preferredStyle: .alert)
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
              // User doesn't have permission to access file
                //Declare Alert message
                let dialogMessage = UIAlertController(title: "Error in Uploading ImageF", message: "User doesn't have permission to access file", preferredStyle: .alert)
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
              // User canceled the upload
                //Declare Alert message
                let dialogMessage = UIAlertController(title: "Error in Uploading Image", message: "User canceled the upload", preferredStyle: .alert)
                // Create OK button with action handler
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                //Add OK and Cancel button to dialog message
                dialogMessage.addAction(ok)
                // Present dialog message to user
                self.present(dialogMessage, animated: true, completion: nil)
              break
            case .unknown:
              // Unknown error occurred, inspect the server response
                //Declare Alert message
                let dialogMessage = UIAlertController(title: "Error in Uploading Image", message: "Unknown error occurred, inspect the server response", preferredStyle: .alert)
                // Create OK button with action handler
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                //Add OK and Cancel button to dialog message
                dialogMessage.addAction(ok)
                // Present dialog message to user
                self.present(dialogMessage, animated: true, completion: nil)
              break
            default:
              // A separate error occurred. This is a good place to retry the upload.
                imageRef.putData(jpegData, metadata: metadata)
              break
            }
          }
        }
        uploadTask.observe(.success) { snapshot in
          // Upload completed successfully
            print("Image Upload completed successfully")
        }
    }
    
    func launchImagePicker() {
        let fusuma = FusumaViewController()
        fusuma.modalPresentationStyle = .overFullScreen
        fusuma.delegate = self
        fusuma.availableModes = [FusumaMode.library, FusumaMode.camera]
        fusuma.allowMultipleSelection = false
        fusumaCameraTitle = "Camera"
        //fusumaCropImage = false
        //fusumaSavesImage = true
        self.present(fusuma, animated: true, completion: nil)
    }
    
    //FusumaDelegate Protocols
    func fusumaImageSelected(_ image: UIImage, source: FusumaMode) {
        switch source {
        case .camera:
            print("Image captured from Camera")
        case .library:
            print("Image selected from Camera Roll")
        default:
            print("Image selected")
        }
        
        imageView.image = image
    }
    
    func fusumaImageSelected(_ image: UIImage, source: FusumaMode, metaData: ImageMetadata) {
        //        print("Image mediatype: \(metaData.mediaType)")
        //        print("Source image size: \(metaData.pixelWidth)x\(metaData.pixelHeight)")
        //        print("Creation date: \(String(describing: metaData.creationDate))")
        //        print("Modification date: \(String(describing: metaData.modificationDate))")
        //        print("Video duration: \(metaData.duration)")
        //        print("Is favourite: \(metaData.isFavourite)")
        //        print("Is hidden: \(metaData.isHidden)")
        //        print("Location: \(String(describing: metaData.location))")
        
        guard let creationDate = metaData.creationDate else {
            print("Creation Date Metadata Empty")
            return
        }
        
        let currentDate = Date()
        let components = Calendar.current.dateComponents([.hour], from: creationDate, to: currentDate)
        
        let hourDifference = components.hour!
        
        if hourDifference > 3 {
            
            print("photo > 3 hours")
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Recent Picture Required", message: "Please select a recent picture (<3 hours).", preferredStyle: .alert)
            
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)
            
            imageView.image = UIImage(named: "redLogo")
        }
    }
    
    func fusumaMultipleImageSelected(_ images: [UIImage], source: FusumaMode) {
        print("Number of selection images: \(images.count)")
    }
    
    func fusumaVideoCompleted(withFileURL fileURL: URL) {
        print("video completed and output to file: \(fileURL)")
    }
    
    func fusumaCameraRollUnauthorized() {
        print("Camera roll unauthorized")
        
        let alert = UIAlertController(title: "Access Requested",
                                      message: "Saving image needs to access your photo album",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { (action) -> Void in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
                
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
        })
        
        guard let vc = UIApplication.shared.delegate?.window??.rootViewController, let presented = vc.presentedViewController else {
            return
        }
        
        presented.present(alert, animated: true, completion: nil)
    }
    
    func fusumaClosed() {
        print("Called when the FusumaViewController disappeared")
    }
    //Called when the close button is pressed
    func fusumaWillClosed() {
        //Set back to portrait mode
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
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
