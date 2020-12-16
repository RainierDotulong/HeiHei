//
//  PanenEditViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/19/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import NotificationBannerSwift
import Firebase
import FirebaseFirestore
import SVProgressHUD

class LabelTableViewCell : UITableViewCell {
    //labelCell
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var contentLabel: UILabel!
}

class TextFieldTableViewCell :UITableViewCell {
    //textFieldCell
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var contentTextField: UITextField!
}

class PanenEditViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, sendPerusahaanData {
    
    //Initalize Variables passed from previous VC
    var farmName : String = ""
    var fullName : String = ""
    var email : String = ""
    var loginClass : String = ""
    var cycleNumber : Int  = 0
    var numberOfFloors : Int  = 0
    var panen : Panen = Panen(id: "", creationTimestamp: 0, isChecked: false, hargaPerKG: 0, mulaiMuatTimestamp: 0, selesaiMuatTimestamp: 0, jumlahKGDO: 0, namaPerusahaan: "", alamatPerusahaan: "", metodePembayaran: "", namaSopir: "", noKendaraaan: "", noSopir: "", pembuatDO: "", rangeBB: "", rangeBawah: 0, rangeAtas: 0, status: "", pengambilanTimestamp: 0, timestamps: [Double](), lantai: [Int](), jumlah: [Int](), isSubtract: [Bool](), isVoided: [Bool](), sekat: [String](), tara: [Float](), berat: [Float](), pemborongPanen: "", penimbang: "", accBy: "")
    var isEdit : Bool = false
    
    var sections : [String] = ["Customer", "Order"]
    var customerData : [Content] = [Content]()
    var orderData : [Content] = [Content]()
    
    //Range BB
    var afkirBawah : Float = 0
    var afkirAtas : Float = 0
    var kecilBawah : Float = 0
    var kecilAtas : Float = 0
    var mediumBawah : Float = 0
    var mediumAtas : Float = 0
    var jumboBawah : Float = 0
    var jumboAtas : Float = 0
    
    struct Content {
        let title : String
        var content : String
        let cellType : String
        let placeholder : String
        let keyboardType : UIKeyboardType
        let capitalization : UITextAutocapitalizationType
    }
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var finishButton: UIButton!
    
    var hargaPerKg : Content = Content(title: "Harga/KG", content: "", cellType: "textField", placeholder: "10000", keyboardType: .numberPad, capitalization: .words)
    var pengambilanTimestamp : Content = Content(title: "Tanggal Pengambilan", content: "", cellType: "label", placeholder: "", keyboardType: .default, capitalization: .none)
    var perusahaan: Content = Content(title: "Perusahaan", content: "", cellType: "label", placeholder: "", keyboardType: .default, capitalization: .words)
    var metodePembayaran: Content = Content(title: "Metode Pembayaran", content: "", cellType: "label", placeholder: "", keyboardType: .default, capitalization: .none)
    var namaSopir : Content = Content(title: "Nama Sopir", content: "", cellType: "textField", placeholder: "Budi", keyboardType: .default, capitalization: .words)
    var noKendaraan : Content = Content(title: "Nomor Kendaraan", content: "", cellType: "textField", placeholder: "N 762 AJ", keyboardType: .default, capitalization: .allCharacters)
    var noSopir : Content = Content(title: "Nomor Telp. Sopir", content: "", cellType: "textField", placeholder: "08183736361", keyboardType: .phonePad, capitalization: .none)
    var jumlahKGDO : Content = Content(title: "Jumlah KG", content: "", cellType: "textField", placeholder: "2000", keyboardType: .decimalPad, capitalization: .none)
    var hargaPerKG : Content = Content(title: "Harga/KG", content: "", cellType: "textField", placeholder: "10000", keyboardType: .numberPad, capitalization: .none)
    var rangeBB : Content = Content(title: "Range BB", content: "", cellType: "label", placeholder: "0.0-0.0 KG", keyboardType: .default, capitalization: .none)
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        // Remove seperator lines from empty cells
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        customerData = [perusahaan, metodePembayaran, namaSopir, noSopir , noKendaraan]
        orderData = [jumlahKGDO, hargaPerKG, rangeBB, pengambilanTimestamp]
        
        if isEdit {
            customerData[0].content = panen.namaPerusahaan
            customerData[1].content = panen.metodePembayaran
            customerData[2].content = panen.namaSopir
            customerData[3].content = panen.noSopir
            customerData[4].content = panen.noKendaraaan
            orderData[0].content = String(panen.jumlahKGDO)
            orderData[1].content = String(panen.hargaPerKG)
            orderData[2].content = panen.rangeBB
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: Date.init(timeIntervalSince1970: panen.pengambilanTimestamp))
            orderData[3].content = stringDate
            finishButton.setTitle("Update", for: .normal)
        }
        else {
            panen = Panen(id: "", creationTimestamp: 0, isChecked: false, hargaPerKG: 0, mulaiMuatTimestamp: 0, selesaiMuatTimestamp: 0, jumlahKGDO: 0, namaPerusahaan: "", alamatPerusahaan: "", metodePembayaran: "", namaSopir: "", noKendaraaan: "", noSopir: "", pembuatDO: "", rangeBB: "", rangeBawah: 0, rangeAtas: 0, status: "", pengambilanTimestamp: 0, timestamps: [Double](), lantai: [Int](), jumlah: [Int](), isSubtract: [Bool](), isVoided: [Bool](), sekat: [String](), tara: [Float](), berat: [Float](), pemborongPanen: "", penimbang: "", accBy: "")
            finishButton.setTitle("Create", for: .normal)
        }
        
        getRangeBBData()
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    func getRangeBBData() {
        //Get Cycle Number from Firebase
        let rangeBBRef = Firestore.firestore().collection("panenSettings").document("rangeBB")
        
        SVProgressHUD.show()
        rangeBBRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let dataDescription = document.data()
                
                self.afkirBawah = (dataDescription!["afkirBawah"] as! NSNumber).floatValue
                self.afkirAtas = (dataDescription!["afkirAtas"] as! NSNumber).floatValue
                self.kecilBawah = (dataDescription!["kecilBawah"] as! NSNumber).floatValue
                self.kecilAtas = (dataDescription!["kecilAtas"] as! NSNumber).floatValue
                self.mediumBawah = (dataDescription!["mediumBawah"] as! NSNumber).floatValue
                self.mediumAtas = (dataDescription!["mediumAtas"] as! NSNumber).floatValue
                self.jumboBawah = (dataDescription!["jumboBawah"] as! NSNumber).floatValue
                self.jumboAtas = (dataDescription!["jumboAtas"] as! NSNumber).floatValue
                
                SVProgressHUD.dismiss()
                
            } else {
                SVProgressHUD.dismiss()
                let dialogMessage = UIAlertController(title: "Current Range BB  Document does not exist", message: "Please Contact Administrator or Create a New One", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func finishButtonPressed(_ sender: Any) {
        //Validate
        guard self.panen.namaPerusahaan != "" else {
            let dialogMessage = UIAlertController(title: "Invalid Data", message: "Nama Perusahaan Belum Terisi", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard self.panen.alamatPerusahaan != "" else {
            let dialogMessage = UIAlertController(title: "Invalid Data", message: "Alamat Perusahaan Belum Terisi", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard self.panen.metodePembayaran != "" else {
            let dialogMessage = UIAlertController(title: "Invalid Data", message: "Metode Pembayaran Belum Terisi", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard self.panen.namaSopir != "" else {
            let dialogMessage = UIAlertController(title: "Invalid Data", message: "Nama Sopir Belum Terisi", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard self.panen.noSopir != "" else {
            let dialogMessage = UIAlertController(title: "Invalid Data", message: "Nomor Sopir Belum Terisi", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard self.panen.noKendaraaan != "" else {
            let dialogMessage = UIAlertController(title: "Invalid Data", message: "Nomor Kendaraan Belum Terisi", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard self.panen.jumlahKGDO != 0 else {
            let dialogMessage = UIAlertController(title: "Invalid Data", message: "Jumlah KG Order Belum Terisi", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard self.panen.hargaPerKG != 0 else {
            let dialogMessage = UIAlertController(title: "Invalid Data", message: "Harga/KG Order Belum Terisi", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard self.panen.rangeBB != "" else {
            let dialogMessage = UIAlertController(title: "Invalid Data", message: "Range BB Order Belum Terisi", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard self.panen.pengambilanTimestamp != 0 else {
            let dialogMessage = UIAlertController(title: "Invalid Data", message: "Tanggal Pengambilan Order Belum Terisi", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        if isEdit {
            print("Finish Update")
            let isPanenUpdateSuccess = Panen.update(farmName: farmName, cycleNumber: cycleNumber, panen: panen)
            
            if isPanenUpdateSuccess {
                let banner = StatusBarNotificationBanner(title: "Panen Record Updated!", style: .success)
                banner.show()
                let PanenChangeNotification = Notification.Name("panenChanged")
                NotificationCenter.default.post(name: PanenChangeNotification, object: nil)
                self.navigationController?.popViewController(animated: true)
            }
            else {
                let banner = StatusBarNotificationBanner(title: "Error Updating Panen Record!", style: .danger)
                banner.show()
            }
        }
        else {
            print("Finish Create")
            //Set Values for other Variables
            panen.creationTimestamp = Date().timeIntervalSince1970
            panen.pembuatDO = fullName
            panen.status = "Created"
            let isPanenCreateSuccess = Panen.create(farmName: farmName, cycleNumber: cycleNumber, panen: panen)
            
            if isPanenCreateSuccess {
                let banner = StatusBarNotificationBanner(title: "Panen Record Uploaded!", style: .success)
                banner.show()
                let PanenChangeNotification = Notification.Name("panenChanged")
                NotificationCenter.default.post(name: PanenChangeNotification, object: nil)
                self.navigationController?.popViewController(animated: true)
            }
            else {
                let banner = StatusBarNotificationBanner(title: "Error Creating Panen Record!", style: .danger)
                banner.show()
            }
        }
    }
    
    func perusahaanDataReceived(selectedPerusahaan: Perusahaan) {
        customerData[0].content = selectedPerusahaan.companyName
        self.panen.namaPerusahaan = selectedPerusahaan.companyName
        self.panen.alamatPerusahaan = selectedPerusahaan.companyAddress
        tableView.reloadData()
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
        case "Customer":
            return customerData.count
        case "Order":
            return orderData.count
        default:
            return 1
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        func createLabelCell(data : Content) -> LabelTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "labelCell", for: indexPath) as! LabelTableViewCell
            
            cell.titleLabel.text = data.title
            if data.content == "" {
                cell.contentLabel.text = "Tap to Edit"
                cell.contentLabel.textColor = .systemBlue
            }
            else {
                cell.contentLabel.text = data.content
                cell.contentLabel.textColor = .black
            }
            
            return cell
        }
        
        func createTextFieldCell(data : Content) -> TextFieldTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "textFieldCell", for: indexPath) as! TextFieldTableViewCell
            
            cell.titleLabel.text = data.title
            cell.contentTextField.text = data.content
            cell.contentTextField.placeholder = data.placeholder
            cell.contentTextField.keyboardType = data.keyboardType
            cell.contentTextField.autocapitalizationType = data.capitalization
            cell.contentTextField.addTarget(self, action: #selector(contentTextFieldDidChange), for: .editingChanged)
            cell.contentTextField.tag = indexPath.section * 10 + indexPath.row
            
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
        
        switch sections[indexPath.section] {
        case "Customer":
            switch customerData[indexPath.row].cellType {
                case "label":
                    return createLabelCell(data: customerData[indexPath.row])
                case "textField":
                    return createTextFieldCell(data: customerData[indexPath.row])
                default:
                    print("Unknown Cell Type")
                    return createTextFieldCell(data: customerData[indexPath.row])
            }
        case "Order":
            switch orderData[indexPath.row].cellType {
            case "label":
                return createLabelCell(data: orderData[indexPath.row])
            case "textField":
                return createTextFieldCell(data: orderData[indexPath.row])
            default:
                print("Unknown Cell Type")
                return createTextFieldCell(data: orderData[indexPath.row])
            }
        default:
            print("Unknown Section")
            return createTextFieldCell(data: orderData[indexPath.row])
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch sections[indexPath.section] {
        case "Customer":
            switch customerData[indexPath.row].title {
            case "Perusahaan":
                self.performSegue(withIdentifier: "goToPerusahaan", sender: self)
            case "Metode Pembayaran":
                let dialogMessage = UIAlertController(title: "Lantai", message: "Pilih lantai yang dilaporkan", preferredStyle: .alert)
                
                let metodePembayaranData = ["Lunas","DP","Bayar ditempat sebelum muat","Bayar ditempat setelah muat","Bayar setelah panen"]
                for metodePembayaran in metodePembayaranData {
                    let action = UIAlertAction(title: metodePembayaran, style: .default, handler: { (action) -> Void in
                        
                        self.customerData[1].content = metodePembayaran
                        self.panen.metodePembayaran = metodePembayaran
                        self.tableView.reloadData()
                    })
                    dialogMessage.addAction(action)
                }
                self.present(dialogMessage, animated: true, completion: nil)
            default:
                print("Unknown Customer Title")
            }
        case "Order":
            switch orderData[indexPath.row].title {
            case "Range BB":
                print("Range BB")
                guard afkirBawah != 0 else {
                    print("No Range Data Available")
                    let dialogMessage = UIAlertController(title: "No Range Data Available", message: "Please Contact Administrator", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                        print("Ok button tapped")
                    })
                    dialogMessage.addAction(ok)
                    self.present(dialogMessage, animated: true, completion: nil)
                    return
                }
                
                let dialogMessage = UIAlertController(title: "Range BB", message: "Pilih Range BB Order", preferredStyle: .alert)
                
                let afkir = UIAlertAction(title: "Afkir (\(afkirBawah) - \(afkirAtas)) KG", style: .default, handler: { (action) -> Void in
                    
                    self.orderData[2].content = "Afkir (\(self.afkirBawah) - \(self.afkirAtas)) KG"
                    self.panen.rangeBB = "Afkir (\(self.afkirBawah) - \(self.afkirAtas)) KG"
                    self.panen.rangeBawah = self.afkirBawah
                    self.panen.rangeAtas = self.afkirAtas
                    self.tableView.reloadData()
                })
                
                let kecil = UIAlertAction(title: "Kecil (\(kecilBawah) - \(kecilAtas)) KG", style: .default, handler: { (action) -> Void in
                    
                    self.orderData[2].content = "Kecil (\(self.kecilBawah) - \(self.kecilAtas)) KG"
                    self.panen.rangeBB = "Kecil (\(self.kecilBawah) - \(self.kecilAtas)) KG"
                    self.panen.rangeBawah = self.kecilBawah
                    self.panen.rangeAtas = self.kecilAtas
                    self.tableView.reloadData()
                })
                
                let medium = UIAlertAction(title: "Medium (\(mediumBawah) - \(mediumAtas)) KG", style: .default, handler: { (action) -> Void in
                    
                    self.orderData[2].content = "Medium (\(self.mediumBawah) - \(self.mediumAtas)) KG"
                    self.panen.rangeBB = "Medium (\(self.mediumBawah) - \(self.mediumAtas)) KG"
                    self.panen.rangeBawah = self.mediumBawah
                    self.panen.rangeAtas = self.mediumAtas
                    self.tableView.reloadData()
                })
                
                let jumbo = UIAlertAction(title: "Jumbo (\(jumboBawah) - \(jumboAtas)) KG", style: .default, handler: { (action) -> Void in
                    
                    self.orderData[2].content = "Jumbo (\(self.jumboBawah) - \(self.jumboAtas)) KG"
                    self.panen.rangeBB = "Jumbo (\(self.jumboBawah) - \(self.jumboAtas)) KG"
                    self.panen.rangeBawah = self.jumboBawah
                    self.panen.rangeAtas = self.jumboAtas
                    self.tableView.reloadData()
                })
                
                dialogMessage.addAction(afkir)
                dialogMessage.addAction(kecil)
                dialogMessage.addAction(medium)
                dialogMessage.addAction(jumbo)
                
                self.present(dialogMessage, animated: true, completion: nil)
            case "Tanggal Pengambilan":
                print("Tanggal Pengambilan")
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
                    self.orderData[3].content = "\(stringDate)"
                    self.panen.pengambilanTimestamp = datePicker.date.timeIntervalSince1970
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
                print("Unknown Order Title")
            }
        default:
            print("Unknown Section")
        }
    }
    
    @objc func contentTextFieldDidChange(_ textField: UITextField) {
        let section = textField.tag / 10 % 10
        let row = textField.tag % 10
        
        switch sections[section] {
        case "Customer":
            self.customerData[row].content = textField.text ?? ""
            switch customerData[row].title {
            case "Nama Sopir":
                self.panen.namaSopir = textField.text ?? ""
            case "Nomor Telp. Sopir":
                self.panen.noSopir = textField.text ?? ""
            case "Nomor Kendaraan":
                self.panen.noKendaraaan = textField.text ?? ""
            default:
                print("Unknown Customer Text field")
            }
        case "Order":
            self.orderData[row].content = textField.text ?? ""
            switch orderData[row].title {
            case "Jumlah KG":
                self.panen.jumlahKGDO = Float(textField.text ?? "0") ?? 0
            case "Harga/KG":
                self.panen.hargaPerKG = Int(textField.text ?? "0") ?? 0
            default:
                print("Unknown Order Text field")
            }
        default:
            print("Unknown Text Field Section")
        }
    }
    
    @objc func doneButtonAction(){
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PerusahaanTableViewController
        {
            let vc = segue.destination as? PerusahaanTableViewController
            vc?.isPick = true
            vc?.delegate = self
        }
    }
}
