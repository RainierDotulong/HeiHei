//
//  PanenInputViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/26/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import CoreBluetooth
import MobileCoreServices
import CoreData
import CoreBluetooth
import NotificationBannerSwift

class PanenInputTableViewCell : UITableViewCell {
    //panenInputCell
    @IBOutlet var waktuLabel: UILabel!
    @IBOutlet var jumlahLabel: UILabel!
    @IBOutlet var beratLabel: UILabel!
    @IBOutlet var taraLabel: UILabel!
    @IBOutlet var sekatLabel: UILabel!
    @IBOutlet var lantaiLabel: UILabel!
}

class PanenInputViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, sendBleData  {
    
    var farmName : String = ""
    var fullName : String = ""
    var email : String = ""
    var loginClass : String = ""
    var cycleNumber : Int  = 0
    var numberOfFloors : Int  = 0
    var panen : Panen = Panen(id: "", creationTimestamp: 0, isChecked: false, hargaPerKG: 0, mulaiMuatTimestamp: 0, selesaiMuatTimestamp: 0, jumlahKGDO: 0, namaPerusahaan: "", alamatPerusahaan: "", metodePembayaran: "", namaSopir: "", noKendaraaan: "", noSopir: "", pembuatDO: "", rangeBB: "", rangeBawah: 0, rangeAtas: 0, status: "", pengambilanTimestamp: 0, timestamps: [Double](), lantai: [Int](), jumlah: [Int](), isSubtract: [Bool](), isVoided: [Bool](), sekat: [String](), tara: [Float](), berat: [Float](), pemborongPanen: "", penimbang: "", accBy: "")
    var selectedBleDevice : CBPeripheral?
    var selectedFloor : Int = 0
    var selectedSekat : String = ""
    
    //User Input Data
    var lantai : [Int] = [Int]()
    var jumlah : [Int] = [Int]()
    var berat : [Float] = [Float]()
    var tara : [Float] = [Float]()
    var sekat : [String] = [String]()
    var timestamps : [Double] = [Double]()
    var isSubtract : [Bool] = [Bool]()
    var isVoided : [Bool] = [Bool]()
    
    struct tableViewData {
        var lantai : String
        var jumlah : String
        var berat : String
        var tara : String
        var sekat : String
        var waktu : String
        var isVoid : Bool
        var isSubtract : Bool
    }
    
    var tableViewDataArray : [tableViewData] = [tableViewData]()
    
    @IBOutlet var sekatButton: UIButton!
    @IBOutlet var lantaiButton: UIButton!
    
    @IBOutlet var jumlahTextField: UITextField!
    @IBOutlet var taraTextField: UITextField!
    @IBOutlet var beratTextField: UITextField!
    
    @IBOutlet var rekamButton: UIButton!

    @IBOutlet var tambahButton: UIButton!
    @IBOutlet var suratJalanButton: UIButton!
    
    @IBOutlet var scaleReadingLabel: UILabel!
    var scaleValue : Float = 0
    
    @IBOutlet var kgKurangLabel: UILabel!
    @IBOutlet var averageBBLabel: UILabel!
    @IBOutlet var totalLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    
    var centralManager: CBCentralManager!
    var weightScalePeripheral: CBPeripheral!
    
    @IBOutlet var doLabel: UILabel!
    @IBOutlet var numberBarButton: UIBarButtonItem!
    @IBOutlet var backButton: UIBarButtonItem!
    @IBOutlet var bleButton: UIBarButtonItem!
    @IBOutlet var navItem: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        // Remove seperator lines from empty cells
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        addDoneButtonOnKeyboard()
        
        doLabel.text = "\(panen.jumlahKGDO) KG - \(panen.rangeBB)"
        
        self.sekatButton.setTitle(" Sekat: \(self.selectedSekat)", for: .normal)
        self.sekatButton.setTitleColor(.black, for: .normal)
        self.sekatButton.tintColor = .black
        
        self.lantaiButton.setTitle(" Lantai: \(self.selectedFloor)", for: .normal)
        self.lantaiButton.setTitleColor(.black, for: .normal)
        self.lantaiButton.tintColor = .black
        
        let tableHeader : tableViewData = tableViewData(lantai: "Lantai", jumlah: "Jumlah", berat: "Berat", tara: "Tara", sekat: "Sekat", waktu: "Waktu", isVoid: false, isSubtract: false)
        tableViewDataArray = [tableHeader]
        self.tableView.reloadData()
        
        if selectedBleDevice != nil {
            print("BLE Selected")
            self.centralManager = CBCentralManager(delegate: self, queue: nil)
        }
        
        self.reloadViewData()
    }
    
    func bleDataReceived(ble: CBPeripheral) {
        selectedBleDevice = ble
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        let dialogMessage = UIAlertController(title: "Konfirmasi", message: "Kembali ke menu awal? Data yang sudah di input akan hilang!", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            self.navigationController?.navigationBar.barTintColor = .none
            if self.selectedBleDevice != nil {
                self.centralManager.stopScan()
            }
            self.navigationController?.popViewController(animated: true)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: { (action) -> Void in
            print("Cancel button tapped")
        })
        dialogMessage.addAction(cancel)
        dialogMessage.addAction(ok)
        self.present(dialogMessage, animated: true, completion: nil)
    }
    
    @IBAction func bleButtonPressed(_ sender: Any) {
        let dialogMessage = UIAlertController(title: "Konfirmasi", message: "Ganti Perangkan BLE Timbangan?", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            if self.selectedBleDevice != nil {
                 self.centralManager.stopScan()
            }
            self.performSegue(withIdentifier: "goToBleDiscovery", sender: self)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: { (action) -> Void in
            print("Cancel button tapped")
        })
        dialogMessage.addAction(cancel)
        dialogMessage.addAction(ok)
        self.present(dialogMessage, animated: true, completion: nil)
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
    
    @IBAction func rekamButtonPressed(_ sender: Any) {
        print("Rekam")
        beratTextField.text = String(format: "%.2f", scaleValue)
    }
    
    @IBAction func tambahButtonPressed(_ sender: Any) {
        guard selectedSekat != "" else {
            let dialogMessage = UIAlertController(title: "Invalid Sekat", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard selectedFloor != 0 else {
            let dialogMessage = UIAlertController(title: "Invalid Lantai", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard Int(jumlahTextField.text ?? "0") ?? 0 != 0 else {
            let dialogMessage = UIAlertController(title: "Invalid Jumlah (Ekor)", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard Float(taraTextField.text ?? "0") ?? 0 != 0 else {
            let dialogMessage = UIAlertController(title: "Invalid Tara (KG)", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard Float(beratTextField.text ?? "0") ?? 0 != 0 else {
            let dialogMessage = UIAlertController(title: "Invalid Berat (KG)", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard Float(beratTextField.text ?? "0") ?? 0 > Float(taraTextField.text ?? "0") ?? 0 else {
            let dialogMessage = UIAlertController(title: "Invalid Berat (KG)", message: "Berat lebih kecil dari Tara", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        let currentTotals = PanenFunctions().calculateTotals(data: panen)
        let nettoToBeAdded = Float(beratTextField.text!)! - Float(taraTextField.text!)!
        guard currentTotals.netto + nettoToBeAdded <= panen.jumlahKGDO + 1 else {
            let dialogMessage = UIAlertController(title: "Over DO", message: "DO Hanya \(String(format:"%.2f",panen.jumlahKGDO)) KG", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        //Append to Panen Data
        panen.lantai.append(selectedFloor)
        panen.jumlah.append(Int(jumlahTextField.text!)!)
        panen.berat.append(Float(beratTextField.text!)!)
        panen.tara.append(Float(taraTextField.text!)!)
        panen.sekat.append(selectedSekat)
        panen.timestamps.append(Date().timeIntervalSince1970)
        panen.isSubtract.append(false)
        panen.isVoided.append(false)
        
        reloadViewData()
        
        updatePanenDocument()
        
        beratTextField.text = ""
    }
    
    func reloadViewData() {
        //Set TableView Data to Panen Data
        tableViewDataArray.removeAll(keepingCapacity: false)
        let tableHeader : tableViewData = tableViewData(lantai: "Lantai", jumlah: "Jumlah", berat: "Berat", tara: "Tara", sekat: "Sekat", waktu: "Waktu", isVoid: false, isSubtract: false)
        tableViewDataArray.append(tableHeader)
        for i in 0..<panen.jumlah.count {
            let date = Date(timeIntervalSince1970: panen.timestamps[i])
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: date)
            
            let tableData : tableViewData = tableViewData(lantai: "\(panen.lantai[i])", jumlah: "\(panen.jumlah[i])", berat: "\(String(format: "%.2f", panen.berat[i]))", tara: "\(String(format: "%.2f", panen.tara[i]))", sekat: "\(panen.sekat[i])", waktu: stringDate, isVoid: panen.isVoided[i], isSubtract: panen.isSubtract[i])
            tableViewDataArray.append(tableData)
        }
        self.tableView.reloadData()
        
        //Update Labels
        let panenTotals = PanenFunctions().calculateTotals(data: panen)
        numberBarButton.title = "\(panenTotals.validEntries)"
        kgKurangLabel.text = "KG Kurang: \(String(format: "%.2f", panen.jumlahKGDO - panenTotals.netto)) KG"
        averageBBLabel.text = "Average BB: \(String(format: "%.2f", panenTotals.averageBB)) KG"
        totalLabel.text = "Total Ekor: \(panenTotals.totalEkor) - Netto: \(String(format: "%.2f", panenTotals.netto)) KG"
    }
    
    func updatePanenDocument() {
        let isPanenUpdateSuccess = Panen.update(farmName: farmName, cycleNumber: cycleNumber, panen: panen)
        
        if isPanenUpdateSuccess {
            print("Panen Record Update Success")
        }
        else {
            let banner = StatusBarNotificationBanner(title: "Error Updating Panen Record!", style: .danger)
            banner.show()
        }
    }
    
    @IBAction func suratJalanButtonPressed(_ sender: Any) {
        print("Surat jalan")
        guard panen.jumlah.isEmpty == false else {
            let dialogMessage = UIAlertController(title: "Invalid Data", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        let dialogMessage = UIAlertController(title: "Konfirmasi", message: "Selesai Panen & Cetak Surat Jalan?", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            self.navigationController?.navigationBar.barTintColor = .none
            self.panen.selesaiMuatTimestamp = Date().timeIntervalSince1970
            self.performSegue(withIdentifier: "goToSuratJalan", sender: self)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: { (action) -> Void in
            print("Cancel button tapped")
        })
        dialogMessage.addAction(cancel)
        dialogMessage.addAction(ok)
        self.present(dialogMessage, animated: true, completion: nil)
    }
    
    //MARK: Table View Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewDataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        func createCell(data : tableViewData) -> PanenInputTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "panenInputCell", for: indexPath) as! PanenInputTableViewCell
            
            cell.waktuLabel.text = data.waktu
            cell.jumlahLabel.text = data.jumlah
            cell.beratLabel.text = data.berat
            cell.taraLabel.text = data.tara
            cell.sekatLabel.text = data.sekat
            cell.lantaiLabel.text = data.lantai
            
            if data.isVoid {
                cell.waktuLabel.text = "VOID"
            }
            
            if data.isSubtract {
                cell.waktuLabel.text = "RETUR"
            }
            
            return cell
        }
        return createCell(data: tableViewDataArray[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let void = UIContextualAction(style: .normal, title: "Void") {  (contextualAction, view, boolValue) in
            print("VOID \(self.tableViewDataArray[indexPath.row].berat)")
            let dialogMessage = UIAlertController(title: "Konfirmasi", message: "VOID \(self.tableViewDataArray[indexPath.row].berat) KG?", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
                self.panen.isVoided[indexPath.row - 1] = true
                self.updatePanenDocument()
                self.reloadViewData()
            })
            let cancel = UIAlertAction(title: "Cancel", style: .default, handler: { (action) -> Void in
                print("Cancel button tapped")
            })
            dialogMessage.addAction(cancel)
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
        }
        void.image = UIImage(systemName: "xmark.circle.fill")
        void.backgroundColor = .systemRed
        
        let retur = UIContextualAction(style: .normal, title: "Retur") {  (contextualAction, view, boolValue) in
            print("RETUR \(self.tableViewDataArray[indexPath.row].berat)")
            let dialogMessage = UIAlertController(title: "Konfirmasi", message: "RETUR \(self.tableViewDataArray[indexPath.row].berat) KG?", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
                self.panen.isSubtract[indexPath.row - 1] = true
                self.updatePanenDocument()
                self.reloadViewData()
            })
            let cancel = UIAlertAction(title: "Cancel", style: .default, handler: { (action) -> Void in
                print("Cancel button tapped")
            })
            dialogMessage.addAction(cancel)
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
        }
        retur.image = UIImage(systemName: "arrow.up.arrow.down.circle.fill")
        retur.backgroundColor = .systemBlue
        
        if indexPath.row == 0 {
            return UISwipeActionsConfiguration(actions: [])
        }
        else {
            if self.panen.isVoided[indexPath.row-1] || self.panen.isSubtract[indexPath.row-1] {
                return UISwipeActionsConfiguration(actions: [])
            }
            else {
                return UISwipeActionsConfiguration(actions: [void,retur])
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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
        taraTextField.inputAccessoryView = doneToolbar
        beratTextField.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction(){
        jumlahTextField.resignFirstResponder()
        taraTextField.resignFirstResponder()
        beratTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        jumlahTextField.resignFirstResponder()
        taraTextField.resignFirstResponder()
        beratTextField.resignFirstResponder()
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PanenSuratJalanViewController
        {
            let vc = segue.destination as? PanenSuratJalanViewController
            vc?.panen = panen
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.email = email
            vc?.loginClass = loginClass
            vc?.cycleNumber = cycleNumber
            vc?.numberOfFloors = numberOfFloors
        }
        else if segue.destination is BLEDiscoveryViewController
        {
            let vc = segue.destination as? BLEDiscoveryViewController
            vc?.delegate = self
        }
    }
}

extension PanenInputViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
        case .poweredOn:
            print("central.state is .poweredOn")
            centralManager.scanForPeripherals(withServices: nil)
        default :
            print("central.state is .uncategorized")
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                      advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral)
        if peripheral.name == selectedBleDevice?.name {
            weightScalePeripheral = peripheral
            weightScalePeripheral.delegate = self
            centralManager.stopScan()
            print("Peripheral Found!")
            centralManager.connect(weightScalePeripheral)
        }
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Peripheral Connected!")
        navItem.title = "Panen - \(weightScalePeripheral.name ?? "")"
        let banner = StatusBarNotificationBanner(title: "BLE Scale Connected", style: .info)
        banner.show()
        backButton.tintColor = .black
        numberBarButton.tintColor = .black
        bleButton.tintColor = .black
        navigationController?.navigationBar.barTintColor = .systemBlue
        weightScalePeripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        navItem.title = "Panen"
        scaleReadingLabel.text = "000.00 KG"
        scaleValue = 0
        let banner = StatusBarNotificationBanner(title: "BLE Scale Disconnected!", style: .danger)
        banner.show()
        navigationController?.navigationBar.barTintColor = .systemRed
        centralManager.scanForPeripherals(withServices: nil)
        print("Peripheral Disconnected")
    }
}

extension PanenInputViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            print(service)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            print(characteristic)
            if characteristic.properties.contains(.read) {
                print("\(characteristic.uuid): properties contains .read")
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.notify) {
                print("\(characteristic.uuid): properties contains .notify")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
        case CBUUID(string: "FFE1"):
            let byteArray = [UInt8](characteristic.value ?? Data())
            print(byteArray)
            if byteArray.count == 12 {
                let digitOne = (byteArray[4] - 48)
                var digitTwo : UInt8 = 0
                var digitThree : UInt8 = 0
                var digitFour : Float = 0
                if byteArray[3] != 32 {
                    digitTwo = (byteArray[3] - 48) * 10
                }
                if byteArray[2] != 32 {
                    digitThree = (byteArray[2] - 48) * 100
                }
                if byteArray[1] != 32 {
                    digitFour = Float((byteArray[1] - 48)) * 1000
                }
                let tenths = Float((byteArray[6] - 48)) / 10
                let hundredths = Float((byteArray[7] - 48)) / 100
                let value = Float(digitOne) + Float(digitTwo) + Float(digitThree) + digitFour + Float(tenths) + Float(hundredths)
                print(value)
                scaleValue = value
                scaleReadingLabel.text = "\(String(format: "%.2f",value)) KG"
            }
        default:
          print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
}
