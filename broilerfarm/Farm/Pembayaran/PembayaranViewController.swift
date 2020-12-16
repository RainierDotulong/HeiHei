//
//  PembayaranViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 9/24/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import NotificationBannerSwift

class PembayaranViewController: UIViewController, UITextFieldDelegate, sendPerusahaanData, sendRekeningData {
    
    //Initalize Variables passed from previous VC
    var farmName : String = ""
    var fullName : String = ""
    var loginClass : String = ""
    var cycleNumber : Int  = 0
    var numberOfFloors : Int  = 0
    var isEdit : Bool = false
    var selectedPembayaran : Pembayaran = Pembayaran(creationTimestamp: 0, accTimestamp: 0, isAcc: false, isRefunded: false, nominal: 0, accBy: "", perusahaanId: "", perusahaanName: "", perusahaanType: "", rekeningName: "", bank: "", bankNumber: "", createdBy: "")

    @IBOutlet var navItem: UINavigationItem!
    
    @IBOutlet var perusahaanButton: UIButton!
    @IBOutlet var perusahaanCategoryImageView: UIImageView!
    @IBOutlet var nominalTextField: UITextField!
    @IBOutlet var pembayaranRefundLabel: UILabel!
    @IBOutlet var pembayaranRefundSwitch: UISwitch!
    @IBOutlet var rekeningButton: UIButton!
    @IBOutlet var bankLabel: UILabel!
    @IBOutlet var bankNumberLabel: UILabel!
    
    var isRefunded : Bool = false
    var selectedPerusahaan : Perusahaan = Perusahaan(id: "", timestamp: 0, companyName: "", companyAddress: "", companyType: "", contactName: "", contactPhone: "", createdBy: "")
    var rekening: String = ""
    var bank: String = ""
    var bankNumber: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        self.addDoneButtonOnKeyboard()
        
        navItem.title = "Pembayaran - \(farmName.uppercased()) \(cycleNumber)"
        
        if isEdit {
            self.selectedPerusahaan.companyName = selectedPembayaran.perusahaanName
            self.selectedPerusahaan.companyType = selectedPembayaran.perusahaanType
            self.perusahaanCategoryImageView.image = UIImage(named: selectedPerusahaan.companyType.lowercased())
            self.perusahaanButton.setTitle(" \(self.selectedPerusahaan.companyName)", for: .normal)
            self.perusahaanButton.setTitleColor(.black, for: .normal)
            self.perusahaanButton.tintColor = .black
            
            self.nominalTextField.text = String(selectedPembayaran.nominal)
            
            if self.selectedPembayaran.isRefunded {
                pembayaranRefundSwitch.isOn = true
                pembayaranRefundLabel.text = "Refund"
            }
            else {
                pembayaranRefundSwitch.isOn = false
                pembayaranRefundLabel.text = "Pembayaran"
            }
            
            self.rekening = selectedPembayaran.rekeningName
            self.rekeningButton.setTitle(" \(self.rekening)", for: .normal)
            self.rekeningButton.setTitleColor(.black, for: .normal)
            self.rekeningButton.tintColor = .black
            bankLabel.text = "Bank: \(selectedPembayaran.bank)"
            bankNumberLabel.text = "Bank Number: \(selectedPembayaran.bankNumber)"
        }
    }
    
    @IBAction func perusahaanButtonPressed(_ sender: Any) {
        print("Perusahaan")
        self.performSegue(withIdentifier: "goToPerusahaan", sender: self)
    }
    
    @IBAction func rekeningButtonPressed(_ sender: Any) {
        print("Rekening")
        self.performSegue(withIdentifier: "goToRekening", sender: self)
    }
    
    @IBAction func pembayaranRefundValueChanged(_ sender: Any) {
        if isRefunded {
            isRefunded = false
            pembayaranRefundLabel.text = "Pembayaran"
        }
        else {
            isRefunded = true
            pembayaranRefundLabel.text = "Refund"
        }
    }
    
    func perusahaanDataReceived(selectedPerusahaan: Perusahaan) {
        print(selectedPerusahaan.companyName)
        self.selectedPerusahaan = selectedPerusahaan
        self.perusahaanCategoryImageView.image = UIImage(named: selectedPerusahaan.companyType.lowercased())
        self.perusahaanButton.setTitle(" \(self.selectedPerusahaan.companyName)", for: .normal)
        self.perusahaanButton.setTitleColor(.black, for: .normal)
        self.perusahaanButton.tintColor = .black
    }
    
    func rekeningDataReceived(rekening: [String]) {
        print(rekening)
        self.rekening = rekening[0]
        self.bank = rekening[1]
        self.bankNumber = rekening[2]
        self.rekeningButton.setTitle(" \(self.rekening)", for: .normal)
        self.rekeningButton.setTitleColor(.black, for: .normal)
        self.rekeningButton.tintColor = .black
        self.bankLabel.text = "Bank: \(rekening[1])"
        self.bankNumberLabel.text = "Bank Number: \(rekening[2])"
    }
    
    @IBAction func finishButtonPressed(_ sender: Any) {
        print("Finish")
        guard rekening != "" else {
            let dialogMessage = UIAlertController(title: "Invalid Rekening", message: "Rekening field is Empty", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard selectedPerusahaan.companyName != "" else {
            let dialogMessage = UIAlertController(title: "Invalid Perusahaan", message: "Perusahaan not selected", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard Int(nominalTextField.text ?? "0") ?? 0 != 0 else {
            let dialogMessage = UIAlertController(title: "Invalid Nominal", message: "Nominal field is non-floating value", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        if isEdit {
            let pembayaran : Pembayaran = Pembayaran(id: selectedPembayaran.id!, creationTimestamp: selectedPembayaran.creationTimestamp, accTimestamp: 0, isAcc: false, isRefunded: isRefunded, nominal: Int(nominalTextField.text!)!, accBy: "", perusahaanId: selectedPerusahaan.id!, perusahaanName: selectedPerusahaan.companyName, perusahaanType: selectedPerusahaan.companyType, rekeningName: rekening, bank: bank, bankNumber: bankNumber, createdBy: fullName)
            
            let isUpdateSuccess = Pembayaran.update(farmName: farmName, cycleNumber: cycleNumber, pembayaran: pembayaran)
            
            if isUpdateSuccess {
                let banner = StatusBarNotificationBanner(title: "Pembayaran Record Updated!", style: .success)
                banner.show()
                navigationController?.popViewController(animated: true)
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .decimal
                let formattedNominal = numberFormatter.string(from: NSNumber(value:Int(nominalTextField.text!)!))
                
                var notes : String = ""
                if selectedPembayaran.isRefunded {
                    notes = "Refund"
                }
                else {
                    notes = "Pembayaran"
                }
                
                let telegramText = "*\(notes) Updated (\(farmName.capitalized) - \(cycleNumber))*\n-------------------------------------\nPerusahaan: \(selectedPerusahaan.companyName)\nNominal: Rp.\(formattedNominal!)\nRekening: \(rekening)\nUpdated by: \(self.fullName)"

                Telegram().postTelegramMessage(botToken: Telegram().ChickenAppBotToken, chatID: Telegram().PembayaranPanenCFChatID, text: telegramText, parse_mode: "Markdown")
            }
            else {
                let banner = StatusBarNotificationBanner(title: "Error Updating Pembayaran Record!", style: .danger)
                banner.show()
            }
        }
        else {
            let pembayaran : Pembayaran = Pembayaran(creationTimestamp: Date().timeIntervalSince1970, accTimestamp: 0, isAcc: false, isRefunded: isRefunded, nominal: Int(nominalTextField.text!)!, accBy: "", perusahaanId: selectedPerusahaan.id!, perusahaanName: selectedPerusahaan.companyName, perusahaanType: selectedPerusahaan.companyType, rekeningName: rekening, bank: bank, bankNumber: bankNumber, createdBy: fullName)
            let isCreateRecordSuccess = Pembayaran.create(farmName: farmName, cycleNumber: cycleNumber, pembayaran: pembayaran)
            
            if isCreateRecordSuccess {
                let banner = StatusBarNotificationBanner(title: "Pembayaran Record Created!", style: .success)
                banner.show()
                navigationController?.popViewController(animated: true)
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .decimal
                let formattedNominal = numberFormatter.string(from: NSNumber(value:Int(nominalTextField.text!)!))
                
                var notes : String = ""
                if selectedPembayaran.isRefunded {
                    notes = "Refund"
                }
                else {
                    notes = "Pembayaran"
                }
                
                let telegramText = "*\(notes) Posted (\(farmName.capitalized) - \(cycleNumber))*\n-------------------------------------\nPerusahaan: \(selectedPerusahaan.companyName)\nNominal: Rp.\(formattedNominal!)\nRekening: \(rekening)\nCreated by: \(self.fullName)"

                Telegram().postTelegramMessage(botToken: Telegram().ChickenAppBotToken, chatID: Telegram().PembayaranPanenCFChatID, text: telegramText, parse_mode: "Markdown")
            }
            else {
                let banner = StatusBarNotificationBanner(title: "Error Creating Pembayaran Record!", style: .danger)
                banner.show()
            }
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        nominalTextField.resignFirstResponder()
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PerusahaanTableViewController
        {
            let vc = segue.destination as? PerusahaanTableViewController
            vc?.isPick = true
            vc?.delegate = self
        }
        else if segue.destination is DataRekeningTableViewController
        {
            let vc = segue.destination as? DataRekeningTableViewController
            vc?.isPick = true
            vc?.delegate = self
        }
    }
}
