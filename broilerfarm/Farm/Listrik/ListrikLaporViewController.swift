//
//  ListrikLaporViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/6/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import Fusuma
import Firebase
import FirebaseFirestore
import FirebaseStorage
import JGProgressHUD
import NotificationBannerSwift

class ListrikLaporViewController: UIViewController, FusumaDelegate {
    
    //Variables Received From Previous VC
    var farmName : String = ""
    var fullName : String = ""
    var loginClass : String = ""
    var cycleNumber : Int = 0
    var numberOfFloors : Int  = 0
    
    var selectedListrikRecord : Listrik = Listrik(id: "", timestamp: 0, kWh: 0, reporterName: "")
    
    var finishTimestamp : Double = 0

    @IBOutlet var kWhTextField: UITextField!
    @IBOutlet var kWhImageView: UIImageView!
    @IBOutlet var tanggalButton: UIButton!
    @IBOutlet var datePickerSwitch: UISwitch!
    @IBOutlet var finishButton: UIButton!
    @IBOutlet var imageViewTop: NSLayoutConstraint!
    
    var isEdit : Bool = false
    var isDatePick : Bool = true
    
    var hud = JGProgressHUD(style: .dark)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        addDoneButtonOnKeyboard()
        
        if isEdit {
            finishTimestamp = selectedListrikRecord.timestamp
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: Date(timeIntervalSince1970: finishTimestamp))
            
            tanggalButton.setTitle(" Tangal: \(stringDate)", for: .normal)
            tanggalButton.setTitleColor(.black, for: .normal)
            tanggalButton.tintColor = .black
            
            kWhTextField.text = "\(selectedListrikRecord.kWh)"
            downloadFile(imageRef: "\(farmName)\(cycleNumber)ListrikImages/\(selectedListrikRecord.id!).jpeg")
            finishButton.setTitle("Update", for: .normal)
        }
        else {
            kWhImageView.image = UIImage(named: "redLogo")
            finishButton.setTitle("Finish", for: .normal)
        }
        
        if isDatePick {
            tanggalButton.isHidden = false
            imageViewTop.constant = 85
            datePickerSwitch.isOn = true
        }
        else {
            tanggalButton.isHidden = true
            imageViewTop.constant = 20
            datePickerSwitch.isOn = false
        }
        
        //Disable date pick for non admins
        if loginClass == "superadmin" || loginClass == "administrator" {
            datePickerSwitch.isEnabled = true
            datePickerSwitch.isHidden = false
        }
        else {
            isDatePick = false
            datePickerSwitch.isEnabled = false
            datePickerSwitch.isHidden = true
        }
    }
    
    @IBAction func datePickerSwitchValueChanged(_ sender: Any) {
        if isDatePick == false {
            isDatePick = true
            tanggalButton.isHidden = false
            imageViewTop.constant = 85
        }
        else {
            isDatePick = false
            tanggalButton.isHidden = true
            imageViewTop.constant = 20
        }
    }
    @IBAction func kWhImageViewTapped(_ sender: Any) {
        print("kWhImageView Tapped")
        launchImagePicker()
    }
    
    @IBAction func tanggalButtonPressed(_ sender: Any) {
        print("Tanggal")
        let datePicker = UIDatePicker()
        if isEdit {
            datePicker.date = Date(timeIntervalSince1970: selectedListrikRecord.timestamp)
        }
        let alert = UIAlertController(title: "\n\n\n\n\n\n\n\n\n\n\n", message: nil, preferredStyle: .actionSheet)
        alert.view.addSubview(datePicker)
        
        datePicker.snp.makeConstraints { (make) in
            make.centerX.equalTo(alert.view)
            make.top.equalTo(alert.view).offset(8)
        }
        
        let ok = UIAlertAction(title: "OK", style: .default) { (action) in
            self.finishTimestamp = datePicker.date.timeIntervalSince1970
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: Date(timeIntervalSince1970: self.finishTimestamp))
            
            self.tanggalButton.setTitle(" Tangal: \(stringDate)", for: .normal)
            self.tanggalButton.setTitleColor(.black, for: .normal)
            self.tanggalButton.tintColor = .black
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        alert.addAction(ok)
        alert.addAction(cancel)
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
        alert.popoverPresentationController?.permittedArrowDirections = []
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func finishButtonPressed(_ sender: Any) {
        guard Float(kWhTextField.text ?? "99999") ?? 99999 != 99999 else {
            print("Invalid kWh Value")
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Invalid kWh Value", message: "kWh value is non-floating.", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard kWhImageView.image != UIImage(named: "redLogo") else {
            print("Invalid kWh Value")
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Photo Required", message: "Tap on Image View to add Photo", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        let dialogMessage = UIAlertController(title: "Konfirmasi", message: "Selesaikan Laporan ini?", preferredStyle: .alert)
        
        // Create OK button with action handler
        let ok = UIAlertAction(title: "YA", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            //Finish Report
            self.finishReport()
        })
        
        // Create Cancel button with action handlder
        let cancel = UIAlertAction(title: "BATAL", style: .cancel) { (action) -> Void in
            print("Cancel button tapped")
        }
        
        //Add OK and Cancel button to dialog message
        dialogMessage.addAction(ok)
        dialogMessage.addAction(cancel)
        
        // Present dialog message to user
        self.present(dialogMessage, animated: true, completion: nil)
    }
    
    func finishReport() {
        if isDatePick == false && isEdit == false {
            finishTimestamp = NSDate().timeIntervalSince1970
        }
        
        var telegramText : String = ""
        if isEdit {
            //UPDATE RECORD
            let listrikRecord : Listrik = Listrik(id: selectedListrikRecord.id!, timestamp: finishTimestamp, kWh: Float(kWhTextField.text!)!, reporterName: fullName)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: Date(timeIntervalSince1970: finishTimestamp))
            
            telegramText = "*LAPORAN LISTRIK UPDATED*\n----------------------------\nDate: \(stringDate)\nkWh: *\(kWhTextField.text!)*\nPelapor: \(fullName)"
            
            let isUpdateRecordSuccess = Listrik.update(farmName: farmName, cycleNumber: cycleNumber, listrik: listrikRecord)
            
            if isUpdateRecordSuccess {
                let banner = StatusBarNotificationBanner(title: "Listrik Record Updated!", style: .success)
                banner.show()
                let ListrikRecordChangeNotification = Notification.Name("listrikRecordChanged")
                NotificationCenter.default.post(name: ListrikRecordChangeNotification, object: nil)
                navigationController?.popViewController(animated: true)
            }
            else {
                let banner = StatusBarNotificationBanner(title: "Error Updating Listrik Record!", style: .danger)
                banner.show()
            }
        }
        else {
            //CREATE RECORD
            let listrikRecord : Listrik = Listrik(id:  UUID().uuidString, timestamp: finishTimestamp, kWh: Float(kWhTextField.text!)!, reporterName: fullName)
            telegramText = "*LAPORAN LISTRIK*\n----------------------------\nkWh: *\(kWhTextField.text!)*\nPelapor: \(fullName)"
            let documentId = Listrik.create(farmName: farmName, cycleNumber: cycleNumber, listrik: listrikRecord)
            
            if documentId != "error" {
                self.uploadImagetoFirebaseStorage(imageRef: "\(farmName)\(cycleNumber)ListrikImages/" + documentId + ".jpeg")
                let banner = StatusBarNotificationBanner(title: "Listrik Record Uploaded!", style: .success)
                banner.show()
                let ListrikRecordChangeNotification = Notification.Name("listrikRecordChanged")
                NotificationCenter.default.post(name: ListrikRecordChangeNotification, object: nil)
                navigationController?.popViewController(animated: true)
            }
            else {
                let banner = StatusBarNotificationBanner(title: "Error Uploading Listrik Record!", style: .danger)
                banner.show()
            }
        }
        
        switch self.farmName {
            case "pinantik":
                Telegram().postTelegramMessage(botToken: Telegram().ChickenAppBotToken, chatID: Telegram().LaporanCFPinantikChatID, text: telegramText, parse_mode: "Markdown")
            case "kejayan":
                Telegram().postTelegramMessage(botToken: Telegram().ChickenAppBotToken, chatID: Telegram().LaporanCFKejayanChatID, text: telegramText, parse_mode: "Markdown")
            default:
                Telegram().postTelegramMessage(botToken: Telegram().ChickenAppBotToken, chatID: Telegram().LaporanCFLewihChatID, text: telegramText, parse_mode: "Markdown")
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
        let jpegData = kWhImageView.image!.jpegData(compressionQuality: 0.0)!
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
    
    func downloadFile(imageRef : String) {
        self.hud.detailTextLabel.text = "0% Complete"
        self.hud.textLabel.text = "Loading"
        self.hud.show(in: self.view)
        
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
            self.kWhImageView.image = image
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
            if Float(percentComplete) == 100.0 {
                self.hud.textLabel.text = "Success"
                self.hud.detailTextLabel.text = "\(String(format: "%.1f",Float(percentComplete)))% Complete"
                self.hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                self.hud.dismiss(afterDelay: 1.0)
            }
            else {
                self.hud.detailTextLabel.text = "\(String(format: "%.1f",Float(percentComplete)))% Complete"
            }
        }

        downloadTask.observe(.success) { snapshot in
          // Download completed successfully
            self.hud.dismiss()
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
            self.hud.dismiss()
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
            self.hud.dismiss()
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
            self.hud.dismiss()
            // User cancelled the download
            print("User cancelled the download")
            break

          /* ... */

          case .unknown:
            self.hud.dismiss()
            // Unknown error occurred, inspect the server response
            print("Unknown error occurred, inspect the server responsed")
            break
          default:
            self.hud.dismiss()
            // Another error occurred. This is a good place to retry the download.
            break
          }
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
        
        kWhImageView.image = image
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
        
        kWhTextField.inputAccessoryView = doneToolbar
        
    }
    
    @objc func doneButtonAction(){
        kWhTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        kWhTextField.resignFirstResponder()
        return true
    }
}
