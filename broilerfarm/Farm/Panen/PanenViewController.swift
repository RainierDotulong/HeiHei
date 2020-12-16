//
//  PanenViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/25/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import NotificationBannerSwift
import CoreBluetooth

class PanenViewController: UIViewController, sendPemborongPanen, sendBleData {
    
    var farmName : String = ""
    var fullName : String = ""
    var email : String = ""
    var loginClass : String = ""
    var cycleNumber : Int  = 0
    var numberOfFloors : Int  = 0
    var panen : Panen = Panen(id: "", creationTimestamp: 0, isChecked: false, hargaPerKG: 0, mulaiMuatTimestamp: 0, selesaiMuatTimestamp: 0, jumlahKGDO: 0, namaPerusahaan: "", alamatPerusahaan: "", metodePembayaran: "", namaSopir: "", noKendaraaan: "", noSopir: "", pembuatDO: "", rangeBB: "", rangeBawah: 0, rangeAtas: 0, status: "", pengambilanTimestamp: 0, timestamps: [Double](), lantai: [Int](), jumlah: [Int](), isSubtract: [Bool](), isVoided: [Bool](), sekat: [String](), tara: [Float](), berat: [Float](), pemborongPanen: "", penimbang: "", accBy: "")
    
    @IBOutlet var namaPerusahaanLabel: UILabel!
    @IBOutlet var nomorPanenLabel: UILabel!
    @IBOutlet var metodePembayaranLabel: UILabel!
    @IBOutlet var jumlahKGLabel: UILabel!
    @IBOutlet var rangeBBLabel: UILabel!
    @IBOutlet var sopirLabel: UILabel!
    @IBOutlet var noKendaraanLabel: UILabel!
    @IBOutlet var pemborongPanenButton: UIButton!
    @IBOutlet var bleDeviceButton: UIButton!
    @IBOutlet var sekatButton: UIButton!
    @IBOutlet var lantaiButton: UIButton!
    
    @IBOutlet var editButton: UIBarButtonItem!
    @IBOutlet var startButton: UIButton!
    
    var selectedBleDevice : CBPeripheral?
    var selectedFloor : Int = 0
    var selectedSekat : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        namaPerusahaanLabel.text = panen.namaPerusahaan
        nomorPanenLabel.text = "\(farmName.prefix(1).uppercased())\(cycleNumber)-\(Int(panen.creationTimestamp))"
        metodePembayaranLabel.text = "Pembayaran: \(panen.metodePembayaran)"
        jumlahKGLabel.text = ": \(panen.jumlahKGDO) KG"
        rangeBBLabel.text = ": \(panen.rangeBB)"
        sopirLabel.text = ": \(panen.namaSopir) (\(panen.noSopir))"
        noKendaraanLabel.text = ": \(panen.noKendaraaan)"
        
        if panen.pemborongPanen != "" {
            pemborongPanenButton.setTitle(" Pemborong Panen: \(panen.pemborongPanen)", for: .normal)
            pemborongPanenButton.setTitleColor(.black, for: .normal)
            pemborongPanenButton.tintColor = .black
        }
        
        if panen.jumlah.isEmpty == false {
            selectedSekat = panen.sekat[0]
            sekatButton.setTitle(" Sekat: \(panen.sekat[0])", for: .normal)
            sekatButton.setTitleColor(.black, for: .normal)
            sekatButton.tintColor = .black
            selectedFloor = panen.lantai[0]
            lantaiButton.setTitle(" Lantai: \(panen.lantai[0])", for: .normal)
            lantaiButton.setTitleColor(.black, for: .normal)
            lantaiButton.tintColor = .black
        }
        
        if panen.status == "ACC" {
            startButton.setTitle("Start", for: .normal)
        }
        else if panen.status == "Started" {
            startButton.setTitle("Continue", for: .normal)
        }
        else {
            startButton.setTitle("Start", for: .normal)
        }
        
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
    }
    
    @IBAction func editButtonPressed(_ sender: Any) {
        print("Edit Sopir & No Telp Sopir")
        let alert = UIAlertController(title: "Edit Sopir/No Telp Sopir", message:"Please Specify Data", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.text = self.panen.namaSopir
            textField.placeholder = "Nama"
            textField.keyboardType = .default
            textField.autocapitalizationType = .words
        }
        
        alert.addTextField { (textField) in
            textField.text = self.panen.noSopir
            textField.placeholder = "Nomor Telpon"
            textField.keyboardType = .phonePad
        }
        
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            let textField = alert.textFields![0]
            let textField2 = alert.textFields![1]
            
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
            
            guard textField2.text ?? "" != "" else {
                print("Incomplete Data")
                let dialogMessage = UIAlertController(title: "Incomplete Data", message: "Text Field Empty", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            print("Update Nama & Telp Sopir")
            self.updateSopir(nama: textField.text!, noTelp: textField2.text!)
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            print("Cancel button tapped")
        }
        
        alert.addAction(ok)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func pemborongPanenReceived(pemborongPanen: String) {
        pemborongPanenButton.setTitle(" Pemborong Panen: \(pemborongPanen)", for: .normal)
        pemborongPanenButton.setTitleColor(.black, for: .normal)
        pemborongPanenButton.tintColor = .black
        self.panen.pemborongPanen = pemborongPanen
    }
    
    func bleDataReceived(ble: CBPeripheral) {
        bleDeviceButton.setTitle(" BLE Device: \(ble.name ?? "NULL")", for: .normal)
        bleDeviceButton.setTitleColor(.black, for: .normal)
        bleDeviceButton.tintColor = .black
        selectedBleDevice = ble
    }
    
    func updateSopir(nama: String, noTelp : String) {
        self.panen.namaSopir = nama
        self.panen.noSopir = noTelp
        sopirLabel.text = ": \(nama) (\(noTelp))"
        let isPanenUpdateSuccess = Panen.update(farmName: farmName, cycleNumber: cycleNumber, panen: panen)
        
        if isPanenUpdateSuccess {
            print("Panen Record Update Success")
            let banner = StatusBarNotificationBanner(title: "Sopir Panen Updated!", style: .success)
            banner.show()
        }
        else {
            let banner = StatusBarNotificationBanner(title: "Error Updating Panen Record!", style: .danger)
            banner.show()
        }
    }
    
    func startPanen() {
        panen.penimbang = fullName
        panen.status = "Started"
        panen.mulaiMuatTimestamp = Date().timeIntervalSince1970
        let isPanenUpdateSuccss = Panen.update(farmName: farmName, cycleNumber: cycleNumber, panen: panen)
        
        if isPanenUpdateSuccss {
            print("Panen Document successfully Updated!")
            let telegramText = "*PANEN START (\(self.farmName.prefix(1).uppercased())\(self.cycleNumber)-\(Int(panen.creationTimestamp)))*\n-------------------------------------\nPerusahaan: \(panen.namaPerusahaan)\nNo Kendaraan: \(panen.noKendaraaan)\nRange BB: \(panen.rangeBB)\nSopir:\(panen.namaSopir) (\(panen.noSopir))\nMetode Pembayaran: \(panen.metodePembayaran)\nPemborong Panen: \(panen.pemborongPanen)\nPenimbang: \(self.fullName)"

            Telegram().postTelegramMessage(botToken: Telegram().ChickenAppBotToken, chatID: Telegram().TeamPanenChatID, text: telegramText, parse_mode: "Markdown")
        }
        else {
            let banner = StatusBarNotificationBanner(title: "Error Updating Listrik Record!", style: .danger)
            banner.show()
        }
    }
    
    @IBAction func pemborongPanenButtonPressed(_ sender: Any) {
        print("Pemborong Panen")
        self.performSegue(withIdentifier: "goToPemborong", sender: self)
    }
    @IBAction func bleDeviceButtonPressed(_ sender: Any) {
        print("BLE Device")
        self.performSegue(withIdentifier: "goToBleDiscovery", sender: self)
    }
    @IBAction func sekatButtonPressed(_ sender: Any) {
        let dialogMessage = UIAlertController(title: "Sekat", message: "Pilih sekat", preferredStyle: .alert)
        
        let blower = UIAlertAction(title: "Blower", style: .default, handler: { (action) -> Void in
            self.selectedSekat = "Blower"
            self.sekatButton.setTitle(" Sekat: \(self.selectedSekat)", for: .normal)
            self.sekatButton.setTitleColor(.black, for: .normal)
            self.sekatButton.tintColor = .black
        })
        let tengah = UIAlertAction(title: "Tengah", style: .default, handler: { (action) -> Void in
            self.selectedSekat = "Tengah"
            self.sekatButton.setTitle(" Sekat: \(self.selectedSekat)", for: .normal)
            self.sekatButton.setTitleColor(.black, for: .normal)
            self.sekatButton.tintColor = .black
        })
        let celldeck = UIAlertAction(title: "Celldeck", style: .default, handler: { (action) -> Void in
            self.selectedSekat = "Celldeck"
            self.sekatButton.setTitle(" Sekat: \(self.selectedSekat)", for: .normal)
            self.sekatButton.setTitleColor(.black, for: .normal)
            self.sekatButton.tintColor = .black
        })
        dialogMessage.addAction(blower)
        dialogMessage.addAction(tengah)
        dialogMessage.addAction(celldeck)
        self.present(dialogMessage, animated: true, completion: nil)
    }
    @IBAction func lantaiButtonPressed(_ sender: Any) {
        let dialogMessage = UIAlertController(title: "Lantai", message: "Pilih lantai", preferredStyle: .alert)
        
        for floor in 1...numberOfFloors {
            let floorAction = UIAlertAction(title: "Lantai \(floor)", style: .default, handler: { (action) -> Void in
                self.selectedFloor = floor
                self.lantaiButton.setTitle(" Lantai: \(self.selectedFloor)", for: .normal)
                self.lantaiButton.setTitleColor(.black, for: .normal)
                self.lantaiButton.tintColor = .black
            })
            dialogMessage.addAction(floorAction)
        }
        self.present(dialogMessage, animated: true, completion: nil)
    }
    @IBAction func startButtonPressed(_ sender: Any) {
        if panen.status == "ACC" {
            guard panen.pemborongPanen != "" else {
                let dialogMessage = UIAlertController(title: "Invalid Data", message: "Pemborong Panen belum terpilih", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            guard selectedFloor != 0 else {
                let dialogMessage = UIAlertController(title: "Invalid Data", message: "Lantai belum terpilih", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            guard selectedSekat != "" else {
                let dialogMessage = UIAlertController(title: "Invalid Data", message: "Sekat belum terpilih", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            print("Start")
            let dialogMessage = UIAlertController(title: "Konfirmasi", message: "Mulai Panen?", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
                self.startPanen()
                self.performSegue(withIdentifier: "goToPanenInput", sender: self)
            })
            let cancel = UIAlertAction(title: "Cancel", style: .default, handler: { (action) -> Void in
                print("Cancel button tapped")
            })
            dialogMessage.addAction(cancel)
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
        }
        else if panen.status == "Started" {
            self.performSegue(withIdentifier: "goToPanenInput", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         if segue.destination is PemborongTableViewController
         {
             let vc = segue.destination as? PemborongTableViewController
             vc?.isSelect = true
             vc?.delegate = self
         }
        else if segue.destination is BLEDiscoveryViewController
        {
            let vc = segue.destination as? BLEDiscoveryViewController
            vc?.delegate = self
        }
        else if segue.destination is PanenInputViewController
        {
            let vc = segue.destination as? PanenInputViewController
            vc?.panen = panen
            vc?.selectedBleDevice = selectedBleDevice
            vc?.selectedFloor = selectedFloor
            vc?.selectedSekat = selectedSekat
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.email = email
            vc?.loginClass = loginClass
            vc?.cycleNumber = cycleNumber
            vc?.numberOfFloors = numberOfFloors
        }
    }
}
