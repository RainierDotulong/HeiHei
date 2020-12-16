//
//  VentilationViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 6/29/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import Reachability
import NotificationBannerSwift
import Firebase
import FirebaseFirestore

class VentilationTableViewCell : UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var contentTextField: UITextField!
    @IBOutlet var unitLabel: UILabel!
}

class VentilationTableViewActionCell : UITableViewCell {
    @IBOutlet var actionButton: UIButton!
}

class VentilationViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    //Variables received from previous View Controller
    var farmName : String = ""
    var fullName : String = ""
    var loginClass : String = ""
    var cycleNumber : Int = 0
    var numberOfFloors : Int = 0
    
    var isEdit : Bool = false
    var isDatePick : Bool = false
    
    struct Content {
        let title : String
        let placeholder : String
        let keyboardType : UIKeyboardType
        let unit : String
    }
    
    var sections : [String] = ["Ventilasi", "Inverter", "Pintu Blower", "Pintu Celldeck", "Luar Kandang", "Lantai"]
    var ventilasiData : [Content] = [Content]()
    var inverterData : [Content] = [Content]()
    var environmentData : [Content] = [Content]()
    
    var ventilation : Ventilation = Ventilation(id: "", timestamp: 99999, ventilasiManual: 99999, ventilasiIntermittent: 99999, ventilasiOn: 99999, ventilasiOff: 99999, ventilasiHeater: 99999, inverter: 99999, inverterPinggir: 99999, inverterTengah: 99999, floor: 99999, reporterName: "", pintuBlowerSuhu: 99999, pintuBlowerSpeed: 99999, pintuBlowerRh: 99999, pintuBlowerNh3: 99999, pintuBlowerCo2: 99999, pintuCellDeckSuhu: 99999, pintuCellDeckSpeed: 99999, pintuCellDeckRh: 99999, pintuCellDeckNh3: 99999, pintuCellDeckCo2: 99999, luarKandangSuhu: 99999, luarKandangSpeed: 99999, luarKandangRh: 99999, luarKandangNh3: 99999, luarKandangCo2: 99999)
    
    @IBOutlet var datePickerSwitch: UISwitch!
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var finishButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Disable date pick for non admins
        if loginClass == "superadmin" || loginClass == "administrator" {
            isDatePick = false
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
            sections = ["Ventilasi", "Inverter", "Pintu Blower", "Pintu Celldeck", "Luar Kandang", "Lantai", "Tanggal"]
        }
        else {
            datePickerSwitch.isOn = false
            sections = ["Ventilasi", "Inverter", "Pintu Blower", "Pintu Celldeck", "Luar Kandang", "Lantai"]
        }
        
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        // Add reachability observer
        if let reachability = AppDelegate.sharedAppDelegate()?.reachability
        {
            NotificationCenter.default.addObserver( self, selector: #selector( self.reachabilityChanged ),name: Notification.Name.reachabilityChanged, object: reachability )
        }
        
        let ventilasiManual : Content = Content(title: "Manual", placeholder: "5", keyboardType: .numberPad, unit: "Fan")
        let ventilasiIntermittent : Content = Content(title: "Intermittent", placeholder: "5", keyboardType: .numberPad, unit: "Fan")
        let ventilasiOn : Content = Content(title: "ON", placeholder: "5", keyboardType: .numberPad, unit: "Fan")
        let ventilasiOff : Content = Content(title: "OFF", placeholder: "5", keyboardType: .decimalPad, unit: "Fan")
        let heater : Content = Content(title: "Heater", placeholder: "30", keyboardType: .decimalPad, unit: "°C")
        ventilasiData = [ventilasiManual,ventilasiIntermittent,ventilasiOn,ventilasiOff,heater]
        
        let jumlah : Content = Content(title: "Jumlah", placeholder: "10", keyboardType: .numberPad, unit: "Hz")
        let pinggir : Content = Content(title: "Pinggir", placeholder: "50", keyboardType: .numberPad, unit: "Hz")
        let tengah : Content = Content(title: "Tengah", placeholder: "50", keyboardType: .numberPad, unit: "Hz")
        inverterData = [jumlah,pinggir,tengah]
        
        let suhu : Content = Content(title: "Suhu", placeholder: "30", keyboardType: .decimalPad, unit: "°C")
        let windSpeed : Content = Content(title: "Wind Speed", placeholder: "50", keyboardType: .numberPad, unit: "fpm")
        let rh : Content = Content(title: "RH", placeholder: "60", keyboardType: .numberPad, unit: "%")
        let nh3 : Content = Content(title: "NH3", placeholder: "120", keyboardType: .numberPad, unit: "ppm")
        let co2 : Content = Content(title: "CO2", placeholder: "120", keyboardType: .numberPad, unit: "ppm")
        environmentData = [suhu,windSpeed,rh,nh3,co2]
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    @IBAction func datePickerSwitchValueChanged(_ sender: Any) {
        if isDatePick == false {
            isDatePick = true
            sections = ["Ventilasi", "Inverter", "Pintu Blower", "Pintu Celldeck", "Luar Kandang", "Lantai", "Tanggal"]
            self.tableView.reloadData()
        }
        else {
            isDatePick = false
            sections = ["Ventilasi", "Inverter", "Pintu Blower", "Pintu Celldeck", "Luar Kandang", "Lantai"]
            self.tableView.reloadData()
        }
    }
    
    //MARK: Table view data source
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case "Ventilasi":
            return ventilasiData.count
        case "Inverter":
            return inverterData.count
        case "Pintu Blower":
            return environmentData.count
        case "Pintu Celldeck":
            return environmentData.count
        case "Luar Kandang":
            return environmentData.count
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        func createActionCells(indexPath : IndexPath) -> VentilationTableViewActionCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ventilationActionCell", for: indexPath) as! VentilationTableViewActionCell
            
            switch indexPath.section {
            case 5:
                if ventilation.floor != 99999 {
                    cell.actionButton.setTitle("\(ventilation.floor)", for: .normal)
                    cell.actionButton.setTitleColor(.black, for: .normal)
                    cell.actionButton.tintColor = .black
                }
                else {
                    cell.actionButton.setTitle("Lantai", for: .normal)
                    cell.actionButton.setTitleColor(.link, for: .normal)
                    cell.actionButton.tintColor = .link
                }
            case 6:
                if ventilation.timestamp != 99999 {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .short
                    dateFormatter.timeStyle = .short
                    let stringDate = dateFormatter.string(from: Date(timeIntervalSince1970: ventilation.timestamp))
                    
                    cell.actionButton.setTitle(stringDate, for: .normal)
                    cell.actionButton.setTitleColor(.black, for: .normal)
                    cell.actionButton.tintColor = .black
                }
                else {
                    cell.actionButton.setTitle("Date", for: .normal)
                    cell.actionButton.setTitleColor(.link, for: .normal)
                    cell.actionButton.tintColor = .link
                }
            default:
                print("Unidentified Action Button Pressed")
            }
            cell.actionButton.tag = indexPath.section
            
            return cell
        }
        
        func createCells(indexPath : IndexPath) -> VentilationTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ventilationCell", for: indexPath) as! VentilationTableViewCell
            
            var data : Content = Content(title: "", placeholder: "", keyboardType: .default, unit: "")
            
            switch sections[indexPath.section] {
                case "Ventilasi":
                    data = ventilasiData[indexPath.row]
                    switch ventilasiData[indexPath.row].title {
                    case "Manual":
                        if ventilation.ventilasiManual != 99999 {
                            cell.contentTextField.text = String(ventilation.ventilasiManual)
                        }
                        else {
                            cell.contentTextField.text = ""
                        }
                    case "Intermittent":
                        if ventilation.ventilasiIntermittent != 99999 {
                            cell.contentTextField.text = String(ventilation.ventilasiIntermittent)
                        }
                        else {
                            cell.contentTextField.text = ""
                        }
                    case "ON":
                        if ventilation.ventilasiOn != 99999 {
                            cell.contentTextField.text = String(ventilation.ventilasiOn)
                        }
                        else {
                            cell.contentTextField.text = ""
                        }
                    case "OFF":
                        if ventilation.ventilasiOff != 99999 {
                            cell.contentTextField.text = String(ventilation.ventilasiOff)
                        }
                        else {
                            cell.contentTextField.text = ""
                        }
                    case "Heater":
                        if ventilation.ventilasiHeater != 99999 {
                            cell.contentTextField.text = String(ventilation.ventilasiHeater)
                        }
                        else {
                            cell.contentTextField.text = ""
                        }
                    default:
                        cell.contentTextField.text = ""
                    }
                    cell.contentTextField.addTarget(self, action: #selector(contentTextFieldDidChange), for: .editingChanged)
                case "Inverter":
                    data = inverterData[indexPath.row]
                    switch inverterData[indexPath.row].title {
                    case "Jumlah":
                        if ventilation.inverter != 99999 {
                            cell.contentTextField.text = String(ventilation.inverter)
                        }
                        else {
                            cell.contentTextField.text = ""
                        }
                    case "Pinggir":
                        if ventilation.inverterPinggir != 99999 {
                            cell.contentTextField.text = String(ventilation.inverterPinggir)
                        }
                        else {
                            cell.contentTextField.text = ""
                        }
                    case "Tengah":
                        if ventilation.inverterTengah != 99999 {
                            cell.contentTextField.text = String(ventilation.inverterTengah)
                        }
                        else {
                            cell.contentTextField.text = ""
                        }
                    default:
                        cell.contentTextField.text = ""
                    }
                    cell.contentTextField.addTarget(self, action: #selector(contentTextFieldDidChange), for: .editingChanged)
                case "Pintu Blower":
                    data = environmentData[indexPath.row]
                    switch environmentData[indexPath.row].title {
                    case "Suhu":
                        if ventilation.pintuBlowerSuhu != 99999 {
                            cell.contentTextField.text = String(ventilation.pintuBlowerSuhu)
                        }
                        else {
                            cell.contentTextField.text = ""
                        }
                    case "Wind Speed":
                        if ventilation.pintuBlowerSpeed != 99999 {
                            cell.contentTextField.text = String(ventilation.pintuBlowerSpeed)
                        }
                        else {
                            cell.contentTextField.text = ""
                        }
                    case "RH":
                        if ventilation.pintuBlowerRh != 99999 {
                            cell.contentTextField.text = String(ventilation.pintuBlowerRh)
                        }
                        else {
                            cell.contentTextField.text = ""
                        }
                    case "NH3":
                        if ventilation.pintuBlowerNh3 != 99999 {
                            cell.contentTextField.text = String(ventilation.pintuBlowerNh3)
                        }
                        else {
                            cell.contentTextField.text = ""
                        }
                    case "CO2":
                        if ventilation.pintuBlowerCo2 != 99999 {
                            cell.contentTextField.text = String(ventilation.pintuBlowerCo2)
                        }
                        else {
                            cell.contentTextField.text = ""
                        }
                    default:
                        cell.contentTextField.text = ""
                    }
                    cell.contentTextField.addTarget(self, action: #selector(contentTextFieldDidChange), for: .editingChanged)
                case "Pintu Celldeck":
                    data = environmentData[indexPath.row]
                    switch environmentData[indexPath.row].title {
                    case "Suhu":
                        if ventilation.pintuCellDeckSuhu != 99999 {
                            cell.contentTextField.text = String(ventilation.pintuCellDeckSuhu)
                        }
                        else {
                            cell.contentTextField.text = ""
                        }
                    case "Wind Speed":
                        if ventilation.pintuCellDeckSpeed != 99999 {
                            cell.contentTextField.text = String(ventilation.pintuCellDeckSpeed)
                        }
                        else {
                            cell.contentTextField.text = ""
                        }
                    case "RH":
                        if ventilation.pintuCellDeckRh != 99999 {
                            cell.contentTextField.text = String(ventilation.pintuCellDeckRh)
                        }
                        else {
                            cell.contentTextField.text = ""
                        }
                    case "NH3":
                        if ventilation.pintuCellDeckNh3 != 99999 {
                            cell.contentTextField.text = String(ventilation.pintuCellDeckNh3)
                        }
                        else {
                            cell.contentTextField.text = ""
                        }
                    case "CO2":
                        if ventilation.pintuCellDeckCo2 != 99999 {
                            cell.contentTextField.text = String(ventilation.pintuCellDeckCo2)
                        }
                        else {
                            cell.contentTextField.text = ""
                        }
                    default:
                        cell.contentTextField.text = ""
                    }
                    cell.contentTextField.addTarget(self, action: #selector(contentTextFieldDidChange), for: .editingChanged)
                case "Luar Kandang":
                    data = environmentData[indexPath.row]
                    switch environmentData[indexPath.row].title {
                    case "Suhu":
                        if ventilation.luarKandangSuhu != 99999 {
                            cell.contentTextField.text = String(ventilation.luarKandangSuhu)
                        }
                        else {
                            cell.contentTextField.text = ""
                        }
                    case "Wind Speed":
                        if ventilation.luarKandangSpeed != 99999 {
                            cell.contentTextField.text = String(ventilation.luarKandangSpeed)
                        }
                        else {
                            cell.contentTextField.text = ""
                        }
                    case "RH":
                        if ventilation.luarKandangRh != 99999 {
                            cell.contentTextField.text = String(ventilation.luarKandangRh)
                        }
                        else {
                            cell.contentTextField.text = ""
                        }
                    case "NH3":
                        if ventilation.luarKandangNh3 != 99999 {
                            cell.contentTextField.text = String(ventilation.luarKandangNh3)
                        }
                        else {
                            cell.contentTextField.text = ""
                        }
                    case "CO2":
                        if ventilation.luarKandangCo2 != 99999 {
                            cell.contentTextField.text = String(ventilation.luarKandangCo2)
                        }
                        else {
                            cell.contentTextField.text = ""
                        }
                    default:
                        cell.contentTextField.text = ""
                    }
                    cell.contentTextField.addTarget(self, action: #selector(contentTextFieldDidChange(_:)), for: .editingChanged)
                default:
                    data = environmentData[indexPath.row]
                    cell.contentTextField.addTarget(self, action: #selector(contentTextFieldDidChange), for: .editingChanged)
            }
            cell.titleLabel.text = data.title
            cell.unitLabel.text = data.unit
            cell.contentTextField.placeholder = data.placeholder
            cell.contentTextField.tag = indexPath.section * 10 + indexPath.row
            cell.contentTextField.keyboardType = data.keyboardType
            
            //Add Done BUtton on Keyboard
            let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
            doneToolbar.barStyle = .default

            let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonAction))

            let items = [flexSpace, done]
            doneToolbar.items = items
            doneToolbar.sizeToFit()
            
            cell.contentTextField.inputAccessoryView = doneToolbar
            
            return cell
        }
        
        if sections[indexPath.section] == "Lantai" || sections[indexPath.section] == "Tanggal"{
            return createActionCells(indexPath: indexPath)
        }
        else {
            return createCells(indexPath: indexPath)
        }
    }
    
    @IBAction func actionButtonPressed(_ sender: UIButton) {
        print(sender.tag)
        switch sender.tag {
        case 5:
            print("Floor Picker")
            let dialogMessage = UIAlertController(title: "Lantai", message: "Pilih lantai yang dilaporkan", preferredStyle: .alert)
            
            for floor in 1...numberOfFloors {
                let floorAction = UIAlertAction(title: "Lantai \(floor)", style: .default, handler: { (action) -> Void in
                    
                    self.ventilation.floor = floor
                    self.tableView.reloadData()

                })
                dialogMessage.addAction(floorAction)
            }
            self.present(dialogMessage, animated: true, completion: nil)
        case 6:
            print("Date Picker")
            let datePicker = UIDatePicker()
            if ventilation.timestamp != 99999 {
                datePicker.date = Date(timeIntervalSince1970: ventilation.timestamp)
            }
            let alert = UIAlertController(title: "\n\n\n\n\n\n\n\n\n\n\n", message: nil, preferredStyle: .actionSheet)
            alert.view.addSubview(datePicker)
            
            datePicker.snp.makeConstraints { (make) in
                make.centerX.equalTo(alert.view)
                make.top.equalTo(alert.view).offset(8)
            }
            
            let ok = UIAlertAction(title: "OK", style: .default) { (action) in
                self.ventilation.timestamp = datePicker.date.timeIntervalSince1970
                self.tableView.reloadData()
            }
            
            let cancel = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            
            alert.addAction(ok)
            alert.addAction(cancel)
            alert.popoverPresentationController?.sourceView = self.view
            alert.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            alert.popoverPresentationController?.permittedArrowDirections = []
            present(alert, animated: true, completion: nil)
        default:
            print("Unidentified Action Button Pressed")
        }
    }
    @IBAction func finishButtonPressed(_ sender: Any) {
        
        if isDatePick == false && isEdit == false {
            ventilation.timestamp = Date().timeIntervalSince1970
        }
        
        ventilation.reporterName = fullName
        
        guard ventilation.timestamp != 99999 else {
            let dialogMessage = UIAlertController(title: "Invalid Timestamp", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard ventilation.ventilasiManual != 99999 else {
            let dialogMessage = UIAlertController(title: "Invalid Ventlasi Manual", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard ventilation.ventilasiIntermittent != 99999 else {
            let dialogMessage = UIAlertController(title: "Invalid Ventlasi Intermittent", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard ventilation.ventilasiOn != 99999 else {
            let dialogMessage = UIAlertController(title: "Invalid Ventlasi ON", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard ventilation.ventilasiOff != 99999 else {
            let dialogMessage = UIAlertController(title: "Invalid Ventlasi OFF", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard ventilation.ventilasiHeater != 99999 else {
            let dialogMessage = UIAlertController(title: "Invalid Ventlasi Heater", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard ventilation.inverter != 99999 else {
            let dialogMessage = UIAlertController(title: "Invalid Inverter", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard ventilation.inverterPinggir != 99999 else {
            let dialogMessage = UIAlertController(title: "Invalid Inverter Pinggir", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard ventilation.inverterTengah != 99999 else {
            let dialogMessage = UIAlertController(title: "Invalid Inverter Tengah", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard ventilation.floor != 99999 else {
            let dialogMessage = UIAlertController(title: "Invalid Floor", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard ventilation.reporterName != "" else {
            let dialogMessage = UIAlertController(title: "Invalid Reporter Name", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard ventilation.pintuBlowerSuhu != 99999 else {
            let dialogMessage = UIAlertController(title: "Invalid Pintu Blower Suhu", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard ventilation.pintuBlowerSpeed != 99999 else {
            let dialogMessage = UIAlertController(title: "Invalid Pintu Blower Speed", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard ventilation.pintuBlowerRh != 99999 else {
            let dialogMessage = UIAlertController(title: "Invalid Pintu Blower RH", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard ventilation.pintuBlowerNh3 != 99999 else {
            let dialogMessage = UIAlertController(title: "Invalid Pintu Blower NH3", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard ventilation.pintuBlowerCo2 != 99999 else {
            let dialogMessage = UIAlertController(title: "Invalid Pintu Blower CO2", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard ventilation.pintuCellDeckSuhu != 99999 else {
            let dialogMessage = UIAlertController(title: "Invalid Pintu Celldeck Suhu", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard ventilation.pintuCellDeckSpeed != 99999 else {
            let dialogMessage = UIAlertController(title: "Invalid Pintu Celldeck Speed", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard ventilation.pintuCellDeckRh != 99999 else {
            let dialogMessage = UIAlertController(title: "Invalid Pintu Celldeck RH", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard ventilation.pintuCellDeckNh3 != 99999 else {
            let dialogMessage = UIAlertController(title: "Invalid Pintu Celldeck NH3", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard ventilation.pintuCellDeckCo2 != 99999 else {
            let dialogMessage = UIAlertController(title: "Invalid Pintu Celldeck CO2", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard ventilation.luarKandangSuhu != 99999 else {
            let dialogMessage = UIAlertController(title: "Invalid Luar Kandang Suhu", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard ventilation.luarKandangSpeed != 99999 else {
            let dialogMessage = UIAlertController(title: "Invalid Luar Kandang Speed", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard ventilation.luarKandangRh != 99999 else {
            let dialogMessage = UIAlertController(title: "Invalid Luar Kandang RH", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard ventilation.luarKandangNh3 != 99999 else {
            let dialogMessage = UIAlertController(title: "Invalid Luar Kandang NH3", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard ventilation.luarKandangCo2 != 99999 else {
            let dialogMessage = UIAlertController(title: "Invalid Luar Kandang CO2", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        print("Finish")
        
        if isEdit {
            let isUpdateRecordSuccess = Ventilation.update(farmName: farmName, cycleNumber: cycleNumber, ventilation: ventilation)
            if isUpdateRecordSuccess {
                let banner = StatusBarNotificationBanner(title: "Ventilation Record Updated!", style: .success)
                banner.show()
                let VentilationChangeNotification = Notification.Name("ventilationChanged")
                NotificationCenter.default.post(name: VentilationChangeNotification, object: nil)
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short
                let stringDate = dateFormatter.string(from: Date(timeIntervalSince1970: ventilation.timestamp))
                
                //Send Telegram Message
                var telegramText = "*VENTILATION REPORT - LT.\(ventilation.floor) UPDATED*\n----------------------------\n"
                telegramText.append("*Date: \(stringDate)*\n")
                telegramText.append("*Ventilasi*\n")
                telegramText.append("Manual: \(ventilation.ventilasiManual), Intermittent: \(ventilation.ventilasiIntermittent)\n")
                telegramText.append("ON: \(ventilation.ventilasiOn), OFF: \(ventilation.ventilasiOff)\n")
                telegramText.append("Inverter: \(ventilation.inverter) (Pinggir: \(ventilation.inverterPinggir) Hz, Tengah: \(ventilation.inverterTengah) Hz)\n")
                telegramText.append("Heater: \(ventilation.ventilasiHeater) °C\n\n")
                
                telegramText.append("*Pintu Blower*\n")
                telegramText.append("Suhu: \(ventilation.pintuBlowerSuhu) °C, RH: \(ventilation.pintuBlowerRh) %\n")
                telegramText.append("Wind Speed: \(ventilation.pintuBlowerSpeed) FPM\n")
                telegramText.append("Ammonia (NH3): \(ventilation.pintuBlowerRh) ppm\n")
                telegramText.append("Carbon Dioxide (CO2): \(ventilation.pintuBlowerCo2) ppm\n\n")
                
                telegramText.append("*Pintu Celldeck*\n")
                telegramText.append("Suhu: \(ventilation.pintuCellDeckSuhu) °C, RH: \(ventilation.pintuCellDeckRh) %\n")
                telegramText.append("Wind Speed: \(ventilation.pintuCellDeckSpeed) FPM\n")
                telegramText.append("Ammonia (NH3): \(ventilation.pintuCellDeckNh3) ppm\n")
                telegramText.append("Carbon Dioxide (CO2): \(ventilation.pintuCellDeckCo2) ppm\n\n")
                
                telegramText.append("*Luar Kandang*\n")
                telegramText.append("Suhu: \(ventilation.luarKandangSuhu) °C, RH: \(ventilation.luarKandangRh) %\n")
                telegramText.append("Wind Speed: \(ventilation.luarKandangSpeed) FPM\n")
                telegramText.append("Ammonia (NH3): \(ventilation.luarKandangNh3) ppm\n")
                telegramText.append("Carbon Dioxide (CO2): \(ventilation.luarKandangCo2) ppm\n\n")
                
                telegramText.append("Pelapor: \(fullName)\n")
                
                switch self.farmName {
                    case "pinantik":
                        Telegram().postTelegramMessage(botToken: Telegram().ChickenAppBotToken, chatID: Telegram().LaporanCFPinantikChatID, text: telegramText, parse_mode: "Markdown")
                    case "kejayan":
                        Telegram().postTelegramMessage(botToken: Telegram().ChickenAppBotToken, chatID: Telegram().LaporanCFKejayanChatID, text: telegramText, parse_mode: "Markdown")
                    default:
                        Telegram().postTelegramMessage(botToken: Telegram().ChickenAppBotToken, chatID: Telegram().LaporanCFLewihChatID, text: telegramText, parse_mode: "Markdown")
                    
                }
                
                navigationController?.popViewController(animated: true)
            }
            else {
                let banner = StatusBarNotificationBanner(title: "Error Uploading Ventilation Record!", style: .danger)
                banner.show()
            }
        }
        else {
            let isCreateRecordSuccess = Ventilation.create(farmName: farmName, cycleNumber: cycleNumber, ventilation: ventilation)
            if isCreateRecordSuccess {
                let banner = StatusBarNotificationBanner(title: "Ventilation Record Uploaded!", style: .success)
                banner.show()
                let VentilationChangeNotification = Notification.Name("ventilationChanged")
                NotificationCenter.default.post(name: VentilationChangeNotification, object: nil)
                
                //Send Telegram Message
                var telegramText = "*VENTILATION REPORT - LT.\(ventilation.floor)*\n----------------------------\n"
                telegramText.append("*Ventilasi*\n")
                telegramText.append("Manual: \(ventilation.ventilasiManual), Intermittent: \(ventilation.ventilasiIntermittent)\n")
                telegramText.append("ON: \(ventilation.ventilasiOn), OFF: \(ventilation.ventilasiOff)\n")
                telegramText.append("Inverter: \(ventilation.inverter)\n")
                telegramText.append("Inverter Pinggir: \(ventilation.inverterPinggir) Hz\n")
                telegramText.append("Inverter Tengah: \(ventilation.inverterTengah) Hz\n")
                telegramText.append("Heater: \(ventilation.ventilasiHeater) °C\n\n")
                
                telegramText.append("*Pintu Blower*\n")
                telegramText.append("Suhu: \(ventilation.pintuBlowerSuhu) °C\n")
                telegramText.append("Wind Speed: \(ventilation.pintuBlowerSpeed) FPM\n")
                telegramText.append("Humidity (RH): \(ventilation.pintuBlowerRh) %\n")
                telegramText.append("Ammonia (NH3): \(ventilation.pintuBlowerRh) ppm\n")
                telegramText.append("Carbon Dioxide (CO2): \(ventilation.pintuBlowerCo2) ppm\n\n")
                
                telegramText.append("*Pintu Celldeck*\n")
                telegramText.append("Suhu: \(ventilation.pintuCellDeckSuhu) °C\n")
                telegramText.append("Wind Speed: \(ventilation.pintuCellDeckSpeed) FPM\n")
                telegramText.append("Humidity (RH): \(ventilation.pintuCellDeckRh) %\n")
                telegramText.append("Ammonia (NH3): \(ventilation.pintuCellDeckNh3) ppm\n")
                telegramText.append("Carbon Dioxide (CO2): \(ventilation.pintuCellDeckCo2) ppm\n\n")
                
                telegramText.append("*Luar Kandang*\n")
                telegramText.append("Suhu: \(ventilation.luarKandangSuhu) °C\n")
                telegramText.append("Wind Speed: \(ventilation.luarKandangSpeed) FPM\n")
                telegramText.append("Humidity (RH): \(ventilation.luarKandangRh) %\n")
                telegramText.append("Ammonia (NH3): \(ventilation.luarKandangNh3) ppm\n")
                telegramText.append("Carbon Dioxide (CO2): \(ventilation.luarKandangCo2) ppm\n\n")
                
                telegramText.append("Pelapor: \(fullName)\n")
                
                switch self.farmName {
                    case "pinantik":
                        Telegram().postTelegramMessage(botToken: Telegram().ChickenAppBotToken, chatID: Telegram().LaporanCFPinantikChatID, text: telegramText, parse_mode: "Markdown")
                    case "kejayan":
                        Telegram().postTelegramMessage(botToken: Telegram().ChickenAppBotToken, chatID: Telegram().LaporanCFKejayanChatID, text: telegramText, parse_mode: "Markdown")
                    default:
                        Telegram().postTelegramMessage(botToken: Telegram().ChickenAppBotToken, chatID: Telegram().LaporanCFLewihChatID, text: telegramText, parse_mode: "Markdown")
                    
                }
                
                navigationController?.popViewController(animated: true)
            }
            else {
                let banner = StatusBarNotificationBanner(title: "Error Uploading Ventilation Record!", style: .danger)
                banner.show()
            }
        }
    }
    
    @objc func contentTextFieldDidChange(_ textField: UITextField) {
        let section = textField.tag / 10 % 10
        let row = textField.tag % 10
        
        switch section {
        case 0:
            //Ventilasi Section
            switch ventilasiData[row].title {
            case "Manual":
                guard Int(textField.text ?? "99999") ?? 99999 != 99999 else {
                    print("Invalid Manual Ventilation")
                    ventilation.ventilasiManual = 99999
                    return
                }
                ventilation.ventilasiManual = Int(textField.text!)!
            case "Intermittent":
                guard Int(textField.text ?? "99999") ?? 99999 != 99999 else {
                    print("Invalid Intermittent Ventilation")
                    ventilation.ventilasiIntermittent = 99999
                    return
                }
                ventilation.ventilasiIntermittent = Int(textField.text!)!
            case "ON":
                guard Int(textField.text ?? "99999") ?? 99999 != 99999 else {
                    print("Invalid ON Ventilation")
                    ventilation.ventilasiOn = 99999
                    return
                }
                ventilation.ventilasiOn = Int(textField.text!)!
            case "OFF":
                guard Int(textField.text ?? "99999") ?? 99999 != 99999 else {
                    print("Invalid OFF Ventilation")
                    ventilation.ventilasiOff = 99999
                    return
                }
                ventilation.ventilasiOff = Int(textField.text!)!
            default:
                guard Float(textField.text ?? "99999") ?? 99999 != 99999 else {
                    print("Invalid Heater Celcius")
                    ventilation.ventilasiHeater = 99999
                    return
                }
                ventilation.ventilasiHeater = Float(textField.text!.replacingOccurrences(of: ",", with: "."))!
            }
        case 1:
            //Inverter Section
            switch inverterData[row].title {
            case "Jumlah":
                guard Int(textField.text ?? "99999") ?? 99999 != 99999 else {
                    print("Invalid Manual Ventilation")
                    ventilation.inverter = 99999
                    return
                }
                ventilation.inverter = Int(textField.text!)!
            case "Pinggir":
                guard Int(textField.text ?? "99999") ?? 99999 != 99999 else {
                    print("Invalid Intermittent Ventilation")
                    ventilation.inverterPinggir = 99999
                    return
                }
                ventilation.inverterPinggir = Int(textField.text!)!
            default:
                guard Int(textField.text ?? "99999") ?? 99999 != 99999 else {
                    print("Invalid Inverter Tengah")
                    ventilation.inverterTengah = 99999
                    return
                }
                ventilation.inverterTengah = Int(textField.text!)!
            }
        case 2:
            //Pintu Blower Section
            switch environmentData[row].title {
            case "Suhu":
                guard Float(textField.text?.replacingOccurrences(of: ",", with: ".") ?? "99999") ?? 99999 != 99999 else {
                    print("Invalid Pintu Blower Suhu")
                    ventilation.pintuBlowerSuhu = 99999
                    return
                }
                ventilation.pintuBlowerSuhu = Float(textField.text!.replacingOccurrences(of: ",", with: "."))!
            case "Wind Speed":
                guard Int(textField.text ?? "99999") ?? 99999 != 99999 else {
                    print("Invalid Pintu Blower Speed")
                    ventilation.pintuBlowerSpeed = 99999
                    return
                }
                ventilation.pintuBlowerSpeed = Int(textField.text!)!
            case "RH":
                guard Int(textField.text ?? "99999") ?? 99999 != 99999 else {
                    print("Invalid Pintu Blower RH")
                    ventilation.pintuBlowerRh = 99999
                    return
                }
                ventilation.pintuBlowerRh = Int(textField.text!)!
            case "NH3":
                guard Int(textField.text ?? "99999") ?? 99999 != 99999 else {
                    print("Invalid Pintu Blower NH3")
                    ventilation.pintuBlowerNh3 = 99999
                    return
                }
                ventilation.pintuBlowerNh3 = Int(textField.text!)!
            default:
                guard Int(textField.text ?? "99999") ?? 99999 != 99999 else {
                    print("Invalid Pintu Blower CO2")
                    ventilation.pintuBlowerCo2 = 99999
                    return
                }
                ventilation.pintuBlowerCo2 = Int(textField.text!)!
            }
        case 3:
            //Pintu Celldeck Section
            switch environmentData[row].title {
            case "Suhu":
                guard Float(textField.text?.replacingOccurrences(of: ",", with: ".") ?? "99999") ?? 99999 != 99999 else {
                    print("Invalid Pintu Celldeck Suhu")
                    ventilation.pintuCellDeckSuhu = 99999
                    return
                }
                ventilation.pintuCellDeckSuhu = Float(textField.text!.replacingOccurrences(of: ",", with: "."))!
            case "Wind Speed":
                guard Int(textField.text ?? "99999") ?? 99999 != 99999 else {
                    print("Invalid Pintu Celldeck Speed")
                    return
                }
                ventilation.pintuCellDeckSpeed = Int(textField.text!)!
            case "RH":
                guard Int(textField.text ?? "99999") ?? 99999 != 99999 else {
                    print("Invalid Pintu Celldeck RH")
                    ventilation.pintuCellDeckRh = 99999
                    return
                }
                ventilation.pintuCellDeckRh = Int(textField.text!)!
            case "NH3":
                guard Int(textField.text ?? "99999") ?? 99999 != 99999 else {
                    print("Invalid Pintu Celldeck NH3")
                    ventilation.pintuCellDeckNh3 = 99999
                    return
                }
                ventilation.pintuCellDeckNh3 = Int(textField.text!)!
            default:
                guard Int(textField.text ?? "99999") ?? 99999 != 99999 else {
                    print("Invalid Pintu Celldeck CO2")
                    ventilation.pintuCellDeckCo2 = 99999
                    return
                }
                ventilation.pintuCellDeckCo2 = Int(textField.text!)!
            }
        default:
            //Luar Kandang Section
            switch environmentData[row].title {
            case "Suhu":
                guard Float(textField.text?.replacingOccurrences(of: ",", with: ".") ?? "99999") ?? 99999 != 99999 else {
                    print("Invalid Luar Kandang Suhu")
                    ventilation.luarKandangSuhu = 99999
                    return
                }
                ventilation.luarKandangSuhu = Float(textField.text!.replacingOccurrences(of: ",", with: "."))!
            case "Wind Speed":
                guard Int(textField.text ?? "99999") ?? 99999 != 99999 else {
                    print("Invalid Luar Kandang Speed")
                    ventilation.luarKandangSpeed = 99999
                    return
                }
                ventilation.luarKandangSpeed = Int(textField.text!)!
            case "RH":
                guard Int(textField.text ?? "99999") ?? 99999 != 99999 else {
                    print("Invalid Luar Kandang RH")
                    ventilation.luarKandangRh = 99999
                    return
                }
                ventilation.luarKandangRh = Int(textField.text!)!
            case "NH3":
                guard Int(textField.text ?? "99999") ?? 99999 != 99999 else {
                    print("Invalid Luar Kandang NH3")
                    ventilation.luarKandangNh3 = 99999
                    return
                }
                ventilation.luarKandangNh3 = Int(textField.text!)!
            default:
                guard Int(textField.text ?? "99999") ?? 99999 != 99999 else {
                    print("Invalid Luar Kandang CO2")
                    ventilation.luarKandangCo2 = 99999
                    return
                }
                ventilation.luarKandangCo2 = Int(textField.text!)!
            }
        }
    }
    
    @objc func doneButtonAction(){
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
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
