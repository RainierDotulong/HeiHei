//
//  TransportInputViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 6/26/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import SVProgressHUD
import Firebase
import FirebaseFirestore
import NotificationBannerSwift
import TextFieldEffects

class TransportInputViewController: UIViewController, UITextFieldDelegate, sendTransportProviderData, sendRpaData {
    
    var fullName : String = ""
    var loginClass : String = ""
    var selectedData : CarcassProduction = CarcassProduction(hargaBeliAyam: 0, transportName: "", transportBank: "", transportBankNumber: "", transportBankName: "", transportPaymentTerm: "", amountDueForTransport: 0, licensePlateNumber: "", sourceFarm: "", escort: "", transportedWeight: 0, transportedQuantity: 0, transportCreatedBy: "", transportCreatedTimestamp: 0, rpaName: "", rpaAddress: "", rpaLatitude: 0, rpaLongitude: 0, rpaNoNkv: "", rpaPerhitunganBiaya: "", rpaPaymentTerm: "", rpaSideProduct: false, rpaContactPerson: "", rpaContactPhone: "", rpaBank: "", rpaBankName: "", rpaBankNumber: "", slaughterTimestamp: 0, typeOfWork: "", receivedWeight: 0, receivedQuantity: 0, receivedDeadWeight: 0, receivedDeadQuantity: 0, rpaInputCreatedBy: "", rpaInputCreatedTimestamp: 0, yieldedWeight: 0, yieldedProductNames: [String](), yieldedProductUnits: [String](), yieldedProductQuantities: [Float](), initialStorageProvider: "", rpaOutputCreatedBy: "", rpaOutputCreatedTimestamp: 0, rpaHargaPerKG: 0)
    var edit : Bool = false
    
    var referencePrice : Int = 0
    
    @IBOutlet var totalHargaBeliAyamTextField: AkiraTextField!
    @IBOutlet var escortTextField: AkiraTextField!
    @IBOutlet var amountDueTextField: AkiraTextField!
    @IBOutlet var totalKgTextField: AkiraTextField!
    @IBOutlet var jumlahEkorTextField: AkiraTextField!
    @IBOutlet var sourceFarmButton: UIButton!
    @IBOutlet var transportProviderButton: UIButton!
    @IBOutlet var rpaButton: UIButton!
    @IBOutlet var finishButton : UIButton!
    @IBOutlet var transportBankLabel: UILabel!
    @IBOutlet var transportBankDetailsLabel: UILabel!
    @IBOutlet var rpaTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        if edit {
            escortTextField.text = selectedData.escort
            totalHargaBeliAyamTextField.text = "\(selectedData.hargaBeliAyam)"
            amountDueTextField.text = "\(selectedData.amountDueForTransport)"
            totalKgTextField.text = "\(selectedData.transportedWeight)"
            jumlahEkorTextField.text = "\(selectedData.transportedQuantity)"
            sourceFarmButton.setTitle(" Source Farm: \(selectedData.sourceFarm.capitalized)", for: .normal)
            sourceFarmButton.setTitleColor(.black, for: .normal)
            sourceFarmButton.tintColor = .black
            transportProviderButton.setTitle(" Transport Provider: \(selectedData.transportName)", for: .normal)
            transportProviderButton.setTitleColor(.black, for: .normal)
            transportProviderButton.tintColor = .black
            transportBankLabel.text = "\(selectedData.transportBankName)"
            transportBankDetailsLabel.text = "\(selectedData.transportBank) - \(selectedData.transportBankNumber)"
            rpaButton.setTitle(" RPA: \(selectedData.rpaName)", for: .normal)
            rpaButton.setTitleColor(.black, for: .normal)
            rpaButton.tintColor = .black
            rpaTextView.text = "Address: \(selectedData.rpaAddress)\n\nCoordinates: \(selectedData.rpaLatitude),\(selectedData.rpaLongitude)\n\nNomor NKV: \(selectedData.rpaNoNkv)\n\nPerhitungan Biaya: \(selectedData.rpaPerhitunganBiaya)\n\nPayment Term: \(selectedData.rpaPaymentTerm)\n\nSide Product: \(selectedData.rpaSideProduct)\n\nContact Person: \(selectedData.rpaContactPerson) - \(selectedData.rpaContactPhone)\n\nBank: \(selectedData.rpaBank)\n\n Nomor Rekening: \(selectedData.rpaBankNumber)\n\nAtas Nama Bank: \(selectedData.rpaBankName)"
            finishButton.setTitle(" Update", for: .normal)
        }
        //Add Done Button on keyboard
        addDoneButtonOnKeyboard()
    }
    
    func rpaDataReceived(rpa: RPA) {
        selectedData.rpaName = rpa.name
        selectedData.rpaAddress = rpa.address
        selectedData.rpaLatitude = rpa.latitude
        selectedData.rpaLongitude = rpa.longitude
        selectedData.rpaNoNkv = rpa.noNkv
        selectedData.rpaPerhitunganBiaya = rpa.perhitunganBiaya
        selectedData.rpaPaymentTerm = rpa.paymentTerm
        selectedData.rpaSideProduct = rpa.sideProduct
        selectedData.rpaContactPerson = rpa.contactPerson
        selectedData.rpaContactPhone = rpa.contactPhone
        selectedData.rpaBank = rpa.bank
        selectedData.rpaBankName = rpa.bankName
        selectedData.rpaBankNumber = rpa.bankNumber
        
        rpaButton.setTitle(" RPA: \(rpa.name)", for: .normal)
        rpaButton.setTitleColor(.black, for: .normal)
        rpaButton.tintColor = .black
        rpaTextView.text = "Address: \(rpa.address)\n\nCoordinates: \(rpa.latitude),\(rpa.longitude)\n\nNomor NKV: \(rpa.noNkv)\n\nPerhitungan Biaya: \(rpa.perhitunganBiaya)\n\nPayment Term: \(rpa.paymentTerm)\n\nSide Product: \(rpa.sideProduct)\n\nContact Person: \(rpa.contactPerson) - \(rpa.contactPhone)\n\nBank: \(rpa.bank)\n\n Nomor Rekening: \(rpa.bankNumber)\n\nAtas Nama Bank: \(rpa.bankName)\n\nReferensi Harga/KG: \(rpa.referencePrice)"
        
        referencePrice = rpa.referencePrice
    }
    
    func transportProviderDataReceived(transportProvider: TransportProvider) {
        selectedData.transportName = transportProvider.name
        selectedData.transportBank = transportProvider.bank
        selectedData.transportBankNumber = transportProvider.bankNumber
        selectedData.transportBankName = transportProvider.bankName
        selectedData.transportPaymentTerm = transportProvider.paymentTerm
        
        transportProviderButton.setTitle(" Transport Provider: \(transportProvider.name)", for: .normal)
        transportProviderButton.setTitleColor(.black, for: .normal)
        transportProviderButton.tintColor = .black
        transportBankLabel.text = "\(transportProvider.bankName)"
        transportBankDetailsLabel.text = "\(transportProvider.bank) - \(transportProvider.bankNumber)"
    }

    
    @IBAction func sourceFarmButtonPressed(_ sender: Any) {
        print("Source Farm")
        let dialogMessage = UIAlertController(title: "Source Farm", message: "", preferredStyle: .alert)
        
        let pinanitk = UIAlertAction(title: "Pinantik", style: .default, handler: { (action) -> Void in
            self.selectedData.sourceFarm = "pinantik"
            self.sourceFarmButton.setTitle(" Source Farm: Pinantik", for: .normal)
            self.sourceFarmButton.setTitleColor(.black, for: .normal)
            self.sourceFarmButton.tintColor = .black
        })
        let kejayan = UIAlertAction(title: "Kejayan", style: .default, handler: { (action) -> Void in
            self.selectedData.sourceFarm = "kejayan"
            self.sourceFarmButton.setTitle(" Source Farm: Kejayan", for: .normal)
            self.sourceFarmButton.setTitleColor(.black, for: .normal)
            self.sourceFarmButton.tintColor = .black
        })
        let lewih = UIAlertAction(title: "Lewih", style: .default, handler: { (action) -> Void in
            self.selectedData.sourceFarm = "lewih"
            self.sourceFarmButton.setTitle(" Source Farm: Lewih", for: .normal)
            self.sourceFarmButton.setTitleColor(.black, for: .normal)
            self.sourceFarmButton.tintColor = .black
        })
        
        dialogMessage.addAction(pinanitk)
        dialogMessage.addAction(kejayan)
        dialogMessage.addAction(lewih)
        
        self.present(dialogMessage, animated: true, completion: nil)
    }
    @IBAction func transportProiderButtonPressed(_ sender: Any) {
        print("Transport Provider")
        self.performSegue(withIdentifier: "goToTransportProviders", sender: self)
    }
    @IBAction func rpaButtonPressed(_ sender: Any) {
        print("RPA")
        self.performSegue(withIdentifier: "goToRPA", sender: self)
    }
    @IBAction func finishButtonPressed(_ sender: Any) {
        guard escortTextField.text != "" else {
            let dialogMessage = UIAlertController(title: "Escort Text Field Empty", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard Int(amountDueTextField.text ?? "") ?? 0 != 0 else {
            let dialogMessage = UIAlertController(title: "Amount Text Field Invalid", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard Float(totalKgTextField.text ?? "") ?? 0 != 0 else {
            let dialogMessage = UIAlertController(title: "Total KG Text Field Invalid", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard Int(jumlahEkorTextField.text ?? "") ?? 0 != 0 else {
            let dialogMessage = UIAlertController(title: "Jumlah Ekor Text Field Invalid", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard Int(totalHargaBeliAyamTextField.text ?? "") ?? 0 != 0 else {
            let dialogMessage = UIAlertController(title: "Harga Per KG Text Field Invalid", message: "Please Complete Data", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard selectedData.sourceFarm != "" else {
            let dialogMessage = UIAlertController(title: "Source Farm Empty", message: "Please Choose Source Farm", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard selectedData.transportName != "" else {
            let dialogMessage = UIAlertController(title: "Tranport Empty", message: "Please Choose Transport Provider", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard selectedData.rpaName != "" else {
            let dialogMessage = UIAlertController(title: "RPA Empty", message: "Please Choose RPA", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        selectedData.hargaBeliAyam = Int(totalHargaBeliAyamTextField.text!)!
        selectedData.amountDueForTransport = Int(amountDueTextField.text!)!
        selectedData.escort = escortTextField.text!
        selectedData.transportedWeight = Float(totalKgTextField.text!)!
        selectedData.transportedQuantity = Int(jumlahEkorTextField.text!)!
        selectedData.transportCreatedTimestamp = Date().timeIntervalSince1970
        selectedData.transportCreatedBy = fullName
        
        if edit {
            let isUpdateSuccess = CarcassProduction.update(carcass: selectedData)
            if isUpdateSuccess {
                let banner = StatusBarNotificationBanner(title: "Carcass Record Updated!", style: .success)
                banner.show()
            }
            else {
                let banner = StatusBarNotificationBanner(title: "Error Updating Carcass Record!", style: .danger)
                banner.show()
            }
        }
        else {
            let isCreateSuccess = CarcassProduction.create(carcass: selectedData)
            if isCreateSuccess {
                let banner = StatusBarNotificationBanner(title: "Carcass Record Created!", style: .success)
                banner.show()
                self.navigationController?.popViewController(animated: true)
            }
            else {
                let banner = StatusBarNotificationBanner(title: "Error Creating Carcass Record!", style: .danger)
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
        
        escortTextField.inputAccessoryView = doneToolbar
        totalHargaBeliAyamTextField.inputAccessoryView = doneToolbar
        amountDueTextField.inputAccessoryView = doneToolbar
        totalKgTextField.inputAccessoryView = doneToolbar
        jumlahEkorTextField.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction(){
        escortTextField.resignFirstResponder()
        totalHargaBeliAyamTextField.resignFirstResponder()
        amountDueTextField.resignFirstResponder()
        totalKgTextField.resignFirstResponder()
        jumlahEkorTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        escortTextField.resignFirstResponder()
        totalHargaBeliAyamTextField.resignFirstResponder()
        amountDueTextField.resignFirstResponder()
        totalKgTextField.resignFirstResponder()
        jumlahEkorTextField.resignFirstResponder()
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToTransportProviders" {
            let vc = segue.destination as? TransportProvidersTableViewController
            vc?.delegate = self
            vc?.pick = true
        }
        else if segue.identifier == "goToRPA" {
            let vc = segue.destination as? RPATableViewController
            vc?.delegate = self
            vc?.pick = true
        }
    }
}
