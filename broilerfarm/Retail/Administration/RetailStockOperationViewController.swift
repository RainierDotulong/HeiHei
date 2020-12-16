//
//  RetailStockOperationViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 5/23/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage
import SVProgressHUD
import NotificationBannerSwift
import Fusuma

class RetailStockOperationViewController: UIViewController,sendProductData, UITextFieldDelegate, FusumaDelegate {
    
    var fullName : String = ""
    var loginClass : String = ""
    var add : Bool = false
    
    var notes : String = ""
    
    @IBOutlet var navItem: UINavigationItem!
    @IBOutlet var productNameLabel: UILabel!
    @IBOutlet var productUnitLabel: UILabel!
    @IBOutlet var quantityTextField: UITextField!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var notesButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Add Done Button on keboard
        addDoneButtonOnKeyboard()
        
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        if add {
            navItem.title = "Stock Addition"
        }
        else {
            navItem.title = "Stock Extraction"
        }
        
        imageView.image = UIImage(systemName: "camera")
    }
    
    @IBAction func productViewTapped(_ sender: Any) {
        print("Product View Tapped")
        self.performSegue(withIdentifier: "goToProducts", sender: self)
    }
    
    func productDataReceived(product: RetailProduct) {
        productNameLabel.text = product.name
        productUnitLabel.text = product.unit
    }
    
    @IBAction func imageViewTapped(_ sender: Any) {
        print("Image View Tapped")
        launchImagePicker()
    }
    
    @IBAction func notesButtonPressed(_ sender: Any) {
        print("Notes Button Pressed")
        let alert = UIAlertController(title: "Notes", message: "", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Notes"
            textField.keyboardType = .default
            textField.autocapitalizationType = .words
        }
        
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            let textField = alert.textFields![0]
            guard textField.text ?? "" != "" else {
                print("Incomplete Data")
                let dialogMessage = UIAlertController(title: "Incomplete Data", message: "Text Field Empty", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            self.notes = textField.text ?? ""
            self.notesButton.setTitle("Note: \(textField.text ?? "")", for: .normal)
            self.notesButton.setTitleColor(UIColor.black, for: .normal)
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            print("Cancel button tapped")
        }
        
        alert.addAction(ok)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func finishButtonPressed(_ sender: Any) {
        print("Finish")
        guard Float(quantityTextField.text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0 != 0 else {
            let dialogMessage = UIAlertController(title: "Invalid Quantity!", message: "Quantity is non-numerical or Empty", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard productNameLabel.text != "Product Name" else {
            print("Product Name Unspecified")
            let dialogMessage = UIAlertController(title: "Product Name Unspecified!", message: "Please select Product.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard imageView.image != UIImage(systemName: "camera") else {
            print("Image Missing")
            let dialogMessage = UIAlertController(title: "Image Missing", message: "Tap Camera Icon to add Image.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        //Check for Stock Document Existance
        var currentQuantity : Float = 0
        let cycle = Firestore.firestore().collection("retailStock").document(productNameLabel.text!)
        
        cycle.getDocument { (document, error) in
            if let document = document, document.exists {
                print("Stock Document exists")
                currentQuantity = document.data()!["quantity"] as! Float
                //Increment/Decrement Stock Document
                var newQuantity : Float = 0
                if self.add {
                    newQuantity = currentQuantity + Float(self.quantityTextField.text!.replacingOccurrences(of: ",", with: "."))!
                }
                else {
                    newQuantity = currentQuantity - Float(self.quantityTextField.text!.replacingOccurrences(of: ",", with: "."))!
                }
                self.updateStock(productName: self.productNameLabel.text!, quantity: newQuantity)
                
            } else {
                print("Stock Document does not exist")
                currentQuantity = 0
                self.createNewStock(productName: self.productNameLabel.text!, quantity: Float(self.quantityTextField.text!.replacingOccurrences(of: ",", with: "."))!, unit: self.productUnitLabel.text!)
            }
        }
        
        //Create Stock Operation Document
        let docID = createStockOperation(add: add, productName: productNameLabel.text!, quantity: Float(quantityTextField.text!.replacingOccurrences(of: ",", with: "."))!, unit: productUnitLabel.text!, notes: notes)
        
        //Upload Image with document name reference
        uploadImagetoFirebaseStorage(imageRef: "RetailStockOperationImages/" + docID + ".jpeg")
        
        self.navigationController?.popViewController(animated: true)
    }
    
    func updateStock(productName : String, quantity : Float) {
        let doc = Firestore.firestore().collection("retailStock").document(productName)
        doc.updateData([
            "quantity" : quantity,
            "createdBy" : fullName,
            "timestamp" : NSDate().timeIntervalSince1970
        ]) { err in
            if let err = err {
                print("Error updating stock: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error Performing Stock Update", style: .danger)
                banner.show()
            } else {
                print("Stock successfully Updated!")
                let RetailStockChangeNotification = Notification.Name("retailStockChanged")
                NotificationCenter.default.post(name: RetailStockChangeNotification, object: nil)
            }
        }
    }
    
    func createNewStock(productName : String, quantity : Float, unit : String) {
        let doc = Firestore.firestore().collection("retailStock").document(productName)
        doc.setData([
            "quantity" : quantity,
            "unit" : unit,
            "createdBy" : fullName,
            "timestamp" : NSDate().timeIntervalSince1970
        ]) { err in
            if let err = err {
                print("Error writing new stock document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error Performing Stock Creation", style: .danger)
                banner.show()
            } else {
                print("Stock Document successfully Created!")
                let RetailStockChangeNotification = Notification.Name("retailStockChanged")
                NotificationCenter.default.post(name: RetailStockChangeNotification, object: nil)
            }
        }
    }
    
    func createStockOperation(add : Bool, productName : String, quantity : Float, unit : String, notes : String) -> String{
        let doc = Firestore.firestore().collection("retailStockOperations").document()
        doc.setData([
            "add" : add,
            "isCancelled" : false,
            "isAutomaticallyGenerated" : false,
            "productName" : productName,
            "quantity" : quantity,
            "unit" : unit,
            "notes" : notes,
            "createdBy" : fullName,
            "timestamp" : NSDate().timeIntervalSince1970
        ]) { err in
            if let err = err {
                print("Error writing new product document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error Performing Operation", style: .danger)
                banner.show()
            } else {
                print("Stock Operation Document successfully Created!")
            }
        }
        return doc.documentID
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
    
    //MARK: - Fusuma
    func launchImagePicker() {
        let fusuma = FusumaViewController()
        fusuma.modalPresentationStyle = .overFullScreen
        fusuma.delegate = self
        fusuma.availableModes = [FusumaMode.library, FusumaMode.camera]
        fusuma.allowMultipleSelection = false
        fusumaCameraTitle = "Camera"
        fusuma.title = "Delivery Photo"
        //fusumaCropImage = false
        fusumaSavesImage = true
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
        
        guard let creationDate = metaData.creationDate else {
            print("Creation Date Metadata Empty")
            return
        }
        
        let currentDate = Date()
        let components = Calendar.current.dateComponents([.hour], from: creationDate, to: currentDate)
        
        let hourDifference = components.hour!
        
        if hourDifference > 1 {
            print("photo > 1 hours")
            imageView.image = UIImage(systemName: "camera")
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
    
    //Add Done Button on Keyboard
    func addDoneButtonOnKeyboard(){
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))
        
        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        quantityTextField.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction(){
        quantityTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        quantityTextField.resignFirstResponder()
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is RetailProductsTableViewController
        {
            let vc = segue.destination as? RetailProductsTableViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.previousMenu = "Stock Operation"
            vc?.delegate = self
        }
    }
}
