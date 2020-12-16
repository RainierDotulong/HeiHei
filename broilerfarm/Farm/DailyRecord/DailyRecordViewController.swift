//
//  DailyRecordViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 6/30/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import TextFieldEffects
import Reachability
import NotificationBannerSwift

class DailyRecordViewController : UIViewController, UITextFieldDelegate {
    
    @IBOutlet var deplesiMatiTextField: JiroTextField!
    @IBOutlet var deplesiCulingTextField: JiroTextField!
    @IBOutlet var pakanPakaiTextField: JiroTextField!
    @IBOutlet var notesTextField: JiroTextField!
    @IBOutlet var bodyWeightTextField: JiroTextField!
    @IBOutlet var floorButton: UIButton!
    @IBOutlet var kesehatanAyamButton: UIButton!
    
    //Variables Received From Previous VC
    var farmName : String = ""
    var fullName : String = ""
    var loginClass : String = ""
    var cycleNumber : Int = 0
    var numberOfFloors : Int  = 0
    var selectedDailyRecordData : DailyRecord = DailyRecord(timestamp: 0, deplesiMati: 0, deplesiCuling: 0, pakanPakai: 0, bodyWeight: 0, kesehatanAyam: "", notes: "", lantai: 0, reporterName: "")
    
    var floor : Int = 0
    
    var kesehatanAyam : String = ""
    var kesehatanAyamData : [String] = [String]()
    
    var finishTimestamp : Double = 0
    
    var isEdit : Bool = false
    var isDatePick : Bool = false
    
    @IBOutlet var datePickerSwitch: UISwitch!
    
    @IBOutlet var datePickerView: UIDatePicker!
    
    override func viewDidLoad() {
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        //add Done button on Text View Keyboards
        self.addDoneButtonOnKeyboard()
        
        kesehatanAyamData = ["Sehat","Coly","Coxy","CRD"]
        
        // Add reachability observer
        if let reachability = AppDelegate.sharedAppDelegate()?.reachability
        {
            NotificationCenter.default.addObserver( self, selector: #selector( self.reachabilityChanged ),name: Notification.Name.reachabilityChanged, object: reachability )
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
        
        if isDatePick {
            datePickerSwitch.isOn = true
            datePickerView.isHidden = false
        }
        else {
            datePickerSwitch.isOn = false
            datePickerView.isHidden = true
        }
        
        if isEdit {
            datePickerView.date = Date(timeIntervalSince1970: selectedDailyRecordData.timestamp)
            finishTimestamp = selectedDailyRecordData.timestamp
            deplesiMatiTextField.text = String(selectedDailyRecordData.deplesiMati)
            deplesiCulingTextField.text = String(selectedDailyRecordData.deplesiCuling)
            pakanPakaiTextField.text = String(selectedDailyRecordData.pakanPakai)
            bodyWeightTextField.text = String(format: "%.2f", selectedDailyRecordData.bodyWeight)
            notesTextField.text = selectedDailyRecordData.notes
            floor = selectedDailyRecordData.lantai
            floorButton.setTitle(" Lantai: Lantai \(selectedDailyRecordData.lantai)", for: .normal)
            floorButton.setTitleColor(.black, for: .normal)
            floorButton.tintColor = .black
            kesehatanAyam = selectedDailyRecordData.kesehatanAyam
            kesehatanAyamButton.setTitle(" Kesehatan Ayam: \(selectedDailyRecordData.kesehatanAyam)", for: .normal)
            kesehatanAyamButton.setTitleColor(.black, for: .normal)
            kesehatanAyamButton.tintColor = .black
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
    
    @IBAction func datePickerValueChanged(_ sender: Any) {
        if isDatePick == false {
            isDatePick = true
            datePickerView.isHidden = false
        }
        else {
            isDatePick = false
            datePickerView.isHidden = true
        }
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func datePickerViewValueChanged(_ sender: Any) {
        finishTimestamp = datePickerView.date.timeIntervalSince1970
    }
    
    @IBAction func floorButtonPressed(_ sender: Any) {
        let dialogMessage = UIAlertController(title: "Lantai", message: "Pilih lantai yang dilaporkan", preferredStyle: .alert)
        
        for floor in 1...numberOfFloors {
            let floorAction = UIAlertAction(title: "Lantai \(floor)", style: .default, handler: { (action) -> Void in
                
                self.floor = floor
                
                self.floorButton.setTitle(" Lantai: Lantai \(floor)", for: .normal)
                self.floorButton.setTitleColor(.black, for: .normal)
                self.floorButton.tintColor = .black
            })
            dialogMessage.addAction(floorAction)
        }
        
        self.present(dialogMessage, animated: true, completion: nil)
    }
    
    @IBAction func kesehatanAyamButtonPressed(_ sender: Any) {
        let dialogMessage = UIAlertController(title: "Lantai", message: "Pilih lantai yang dilaporkan", preferredStyle: .alert)
        
        for kesehatanAyam in kesehatanAyamData {
            let action = UIAlertAction(title: kesehatanAyam, style: .default, handler: { (action) -> Void in
                self.kesehatanAyam = kesehatanAyam
                self.kesehatanAyamButton.setTitle(" Kesehatan Ayam: \(kesehatanAyam)", for: .normal)
                self.kesehatanAyamButton.setTitleColor(.black, for: .normal)
                self.kesehatanAyamButton.tintColor = .black
            })
            dialogMessage.addAction(action)
        }
        
        self.present(dialogMessage, animated: true, completion: nil)
    }
    
    @IBAction func finishButtonPressed(_ sender: Any) {
        
        guard Float(bodyWeightTextField.text?.replacingOccurrences(of: ",", with: ".") ?? "0") ?? 0 != 0 else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Invalid Body Weight", message: "Body weight is non-floating value", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        if deplesiMatiTextField.text != "" && deplesiCulingTextField.text != "" && pakanPakaiTextField.text != "" &&
            floor != 0 {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Confirm", message: "Are you sure you want to  finish this report?", preferredStyle: .alert)
            
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
                
                //Finish Report
                self.finishReport()
                
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
            print("Incomplete Data")
            
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
    
    func finishReport() {
        print("FINISH REPORT")
        if isDatePick == false && isEdit == false {
            finishTimestamp = NSDate().timeIntervalSince1970
        }
        
        var telegramText : String = ""
        if isEdit {
            //UPDATE RECORD
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: Date(timeIntervalSince1970: finishTimestamp))
            
            telegramText = "*DAILY REPORT UPDATED - LT.\(floor)*\n----------------------------\nDate: \(stringDate)\nDeplesi Mati: \(deplesiMatiTextField.text!) Ekor\nDeplesi Culing: \(self.deplesiCulingTextField.text!) Ekor\nPakan Terpakai: \(pakanPakaiTextField.text!) Zak\nBody Weight: *\(bodyWeightTextField.text!)* Gram\nKesehatan Ayam: *\(kesehatanAyam)*\n\nNotes: \(notesTextField.text ?? "")\nPelapor: \(fullName)"
            
            let isUpdateRecordSuccess = DailyRecord.update(documentId: selectedDailyRecordData.id!, farmName: farmName, cycleNumber: cycleNumber, timestamp: finishTimestamp, deplesiMati: Int(deplesiMatiTextField.text ?? "0") ?? 0, deplesiCuling: Int(deplesiCulingTextField.text ?? "0") ?? 0, pakanPakai: Int(pakanPakaiTextField.text ?? "0") ?? 0, bodyWeight: Float(bodyWeightTextField.text ?? "0") ?? 0, kesehatanAyam: kesehatanAyam, notes: notesTextField.text ?? "", lantai: floor, reporterName: fullName)
            
            if isUpdateRecordSuccess {
                let banner = StatusBarNotificationBanner(title: "Daily Record Updated!", style: .success)
                banner.show()
                let DailyRecordChangeNotification = Notification.Name("dailyRecordChanged")
                NotificationCenter.default.post(name: DailyRecordChangeNotification, object: nil)
                navigationController?.popViewController(animated: true)
            }
            else {
                let banner = StatusBarNotificationBanner(title: "Error Updating Daily Record!", style: .danger)
                banner.show()
            }
        }
        else {
            //CREATE RECORD
            telegramText = "*DAILY REPORT - LT.\(floor)*\n----------------------------\nDeplesi Mati: \(deplesiMatiTextField.text!) Ekor\nDeplesi Culing: \(self.deplesiCulingTextField.text!) Ekor\nPakan Terpakai: \(pakanPakaiTextField.text!) Zak\nBody Weight: *\(bodyWeightTextField.text!)* Gram\nKesehatan Ayam: *\(kesehatanAyam)*\n\nNotes: \(notesTextField.text ?? "")\nPelapor: \(fullName)"
            let isCreateRecordSuccess = DailyRecord.create(farmName: farmName, cycleNumber: cycleNumber, timestamp: finishTimestamp, deplesiMati: Int(deplesiMatiTextField.text ?? "0") ?? 0, deplesiCuling: Int(deplesiCulingTextField.text ?? "0") ?? 0, pakanPakai: Int(pakanPakaiTextField.text ?? "0") ?? 0, bodyWeight: Float(bodyWeightTextField.text ?? "0") ?? 0, kesehatanAyam: kesehatanAyam, notes: notesTextField.text ?? "", lantai: floor, reporterName: fullName)
            
            if isCreateRecordSuccess {
                let banner = StatusBarNotificationBanner(title: "Daily Record Uploaded!", style: .success)
                banner.show()
                let DailyRecordChangeNotification = Notification.Name("dailyRecordChanged")
                NotificationCenter.default.post(name: DailyRecordChangeNotification, object: nil)
                navigationController?.popViewController(animated: true)
            }
            else {
                let banner = StatusBarNotificationBanner(title: "Error Uploading Daily Record!", style: .danger)
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
    
    //Add Done Button on Keyboard
    func addDoneButtonOnKeyboard(){
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))
        
        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        deplesiMatiTextField.inputAccessoryView = doneToolbar
        deplesiCulingTextField.inputAccessoryView = doneToolbar
        pakanPakaiTextField.inputAccessoryView = doneToolbar
        bodyWeightTextField.inputAccessoryView = doneToolbar
        notesTextField.inputAccessoryView = doneToolbar

    }
    
    @objc func doneButtonAction(){
        deplesiMatiTextField.resignFirstResponder()
        deplesiCulingTextField.resignFirstResponder()
        pakanPakaiTextField.resignFirstResponder()
        bodyWeightTextField.resignFirstResponder()
        notesTextField.resignFirstResponder()

    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        deplesiMatiTextField.resignFirstResponder()
        deplesiCulingTextField.resignFirstResponder()
        pakanPakaiTextField.resignFirstResponder()
        bodyWeightTextField.resignFirstResponder()
        notesTextField.resignFirstResponder()
        return true
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
}
