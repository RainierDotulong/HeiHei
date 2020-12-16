//
//  StorageImportViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 11/1/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import TextFieldEffects
import Firebase
import FirebaseFirestore
import FirebaseStorage
import Reachability
import Fusuma
import SVProgressHUD
import NotificationBannerSwift

class StorageInputTableViewCell : UITableViewCell {
    @IBOutlet var namaBarangLabel: UILabel!
    @IBOutlet var jumlahSatuanLabel: UILabel!
    @IBOutlet var suratJalanLabel: UILabel!
    @IBOutlet var categoryImageView: UIImageView!
    
}

class StorageInputViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, FusumaDelegate, sendScannerData {
    
    //Initalize Variables passed from previous VC
    var farmName : String = ""
    var fullName : String = ""
    var cycleNumber : Int  = 0
    var category : String = ""
    var action : String = ""
    
    var timestamp : String  = ""
    
    var selectedPricePerUnit : String = ""
    
    var priceListDataArray : [[String]] = [[String]]()
    var priceListTitleArray : [String] = [String]()
    
    var pickerData : [String] = [String]()
    var tableViewDataArray : [[String]] = [[String]]()
    
    var floorPickerData : [String] = [String]()
    
    @IBOutlet var namaBarangTextField: AkiraTextField!
    @IBOutlet var jumlahTextField: AkiraTextField!
    @IBOutlet var satuanTextField: AkiraTextField!
    @IBOutlet var suratJalanTextField: AkiraTextField!
    @IBOutlet var pickerView: UIPickerView!
    @IBOutlet var floorPickerView: UIPickerView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var navItem: UINavigationItem!
    @IBOutlet var storageInputTableView: UITableView!
    @IBOutlet var barButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        navItem.title = action
        switch action {
        case "Storage Export":
            barButton.title = ""
            barButton.image = nil
            barButton.isEnabled = false
            imageView.isHidden = true
            imageView.isUserInteractionEnabled = false
            suratJalanTextField.placeholder = "Lantai"
            suratJalanTextField.text = "Umum"
            suratJalanTextField.isUserInteractionEnabled = false
            switch farmName {
            case "pinantik":
                floorPickerData = ["Umum","Lantai 1", "Lantai 2"]
            case "kejayan":
                floorPickerData = ["Umum","Lantai 1","Lantai 2","Lantai 3"]
            default:
                floorPickerData = ["Umum","Lantai 1","Lantai 2","Lantai 3","Lantai 4","Lantai 5","Lantai 6"]
            }
        case "Storage Import":
            barButton.title = "Scan"
            barButton.image = UIImage(systemName: "qrcode")
            floorPickerView.isHidden = true
            floorPickerView.isUserInteractionEnabled = false
        default:
            barButton.title = ""
            barButton.isEnabled = false
            floorPickerView.isHidden = true
            floorPickerView.isUserInteractionEnabled = false
        }
        
        addDoneButtonOnKeyboard()
                
        getPriceListDataFromServer()
        
        //Shift elements up when keyboard comes out
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Add reachability observer
        if let reachability = AppDelegate.sharedAppDelegate()?.reachability
        {
            NotificationCenter.default.addObserver( self, selector: #selector( self.reachabilityChanged ),name: Notification.Name.reachabilityChanged, object: reachability )
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
    
    func dataReceivedFromScannerVC(code: String) {
        //NomorSuratJalan;NamaBarang,Jumlah,Satuan,Category,HargaPerSatuan;NamaBarang,Jumlah,Satuan,Category,HargaPerSatuan
        
        print(code)
        
        let scannedData = code.components(separatedBy: ";")
        for i in 0...scannedData.count - 1 {
            if i != 0 {
                var subArray : [String] = [String]()
                subArray = scannedData[i].components(separatedBy: ",")
                if subArray.count == 5 {
                    subArray.append(scannedData[0])
                    subArray.append(action)
                    subArray.append(fullName)
                    print(subArray)
                    tableViewDataArray.append(subArray)
                }
            }
        }
        suratJalanTextField.text = scannedData[0]
        storageInputTableView.reloadData()
    }
    
    @IBAction func imageViewTapped(_ sender: Any) {
        print("Image View Tapped")
        launchImagePicker()
    }
    func getPriceListDataFromServer() {
        SVProgressHUD.show()
        let db = Firestore.firestore()
        db.collection("priceList").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                SVProgressHUD.dismiss()
            } else {
                for document in querySnapshot!.documents {
                    //print("\(document.documentID) => \(document.data())")
                    if document.data()["category"] as! String != "Tenaga Kerja"{
                        //Setting up data
                        var subArray = [String]()
                        subArray.append(document.documentID)
                        subArray.append(document.data()["category"] as! String)
                        subArray.append(document.data()["pricePerUnit"] as! String)
                        subArray.append(document.data()["unit"] as! String)
                        self.priceListDataArray.append(subArray)
                        self.priceListTitleArray.append(document.documentID)
                    }
                }
                self.pickerData = self.priceListTitleArray
                self.pickerView.reloadAllComponents()
                SVProgressHUD.dismiss()
            }
        }
    }
    @IBAction func barButtonPressed(_ sender: Any) {
        if action == "Storage Import" {
            self.performSegue(withIdentifier: "goToScanner", sender: self)
        }
    }
    @IBAction func addButtonPressed(_ sender: Any) {
        if namaBarangTextField.text != "" && jumlahTextField.text != "" && satuanTextField.text != "" && suratJalanTextField.text != "" {
            let jumlah = jumlahTextField.text!.replacingOccurrences(of: ",", with: ".")
            tableViewDataArray.append([namaBarangTextField.text!,jumlah,satuanTextField.text!,category,selectedPricePerUnit,suratJalanTextField.text!,action,fullName])
            storageInputTableView.reloadData()
        }
        else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Incomplete Data", message: "Please Fill out all Text Fields", preferredStyle: .alert)
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
    
    @IBAction func finishButtonPressed(_ sender: Any) {
        timestamp = String(NSDate().timeIntervalSince1970)
        if action == "Storage Import" && tableViewDataArray.isEmpty == false && imageView.image != nil || action == "Storage Export" && tableViewDataArray.isEmpty == false {
            
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Confirm", message: "Are you sure you want to Finish?", preferredStyle: .alert)
            
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
                if self.action == "Storage Import" || self.action == "Storage Export" {
                    for data in self.tableViewDataArray {
                        self.uploadDataToServer(collection: "\(self.farmName)\(self.cycleNumber)Storage", namaBarang: data[0], jumlah: data[1], satuan: data[2], category: data[3], pricePerUnit: data[4], nomorSuratJalan: data[5], action: data[6], reporterName: data[7])
                        
                        //Auto Add Karung when pakan is checked out
                        if data[6] == "Storage Export" && data[3] == "Pakan" {
                            self.uploadDataToServer(collection: "\(self.farmName)\(self.cycleNumber)Storage", namaBarang: "Karung", jumlah: data[1], satuan: "Lembar", category: "Lain-Lain", pricePerUnit: "0", nomorSuratJalan: data[5], action: "Storage Import", reporterName: data[7])
                        }
                    }
                    if self.action == "Storage Import" {
                        self.uploadImagetoFirebaseStorage(imageRef : "\(self.farmName)\(self.cycleNumber)StorageImportImages/" + self.suratJalanTextField.text! + ".jpeg")
                    }
                    self.navigationController?.popViewController(animated: true)
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
        else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Incomplete Data", message: "Please Fill out all Text Fields", preferredStyle: .alert)
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
    
    func uploadDataToServer(collection : String, namaBarang : String, jumlah : String, satuan : String, category : String, pricePerUnit : String, nomorSuratJalan: String, action : String, reporterName : String) {
        let doc = Firestore.firestore().collection(collection).document(namaBarang + "-" + String(timestamp))
        doc.setData([
            "namaBarang" : namaBarang,
            "jumlah" : jumlah,
            "satuan" : satuan,
            "category" : category,
            "pricePerUnit" : pricePerUnit,
            "nomorSuratJalan" : nomorSuratJalan,
            "action" : action,
            "reporterName" : reporterName
            
        ]) { err in
            if let err = err {
                print("Error writing Storage Document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error writing Storage Document", style: .danger)
                banner.show()
            } else {
                print("Storage Document successfully written!")
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
    
    //Picker View Methods
    // Number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == floorPickerView {
            return floorPickerData.count
        }
        else {
            return pickerData.count
        }
    }
    
    // The data to return fopr the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == floorPickerView {
            return floorPickerData[row]
        }
        else {
            return pickerData[row]
        }
    }
    
    //This method is triggered whenever the user makes a change to the picker selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == floorPickerView {
            suratJalanTextField.text = floorPickerData[row]
        }
        else {
            print("SELECTED: " + pickerData[row])
            namaBarangTextField.text = priceListDataArray[row][0]
            category = priceListDataArray[row][1]
            selectedPricePerUnit = priceListDataArray[row][2]
            satuanTextField.text = priceListDataArray[row][3]
            jumlahTextField.text = ""
        }
    }
    
    // Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return tableViewDataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.rowHeight = UITableView.automaticDimension
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "storageInputCell", for: indexPath) as! StorageInputTableViewCell
        cell.namaBarangLabel.text = tableViewDataArray[tableViewDataArray.count - indexPath.row - 1][0]
        cell.jumlahSatuanLabel.text = tableViewDataArray[tableViewDataArray.count - indexPath.row - 1][1] + " " +  tableViewDataArray[tableViewDataArray.count - indexPath.row - 1][2]
        cell.suratJalanLabel.text = tableViewDataArray[tableViewDataArray.count - indexPath.row - 1][5]
        cell.categoryImageView.image = UIImage(named: CategoryToImage(category: tableViewDataArray[tableViewDataArray.count - indexPath.row - 1][3]))

        return cell
    }
    
    //Add Table Cell Button Actions
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let delete = UIContextualAction(style: .normal, title: "Delete") {  (contextualAction, view, boolValue) in
            print("Delete " + self.tableViewDataArray[self.tableViewDataArray.count - indexPath.row - 1][0])
            self.tableViewDataArray.remove(at: self.tableViewDataArray.count - indexPath.row - 1)
            self.storageInputTableView.reloadData()
        }
        delete.image = UIImage(systemName: "trash")
        delete.backgroundColor = .red
        
        let swipeActions = UISwipeActionsConfiguration(actions: [delete])
        
        return swipeActions
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(self.tableViewDataArray[tableViewDataArray.count - indexPath.row - 1][0])
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
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
        
        jumlahTextField.inputAccessoryView = doneToolbar
        suratJalanTextField.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction(){
        jumlahTextField.resignFirstResponder()
        suratJalanTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        jumlahTextField.resignFirstResponder()
        suratJalanTextField.resignFirstResponder()
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
    
    @objc private func reachabilityChanged( notification: NSNotification )
    {
        guard let reachability = notification.object as? Reachability else
        {
            return
        }

        if reachability.connection != .unavailable
        {
            if reachability.connection == .wifi
            {
                print("Reachable via WiFi")
                let banner = StatusBarNotificationBanner(title: "Connected via WiFi", style: .success)
                banner.show()
            }
            else
            {
                print("Reachable via Cellular")
                let banner = StatusBarNotificationBanner(title: "Connected via Cellular", style: .success)
                banner.show()
            }
        }
        else
        {
            print("Network not reachable")
            let banner = StatusBarNotificationBanner(title: "Not Connected", style: .danger)
            banner.show()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is ScannerViewController
        {
            let vc = segue.destination as? ScannerViewController
            vc?.delegate = self
        }
    }
}
