//
//  InputRPAViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 6/26/20.
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

class InputRPAViewController: UIViewController, FusumaDelegate, UITextFieldDelegate {
    
    var fullName : String = ""
    var loginClass : String = ""
    var selectedData : CarcassProduction = CarcassProduction(hargaBeliAyam: 0, transportName: "", transportBank: "", transportBankNumber: "", transportBankName: "", transportPaymentTerm: "", amountDueForTransport: 0, licensePlateNumber: "", sourceFarm: "", escort: "", transportedWeight: 0, transportedQuantity: 0, transportCreatedBy: "", transportCreatedTimestamp: 0, rpaName: "", rpaAddress: "", rpaLatitude: 0, rpaLongitude: 0, rpaNoNkv: "", rpaPerhitunganBiaya: "", rpaPaymentTerm: "", rpaSideProduct: false, rpaContactPerson: "", rpaContactPhone: "", rpaBank: "", rpaBankName: "", rpaBankNumber: "", slaughterTimestamp: 0, typeOfWork: "", receivedWeight: 0, receivedQuantity: 0, receivedDeadWeight: 0, receivedDeadQuantity: 0, rpaInputCreatedBy: "", rpaInputCreatedTimestamp: 0, yieldedWeight: 0, yieldedProductNames: [String](), yieldedProductUnits: [String](), yieldedProductQuantities: [Float](), initialStorageProvider: "", rpaOutputCreatedBy: "", rpaOutputCreatedTimestamp: 0, rpaHargaPerKG: 0)
    var edit : Bool = false
    
    @IBOutlet var totalKGTerimaTextField: AkiraTextField!
    @IBOutlet var totalKGMatiTextField: AkiraTextField!
    @IBOutlet var jumlahEkorTerimaTextField: AkiraTextField!
    @IBOutlet var jumlahEkorMatiTextField: AkiraTextField!
    @IBOutlet var jamPotongButton: UIButton!
    @IBOutlet var jenisPekerjaanButton: UIButton!
    @IBOutlet var finishButton: UIButton!
    @IBOutlet var tandaTerimaImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        //Add Done Button on Keyboard
        addDoneButtonOnKeyboard()
        
        if edit {
            totalKGTerimaTextField.text = "\(selectedData.receivedWeight)"
            totalKGMatiTextField.text = "\(selectedData.receivedDeadWeight)"
            jumlahEkorTerimaTextField.text = "\(selectedData.receivedQuantity)"
            jumlahEkorMatiTextField.text = "\(selectedData.receivedDeadQuantity)"
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: Date(timeIntervalSince1970: selectedData.slaughterTimestamp))
            jamPotongButton.setTitle(" Jam Potong: \(stringDate)", for: .normal)
            jamPotongButton.setTitleColor(.black, for: .normal)
            jamPotongButton.tintColor = .black
            jenisPekerjaanButton.setTitle(" Jenis Pekerjaan: \(selectedData.typeOfWork.capitalized)", for: .normal)
            jenisPekerjaanButton.setTitleColor(.black, for: .normal)
            jenisPekerjaanButton.tintColor = .black
            downloadImage(imageRef: "rpaInputReceipts/" + selectedData.id! + ".jpeg")
        }
    }
    @IBAction func jamPotongButtonPressed(_ sender: Any) {
        print("Jam Potong Button Pressed")
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        
        let alert = UIAlertController(title: "\n\n\n\n\n\n\n\n\n\n\n", message: nil, preferredStyle: .actionSheet)
        alert.view.addSubview(datePicker)
        
        datePicker.snp.makeConstraints { (make) in
            make.centerX.equalTo(alert.view)
            make.top.equalTo(alert.view).offset(8)
        }
        
        let ok = UIAlertAction(title: "OK", style: .default) { (action) in
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: datePicker.date)
            self.selectedData.slaughterTimestamp = datePicker.date.timeIntervalSince1970
            self.jamPotongButton.setTitle(" Jam Potong: \(stringDate)", for: .normal)
            self.jamPotongButton.setTitleColor(.black, for: .normal)
            self.jamPotongButton.tintColor = .black
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        alert.addAction(ok)
        alert.addAction(cancel)
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
        alert.popoverPresentationController?.permittedArrowDirections = []
        present(alert, animated: true, completion: nil)
    }
    @IBAction func jenisPekerjaanButtonPressed(_ sender: Any) {
        print("Jenis Pekerjaan Button Pressed")
        let dialogMessage = UIAlertController(title: "Work Type", message: "", preferredStyle: .alert)
        
        let regular = UIAlertAction(title: "Regular", style: .default, handler: { (action) -> Void in
            self.selectedData.typeOfWork = "regular"
            self.jenisPekerjaanButton.setTitle(" Jenis Pekerjaan: Regular", for: .normal)
            self.jenisPekerjaanButton.setTitleColor(.black, for: .normal)
            self.jenisPekerjaanButton.tintColor = .black
        })
        let boneless = UIAlertAction(title: "Boneless", style: .default, handler: { (action) -> Void in
            self.selectedData.typeOfWork = "boneless"
            self.jenisPekerjaanButton.setTitle(" Jenis Pekerjaan: Boneless", for: .normal)
            self.jenisPekerjaanButton.setTitleColor(.black, for: .normal)
            self.jenisPekerjaanButton.tintColor = .black
        })

        dialogMessage.addAction(regular)
        dialogMessage.addAction(boneless)
        
        self.present(dialogMessage, animated: true, completion: nil)
    }
    @IBAction func imageViewTapped(_ sender: Any) {
        print("Image View tapped")
        launchImagePicker()
    }
    
    @IBAction func finishButtonPressed(_ sender: Any) {
        guard Float(totalKGTerimaTextField.text ?? "") ?? 0 != 0 else {
            let dialogMessage = UIAlertController(title: "Total KG Terima Text Field Invalid", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard Float(totalKGMatiTextField.text ?? "") ?? 9999 != 9999 else {
            let dialogMessage = UIAlertController(title: "Total KG Mati Text Field Invalid", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard Int(jumlahEkorTerimaTextField.text ?? "") ?? 0 != 0 else {
            let dialogMessage = UIAlertController(title: "Jumlah Ekor Terima Text Field Invalid", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard Int(jumlahEkorMatiTextField.text ?? "") ?? 9999 != 9999 else {
            let dialogMessage = UIAlertController(title: "Jumlah Ekor Mati Text Field Invalid", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard selectedData.slaughterTimestamp != 0 else {
            let dialogMessage = UIAlertController(title: "Jam Potong Unspecified", message: "Please Specify Slaughter Timestamp", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard selectedData.typeOfWork != "" else {
            let dialogMessage = UIAlertController(title: "Jenis Pekerjaan Empty", message: "Please Specify Type of Work", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        selectedData.receivedWeight = Float(totalKGTerimaTextField.text!)!
        selectedData.receivedQuantity = Int(jumlahEkorTerimaTextField.text!)!
        selectedData.receivedDeadWeight = Float(totalKGTerimaTextField.text!)!
        selectedData.receivedDeadQuantity = Int(jumlahEkorMatiTextField.text!)!
        
        let isUpdateSuccess = CarcassProduction.update(carcass: selectedData)
        if isUpdateSuccess {
            let banner = StatusBarNotificationBanner(title: "Carcass Record Updated!", style: .success)
            banner.show()
            uploadImagetoFirebaseStorage(imageRef: "rpaInputReceipts/" + selectedData.id! + ".jpeg")
        }
        else {
            let banner = StatusBarNotificationBanner(title: "Error Updating Carcass Record!", style: .danger)
            banner.show()
        }

    }
    
    func updateRPAInput(batchID : String,
                        slaughterTimestamp : Double,
                        typeOfWork : String,
                        receivedWeight : Float,
                        receivedQuantity : Int,
                        receivedDeadWeight : Float,
                        receivedDeadQuantity : Int) {
        finishButton.isEnabled = false
        
        let doc = Firestore.firestore().collection("carcassProduction").document(batchID)
        
        doc.updateData([
            "slaughterTimestamp" : slaughterTimestamp,
            "typeOfWork" : typeOfWork,
            "receivedWeight" : receivedWeight,
            "receivedQuantity" : receivedQuantity,
            "receivedDeadWeight" : receivedDeadWeight,
            "receivedDeadQuantity" : receivedDeadQuantity,
            "rpaInputCreatedBy" : fullName,
            "rpaInputCreatedTimestamp" : NSDate().timeIntervalSince1970
        ]) { err in
            if let err = err {
                print("Error writing new RPA document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error writing New RPA Document", style: .danger)
                banner.show()
                self.finishButton.isEnabled = true
            } else {
                print("Document successfully Updated!")
                let CarcassProductionUpdatedNotification = Notification.Name("carcassProductionUpdated")
                NotificationCenter.default.post(name: CarcassProductionUpdatedNotification, object: nil)
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
        let jpegData = tandaTerimaImageView.image!.jpegData(compressionQuality: 0.0)!
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
    
    func downloadImage(imageRef : String) {
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
            self.tandaTerimaImageView.image = image
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
        tandaTerimaImageView.image = image
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
        
        totalKGTerimaTextField.inputAccessoryView = doneToolbar
        totalKGMatiTextField.inputAccessoryView = doneToolbar
        jumlahEkorTerimaTextField.inputAccessoryView = doneToolbar
        jumlahEkorMatiTextField.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction(){
        totalKGTerimaTextField.resignFirstResponder()
        totalKGMatiTextField.resignFirstResponder()
        jumlahEkorTerimaTextField.resignFirstResponder()
        jumlahEkorMatiTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        totalKGTerimaTextField.resignFirstResponder()
        totalKGMatiTextField.resignFirstResponder()
        jumlahEkorTerimaTextField.resignFirstResponder()
        jumlahEkorMatiTextField.resignFirstResponder()
        return true
    }
    
}
