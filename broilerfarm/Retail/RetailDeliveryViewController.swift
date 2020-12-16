//
//  RetailDeliveryViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 4/24/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage
import SVProgressHUD
import NotificationBannerSwift
import Fusuma

class RetailDeliveryTableViewCell : UITableViewCell {
    //RetailDeliveryCell
    @IBOutlet var itemNameLabel: UILabel!
    @IBOutlet var itemDescriptionLabel: UILabel!
    @IBOutlet var itemQuantityLabel: UILabel!
    
}

class RetailDeliveryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, FusumaDelegate {
    
    var loginClass : String = ""
    var fullName : String = ""
    var purchaseOrder : RetailPurchaseOrder!

    @IBOutlet var contactNameLabel: UILabel!
    @IBOutlet var contactPhoneLabel: UILabel!
    @IBOutlet var addressTextView: UITextView!
    @IBOutlet var smsButton: UIButton!
    @IBOutlet var phoneButton: UIButton!
    @IBOutlet var whatsappButton: UIButton!
    @IBOutlet var googleMapsButton: UIButton!
    @IBOutlet var purchaseOrderNumberLabel: UILabel!
    
    @IBOutlet var bottomButton: UIButton!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var totalLabel: UILabel!
    @IBOutlet var deliveryImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        deliveryImageView.image = UIImage(systemName: "photo.fill")
        
        //Set Labels
        contactNameLabel.text = purchaseOrder.deliveryContactName
        contactPhoneLabel.text = "Phone: \( purchaseOrder.deliveryContactPhone)"
        addressTextView.text = purchaseOrder.deliveryAddress
        
        //Set Buttons
        smsButton.layer.cornerRadius = 0.5 * smsButton.bounds.width
        smsButton.layer.borderWidth = 1
        smsButton.layer.borderColor = UIColor.lightGray.cgColor
        
        phoneButton.layer.cornerRadius = 0.5 * phoneButton.bounds.width
        phoneButton.layer.borderWidth = 1
        phoneButton.layer.borderColor = UIColor.lightGray.cgColor
        
        whatsappButton.layer.cornerRadius = 0.5 * whatsappButton.bounds.width
        whatsappButton.layer.borderWidth = 1
        whatsappButton.layer.borderColor = UIColor.lightGray.cgColor
        
        googleMapsButton.layer.cornerRadius = 0.5 * googleMapsButton.bounds.width
        googleMapsButton.layer.borderWidth = 1
        googleMapsButton.layer.borderColor = UIColor.lightGray.cgColor
        
        purchaseOrderNumberLabel.text = purchaseOrder.purchaseOrderNumber
        
        if purchaseOrder.status == "Quality Checked" {
            bottomButton.setTitle(" Start Delivery", for: .normal)
            bottomButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        }
        else if purchaseOrder.status == "Delivery In Progress" {
            bottomButton.setTitle(" Finish Delivery", for: .normal)
            bottomButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        }
        
        self.tableView.reloadData()
        
        var subtotals : [Float] = [Float]()
        for i in 0..<purchaseOrder.realItems.count {
            let subtotal = Float(purchaseOrder.realItems[i].pricePerUnit) * purchaseOrder.realItemQuantities[i]
            subtotals.append(subtotal)
        }
        let total = subtotals.reduce(0,+) - Float(purchaseOrder.discount) - Float(purchaseOrder.deliveryFee)
        //Format Total
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let formattedTotal = numberFormatter.string(from: NSNumber(value: Int(total)))
        
        totalLabel.text = "Total: Rp. \(formattedTotal!) - \(purchaseOrder.paymentMethod)"
    }
    
    @IBAction func whatsappButtonPressed(_ sender: Any) {
        var phoneNumber = ""
        if ("0" == purchaseOrder.deliveryContactPhone.prefix(1)) {
            purchaseOrder.deliveryContactPhone.remove(at: purchaseOrder.deliveryContactPhone.startIndex)
            purchaseOrder.deliveryContactPhone = "62" + purchaseOrder.deliveryContactPhone
            phoneNumber = purchaseOrder.deliveryContactPhone
        }
        else {
            phoneNumber = purchaseOrder.deliveryContactPhone
        }

        let appURL = NSURL(string: "https://api.whatsapp.com/send?phone=\(phoneNumber.replacingOccurrences(of: "+", with: ""))")!
        if UIApplication.shared.canOpenURL(appURL as URL) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(appURL as URL, options: [:], completionHandler: nil)
            }
            else {
                UIApplication.shared.openURL(appURL as URL)
            }
        }
        else {
            let alert = UIAlertController(title: "Whatsapp not Installed!", message: "Please Install Whatsapp from the App Store", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    @IBAction func googlemapsButtonPressed(_ sender: Any) {
        func open(scheme: String) {
            if let url = URL(string: scheme) {
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url, options: [:],completionHandler: {(success) in
                        print("Open \(scheme): \(success)")
                    })
                } else {
                    let success = UIApplication.shared.openURL(url)
                    print("Open \(scheme): \(success)")
                }
            }
        }
        
        open(scheme: "comgooglemaps://?saddr=&daddr=\( purchaseOrder.deliveryLatitude),\(purchaseOrder.deliveryLongitude)&directionsmode=driving")
    }

    @IBAction func phoneButtonPressed(_ sender: Any) {
        var phoneNumber = ""
        if ("0" == purchaseOrder.deliveryContactPhone.prefix(1)) {
            purchaseOrder.deliveryContactPhone.remove(at: purchaseOrder.deliveryContactPhone.startIndex)
            purchaseOrder.deliveryContactPhone = "+62" + purchaseOrder.deliveryContactPhone
            phoneNumber = purchaseOrder.deliveryContactPhone
        }
        else {
            phoneNumber = purchaseOrder.deliveryContactPhone
        }
        guard let number = URL(string: "tel://" + phoneNumber) else { return }
        
        UIApplication.shared.open(number)
    }
    @IBAction func messageButtonPressed(_ sender: Any) {
        var phoneNumber = ""
        if ("0" == purchaseOrder.deliveryContactPhone.prefix(1)) {
            purchaseOrder.deliveryContactPhone.remove(at: purchaseOrder.deliveryContactPhone.startIndex)
            purchaseOrder.deliveryContactPhone = "+62" + purchaseOrder.deliveryContactPhone
            phoneNumber = purchaseOrder.deliveryContactPhone
        }
        else {
            phoneNumber = purchaseOrder.deliveryContactPhone
        }
        guard let message = URL(string: "sms://" + phoneNumber) else { return }
        
        UIApplication.shared.open(message)
    }
    @IBAction func bottomButtonPressed(_ sender: Any) {
        if purchaseOrder.status == "Quality Checked" {
            purchaseOrder.status = "Delivery In Progress"
            bottomButton.setTitle(" Finish Delivery", for: .normal)
            bottomButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
            updateDeliveryInProgressStatusPurchaseOrder(purchaseOrder: purchaseOrder)
        }
        else if purchaseOrder.status == "Delivery In Progress" {
            guard deliveryImageView.image != UIImage(systemName: "photo.fill") else {
                print("Delivery Image View Empty")
                let alert = UIAlertController(title: "Delivery Image Empty!", message: "Please add Delivery Image", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            updateDeliveredStatusPurchaseOrder(purchaseOrder: purchaseOrder)
        }
    }
    
    @IBAction func deliveryImageViewTapped(_ sender: Any) {
        launchImagePicker()
    }
    func updateDeliveryInProgressStatusPurchaseOrder (purchaseOrder : RetailPurchaseOrder) {
        print("Delivery In Progress Purchase Order")
        bottomButton.isEnabled = false
        let doc = Firestore.firestore().collection("retailPurchaseOrders").document(purchaseOrder.purchaseOrderNumber)
        doc.updateData([
            "status" : "Delivery In Progress"
        ]) { err in
            if let err = err {
                print("Error Updating product document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error writing Updating Purchase Order Document", style: .danger)
                banner.show()
                self.bottomButton.isEnabled = true
            } else {
                print("Purchase Order successfully Updated!")
                //Post Notification for finished purchase order creation
                let PurchaseOrderCreationNotification = Notification.Name("purchaseOrderCreated")
                NotificationCenter.default.post(name: PurchaseOrderCreationNotification, object: nil)
                let banner = StatusBarNotificationBanner(title: "Purchase Order Successfully Updated!", style: .success)
                banner.show()
                self.bottomButton.isEnabled = true
            }
        }
    }
    
    func updateDeliveredStatusPurchaseOrder (purchaseOrder : RetailPurchaseOrder) {
        print("Delivery In Progress Purchase Order")
        bottomButton.isEnabled = false
        let doc = Firestore.firestore().collection("retailPurchaseOrders").document(purchaseOrder.purchaseOrderNumber)
        doc.updateData([
            "status" : "Delivered",
            "deliveredBy" : fullName,
            "deliveryTimestamp" : NSDate().timeIntervalSince1970
        ]) { err in
            if let err = err {
                print("Error Updating product document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error Updating Purchase Order Document", style: .danger)
                banner.show()
                self.bottomButton.isEnabled = true
            } else {
                print("Purchase Order successfully Updated!")
                //Post Notification for finished purchase order creation
                let PurchaseOrderCreationNotification = Notification.Name("purchaseOrderCreated")
                NotificationCenter.default.post(name: PurchaseOrderCreationNotification, object: nil)
                let banner = StatusBarNotificationBanner(title: "Purchase Order Successfully Updated!", style: .success)
                banner.show()
                self.bottomButton.isEnabled = true
                
                //Send Telegram Message for PO Delivery
                let telegramText = "*ORDER DELIVERED*\n----------------------------\nPO Number: \(purchaseOrder.purchaseOrderNumber)\nName: \(purchaseOrder.name)\nAddress: \(purchaseOrder.address)\nDelivered To: \(purchaseOrder.deliveryContactName) - \(purchaseOrder.deliveryContactPhone)\nDelivered By: \(self.fullName)\n"
                
                Telegram().postTelegramMessage(botToken: Telegram().ChickenAppBotToken, chatID: Telegram().HeiHeiRetailChatID, text: telegramText, parse_mode: "Markdown")
                
                self.navigationController?.popViewController(animated: true)
            }
        }
        //Upload Delivery Image To Server
        uploadImagetoFirebaseStorage(imageRef: "RetailDeliveryImages/" + purchaseOrder.purchaseOrderNumber + ".jpeg")
    }
    
    func uploadImagetoFirebaseStorage(imageRef : String) {
        //Upload to Firebase Storage
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child(imageRef)
        // Create the file metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Upload file and metadata to the object
        let jpegData = deliveryImageView.image!.jpegData(compressionQuality: 0.0)!
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
    
    //MARK: Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return purchaseOrder.realItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        func createItemsCell(data : RetailProduct, quantity: Float) -> RetailDeliveryTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RetailDeliveryCell", for: indexPath) as! RetailDeliveryTableViewCell
            
            cell.itemNameLabel.text = data.name
            cell.itemDescriptionLabel.text = data.description
            cell.itemQuantityLabel.text = "Qty: \(String(format: "%.2f", quantity)) \(data.unit)"
            return cell
        }
        
        return createItemsCell(data: purchaseOrder.realItems[indexPath.row], quantity: purchaseOrder.realItemQuantities[indexPath.row])
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
        deliveryImageView.image = image
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

}
