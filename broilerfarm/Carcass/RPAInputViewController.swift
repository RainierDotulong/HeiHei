//
//  RPAInputViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 6/23/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import SVProgressHUD
import Firebase
import FirebaseFirestore
import FirebaseStorage
import NotificationBannerSwift
import TextFieldEffects
import Fusuma

class RPAInputViewController: UIViewController, sendPlaceData, FusumaDelegate, UITextFieldDelegate {
    
    var fullName : String = ""
    var loginClass : String = ""
    var rpaNames : [String] = [String]()
    var edit = false
    var selectedRpa : RPA = RPA(name: "", address: "", latitude: 0, longitude: 0, noNkv: "", perhitunganBiaya: "", referencePrice: 0, paymentTerm: "", sideProduct: false, contactPerson: "", contactPhone: "", bank: "", bankName: "", bankNumber: "", createdBy: "", timestamp: 0)
    
    var sideProduct : Bool = true
    var perhitunganBiaya : String = "Total Terima RPA"
    var paymentTerm : String = "Cash on Delivery"

    @IBOutlet var nameTextField: AkiraTextField!
    @IBOutlet var addressTextField: AkiraTextField!
    @IBOutlet var nomorNkvTextField: AkiraTextField!
    @IBOutlet var namaKontakTextField: AkiraTextField!
    @IBOutlet var noTelpKontakTextField: AkiraTextField!
    @IBOutlet var bankTextField: AkiraTextField!
    @IBOutlet var bankNameTextField: AkiraTextField!
    @IBOutlet var noRekTextField: AkiraTextField!
    @IBOutlet var referensiHargaTextField: AkiraTextField!
    @IBOutlet var latitudeLabel: UILabel!
    @IBOutlet var longitudeLabel: UILabel!
    @IBOutlet var sideProductButton: UIButton!
    @IBOutlet var perhitunganBiayaButton: UIButton!
    @IBOutlet var paymentTermButton: UIButton!
    @IBOutlet var halalCertificateImageView: UIImageView!
    @IBOutlet var finishButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        //Done Button on keyboard
        addDoneButtonOnKeyboard()
        
        if edit {
            nameTextField.isUserInteractionEnabled = false
            nameTextField.text = selectedRpa.name
            addressTextField.text = selectedRpa.address
            nomorNkvTextField.text = selectedRpa.noNkv
            namaKontakTextField.text = selectedRpa.contactPerson
            noTelpKontakTextField.text = selectedRpa.contactPhone
            bankTextField.text = selectedRpa.bank
            bankNameTextField.text = selectedRpa.bankName
            noRekTextField.text = selectedRpa.bankNumber
            referensiHargaTextField.text = "\(selectedRpa.referencePrice)"
            latitudeLabel.text = String(selectedRpa.latitude)
            longitudeLabel.text = String(selectedRpa.longitude)
            if selectedRpa.sideProduct {
                sideProductButton.setTitle("Ikut Kita", for: .normal)
            }
            else {
                sideProductButton.setTitle("Ikut RPA", for: .normal)
            }
            perhitunganBiayaButton.setTitle(selectedRpa.perhitunganBiaya, for: .normal)
            paymentTermButton.setTitle(selectedRpa.paymentTerm, for: .normal)
            //MARK: TODO: Halal Certificate Download
            
            finishButton.setTitle("Update", for: .normal)
        }
        else {
            //Set Placeholder Image
            halalCertificateImageView.image = UIImage(systemName: "photo.fill")
        }
    }
    
    func placeDataReceived(address: String, latitude: String, longitude: String) {
        self.latitudeLabel.text = latitude
        self.longitudeLabel.text = longitude
    }
    
    @IBAction func locationButtonPressed(_ sender: Any) {
        print("Location")
        self.performSegue(withIdentifier: "goToGoogleMaps", sender: self)
    }
    @IBAction func sideProductButtonPressed(_ sender: Any) {
        print("Side Product")
        let dialogMessage = UIAlertController(title: "Side Product", message: "", preferredStyle: .alert)
        
        let ikutKita = UIAlertAction(title: "Ikut Kita", style: .default, handler: { (action) -> Void in
            self.sideProduct = true
            self.sideProductButton.setTitle("Ikut Kita", for: .normal)
        })
        let ikutRPA = UIAlertAction(title: "Ikut RPA", style: .default, handler: { (action) -> Void in
            self.sideProduct = false
            self.sideProductButton.setTitle("Ikut RPA", for: .normal)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: { (action) -> Void in
            print("Cancel button tapped")
        })
        
        dialogMessage.addAction(ikutKita)
        dialogMessage.addAction(ikutRPA)
        dialogMessage.addAction(cancel)
        
        self.present(dialogMessage, animated: true, completion: nil)
    }
    @IBAction func perhitunganBiayaButtonPressed(_ sender: Any) {
        print("Perhitungan Biaya")
        let dialogMessage = UIAlertController(title: "Perhitungan Biaya", message: "", preferredStyle: .alert)
        
        let totalTerimaRPA = UIAlertAction(title: "Total Terima RPA", style: .default, handler: { (action) -> Void in
            self.perhitunganBiaya = "Total Terima RPA"
            self.perhitunganBiayaButton.setTitle("Total Terima RPA", for: .normal)
        })
        let karkasDiterima = UIAlertAction(title: "Karkas Diterima", style: .default, handler: { (action) -> Void in
            self.perhitunganBiaya = "Karkas Diterima"
            self.perhitunganBiayaButton.setTitle("Karkas Diterima", for: .normal)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: { (action) -> Void in
            print("Cancel button tapped")
        })
        
        dialogMessage.addAction(totalTerimaRPA)
        dialogMessage.addAction(karkasDiterima)
        dialogMessage.addAction(cancel)
        
        self.present(dialogMessage, animated: true, completion: nil)
    }
    @IBAction func paymentTermButtonPressed(_ sender: Any) {
        print("Payment Term")
        let dialogMessage = UIAlertController(title: "Payment Term", message: "", preferredStyle: .alert)
        
        let termin = UIAlertAction(title: "Termin", style: .default, handler: { (action) -> Void in
            self.paymentTerm = "Termin"
            self.paymentTermButton.setTitle("Termin", for: .normal)
        })
        
        let cod = UIAlertAction(title: "Cash on Delivery", style: .default, handler: { (action) -> Void in
            self.paymentTerm = "Cash on Delivery"
            self.paymentTermButton.setTitle("Cash on Delivery", for: .normal)
        })
        let cbd = UIAlertAction(title: "Cash Before Delivery", style: .default, handler: { (action) -> Void in
            self.paymentTerm = "Cash Before Delivery"
            self.paymentTermButton.setTitle("Cash Before Delivery", for: .normal)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: { (action) -> Void in
            print("Cancel button tapped")
        })
        
        dialogMessage.addAction(termin)
        dialogMessage.addAction(cod)
        dialogMessage.addAction(cbd)
        dialogMessage.addAction(cancel)
        
        self.present(dialogMessage, animated: true, completion: nil)
    }
    
    @IBAction func halalCertificateImageViewTapped(_ sender: Any) {
        print("Halal Certificate Image View Tapped")
        launchImagePicker()
    }
    
    @IBAction func finishButtonPressed(_ sender: Any) {
        //Check for data completion
        guard nameTextField.text != "" else {
            let dialogMessage = UIAlertController(title: "Name Text Field Empty", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        if edit == false {
            guard rpaNames.contains(nameTextField.text!) == false else {
                let dialogMessage = UIAlertController(title: "RPA Already Exists", message: "", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
        }
        guard addressTextField.text != "" else {
            let dialogMessage = UIAlertController(title: "Address Text Field Empty", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard nomorNkvTextField.text != "" else {
            let dialogMessage = UIAlertController(title: "Nomor NKV Text Field Empty", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard namaKontakTextField.text != "" else {
            let dialogMessage = UIAlertController(title: "Nama Kontak Text Field Empty", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard noTelpKontakTextField.text != "" else {
            let dialogMessage = UIAlertController(title: "No Telp Kontak Text Field Empty", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard bankTextField.text != "" else {
            let dialogMessage = UIAlertController(title: "Bank Text Field Empty", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard bankNameTextField.text != "" else {
            let dialogMessage = UIAlertController(title: "Bank Name Text Field Empty", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard noRekTextField.text != "" else {
            let dialogMessage = UIAlertController(title: "Nomor Rekening Text Field Empty", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard Int(noRekTextField.text ?? "0") ?? 0 != 0 else {
            let dialogMessage = UIAlertController(title: "Referensi Harga Invalid", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard latitudeLabel.text != "Latitude" && longitudeLabel.text != "Longitude" else {
            let dialogMessage = UIAlertController(title: "Coordinates Missing!", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard halalCertificateImageView.image != UIImage(systemName: "photo.fill") else {
            let dialogMessage = UIAlertController(title: "Halal Certificate Photo Missing!", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        //MARK: Create RPA Document
        createRPA(name: nameTextField.text!, address: addressTextField.text!, latitude: Double(latitudeLabel.text!)!, longitude: Double(longitudeLabel.text!)!, noNkv: nomorNkvTextField.text! , perhitunganBiaya: perhitunganBiaya, referencePrice: Int(referensiHargaTextField.text!)!, sideProduct: sideProduct, contactPerson: namaKontakTextField.text!, contactPhone: noTelpKontakTextField.text!, bank: bankTextField.text!, bankNumber: noRekTextField.text!, bankName: bankNameTextField.text!, paymentTerm: paymentTerm, createdBy: fullName)
        
        //MARK: Upload Halal certificate
        if edit == false {
            uploadImagetoFirebaseStorage(imageRef: "rpaHalalCertificates/" + nameTextField.text!.replacingOccurrences(of: " ", with: "-") + ".jpeg")
        }
    }
    
    func createRPA(name : String, address : String, latitude : Double, longitude: Double, noNkv : String, perhitunganBiaya : String, referencePrice : Int, sideProduct : Bool, contactPerson : String, contactPhone : String, bank : String, bankNumber : String, bankName : String, paymentTerm : String, createdBy : String) {
        finishButton.isEnabled = false
        let doc = Firestore.firestore().collection("rpa").document(name)
        doc.setData([
            "name" : name,
            "address" : address,
            "latitude" : latitude,
            "longitude" : longitude,
            "noNkv" : noNkv,
            "perhitunganBiaya" : perhitunganBiaya,
            "referencePrice" : referencePrice,
            "sideProduct" : sideProduct,
            "contactPerson" : contactPerson,
            "contactPhone" : contactPhone,
            "bank" : bank,
            "bankNumber" : bankNumber,
            "bankName" : bankName,
            "paymentTerm" : paymentTerm,
            "createdBy" : createdBy,
            "timestamp" : NSDate().timeIntervalSince1970
        ]) { err in
            if let err = err {
                print("Error writing new RPA document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error writing New RPA Document", style: .danger)
                banner.show()
                self.finishButton.isEnabled = true
            } else {
                print("RPA successfully Created!")
                let RPACreationNotification = Notification.Name("rpaCreated")
                NotificationCenter.default.post(name: RPACreationNotification, object: nil)
                let banner = StatusBarNotificationBanner(title: "RPA successfully Created!", style: .success)
                banner.show()
                self.finishButton.isEnabled = true
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
        let jpegData = halalCertificateImageView.image!.jpegData(compressionQuality: 0.0)!
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
        halalCertificateImageView.image = image
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
    
    //Add Done Button on Keyboard
    func addDoneButtonOnKeyboard(){
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))
        
        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        nameTextField.inputAccessoryView = doneToolbar
        addressTextField.inputAccessoryView = doneToolbar
        nomorNkvTextField.inputAccessoryView = doneToolbar
        namaKontakTextField.inputAccessoryView = doneToolbar
        noTelpKontakTextField.inputAccessoryView = doneToolbar
        bankTextField.inputAccessoryView = doneToolbar
        bankNameTextField.inputAccessoryView = doneToolbar
        noRekTextField.inputAccessoryView = doneToolbar
        referensiHargaTextField.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction(){
        nameTextField.resignFirstResponder()
        addressTextField.resignFirstResponder()
        nomorNkvTextField.resignFirstResponder()
        namaKontakTextField.resignFirstResponder()
        noTelpKontakTextField.resignFirstResponder()
        bankTextField.resignFirstResponder()
        bankNameTextField.resignFirstResponder()
        noRekTextField.resignFirstResponder()
        referensiHargaTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        nameTextField.resignFirstResponder()
        addressTextField.resignFirstResponder()
        nomorNkvTextField.resignFirstResponder()
        namaKontakTextField.resignFirstResponder()
        noTelpKontakTextField.resignFirstResponder()
        bankTextField.resignFirstResponder()
        bankNameTextField.resignFirstResponder()
        noRekTextField.resignFirstResponder()
        referensiHargaTextField.resignFirstResponder()
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is GoogleMapsViewController
        {
            let vc = segue.destination as? GoogleMapsViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.previousMenu = "RPA"
            vc?.delegate = self
        }
    }
}
