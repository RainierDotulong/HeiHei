//
//  PanenInvoiceViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/27/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import SVProgressHUD
import QuickLook

class PanenInvoiceViewController: UIViewController, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    
    var farmName : String = ""
    var fullName : String = ""
    var cycleNumber : Int  = 0
    var numberOfFloors : Int  = 0
    var panen : Panen = Panen(id: "", creationTimestamp: 0, isChecked: false, hargaPerKG: 0, mulaiMuatTimestamp: 0, selesaiMuatTimestamp: 0, jumlahKGDO: 0, namaPerusahaan: "", alamatPerusahaan: "", metodePembayaran: "", namaSopir: "", noKendaraaan: "", noSopir: "", pembuatDO: "", rangeBB: "", rangeBawah: 0, rangeAtas: 0, status: "", pengambilanTimestamp: 0, timestamps: [Double](), lantai: [Int](), jumlah: [Int](), isSubtract: [Bool](), isVoided: [Bool](), sekat: [String](), tara: [Float](), berat: [Float](), pemborongPanen: "", penimbang: "", accBy: "")
    
    var isProforma : Bool = false

    @IBOutlet var navItem: UINavigationItem!
    @IBOutlet var pdfView: UIView!
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var invoiceNumberLabel: UILabel!
    @IBOutlet var tanggalLabel: UILabel!
    @IBOutlet var perusahaanLabel: UILabel!
    @IBOutlet var alamatPerusahaanLabel: UILabel!
    @IBOutlet var nomorSuratJalanDOLabel: UILabel!
    @IBOutlet var nomorSuratJalanDOContentLabel: UILabel!
    @IBOutlet var rangeBBContentLabel: UILabel!
    @IBOutlet var jumlahContentLabel: UILabel!
    @IBOutlet var namaSopirContentLabel: UILabel!
    @IBOutlet var nomorTelpSopirContentLabel: UILabel!
    @IBOutlet var noKendaraanContentLabel: UILabel!
    @IBOutlet var jamPengambilanMulaiMuatLabel: UILabel!
    @IBOutlet var jamPengambilanMulaiMuatContentLabel: UILabel!
    
    @IBOutlet var jenisAyamLabel: UILabel!
    @IBOutlet var nettoLabel: UILabel!
    @IBOutlet var hargaPerKgLabel: UILabel!
    @IBOutlet var totalLabel: UILabel!
    
    @IBOutlet var jenisAyamContentLabel: UILabel!
    @IBOutlet var nettoContentLabel: UILabel!
    @IBOutlet var hargaPerKgContentLabel: UILabel!
    @IBOutlet var totalContentLabel: UILabel!
    
    @IBOutlet var noteLabel1: UILabel!
    @IBOutlet var noteLabel2: UILabel!
    
    @IBOutlet var namaBankContentLabel: UILabel!
    @IBOutlet var atasNameContentLabel: UILabel!
    @IBOutlet var nomorRekeningContentLabel: UILabel!
    
    @IBOutlet var createButton: UIBarButtonItem!
    
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    var filePath : String = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        getRekeningData()
        
        let date = Date(timeIntervalSince1970: panen.selesaiMuatTimestamp )
        var dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let stringDate = dateFormatter.string(from: date)
        tanggalLabel.text = stringDate
        
        print(panen.jumlah)
        if panen.jumlah.isEmpty {
            isProforma = true
        }
        else {
            isProforma = false
        }
        
        perusahaanLabel.text = "\(panen.namaPerusahaan)"
        alamatPerusahaanLabel.text = "\(panen.alamatPerusahaan)"
        nomorSuratJalanDOContentLabel.text = ": \(self.farmName.prefix(1).uppercased())\(self.cycleNumber)-\(Int(panen.creationTimestamp))"
        rangeBBContentLabel.text = ": \(panen.rangeBB)"
        jenisAyamContentLabel.text = "BROILER"
        
        namaSopirContentLabel.text = ": \(panen.namaSopir)"
        nomorTelpSopirContentLabel.text = ": \(panen.noSopir)"
        noKendaraanContentLabel.text = ": \(panen.noKendaraaan)"
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let formattedHargaPerKG = numberFormatter.string(from: NSNumber(value:panen.hargaPerKG))
        
        hargaPerKgContentLabel.text = "Rp.\(formattedHargaPerKG!)"
        if isProforma {
            titleLabel.text = "PROFORMA INVOICE"
            nomorSuratJalanDOLabel.text = "Nomor Delivery Order"
            jamPengambilanMulaiMuatLabel.text = "Jam Pengambilan"
            let date = Date(timeIntervalSince1970: panen.pengambilanTimestamp )
            dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: date)
            jamPengambilanMulaiMuatContentLabel.text = ": \(stringDate)"
            nettoContentLabel.text = "\(String(format: "%.2f", panen.jumlahKGDO)) KG"
            let total = panen.jumlahKGDO * Float(panen.hargaPerKG)
            let formattedTotal = numberFormatter.string(from: NSNumber(value:Int(total)))
            totalContentLabel.text = "Rp.\(formattedTotal!)"
            let totalEkor = panen.jumlahKGDO/((panen.rangeBawah + panen.rangeAtas)/2)
            nomorSuratJalanDOContentLabel.text = ": \(Int(totalEkor)) Ekor"
            noteLabel1.text = "* Detil muatan ini merupakan estimasi kurang lebihnya."
            noteLabel2.text = "Realisasi hasil muatan akan berada pada recording panen dan surat jalan."
        }
        else {
            titleLabel.text = "INVOICE"
            nomorSuratJalanDOLabel.text = "Nomor Surat Jalan"
            jamPengambilanMulaiMuatLabel.text = "Jam Selesai Muat"
            let date = Date(timeIntervalSince1970: panen.selesaiMuatTimestamp )
            dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: date)
            jamPengambilanMulaiMuatContentLabel.text = ": \(stringDate)"
            var validJumlah : [Int] = [Int]()
            var validBerat : [Float] = [Float]()
            var validTara : [Float] = [Float]()
            for i in 0..<panen.isVoided.count {
                if panen.isVoided[i] == false && panen.isSubtract[i] == false {
                    validJumlah.append(panen.jumlah[i])
                    validBerat.append(panen.berat[i])
                    validTara.append(panen.tara[i])
                }
            }
            let totalEkor = validJumlah.reduce(0,+)
            let netto = validBerat.reduce(0,+) - validTara.reduce(0,+)
            let averageBB = netto/Float(totalEkor)
            
            noteLabel1.text = "* Average BW: \(String(format: "%.2f", averageBB)) KG"
            noteLabel2.text = ""
            jumlahContentLabel.text = ": \(totalEkor) Ekor"
            nettoContentLabel.text = "\(String(format: "%.2f", netto)) KG"
            
            let total = netto * Float(panen.hargaPerKG)
            let formattedTotal = numberFormatter.string(from: NSNumber(value:Int(total)))
            
            totalContentLabel.text = "Rp.\(formattedTotal!)"
        }
        jenisAyamLabel.layer.borderColor = UIColor.black.cgColor;
        nettoLabel.layer.borderColor = UIColor.black.cgColor;
        hargaPerKgLabel.layer.borderColor = UIColor.black.cgColor;
        totalLabel.layer.borderColor = UIColor.black.cgColor;
        jenisAyamContentLabel.layer.borderColor = UIColor.black.cgColor;
        nettoContentLabel.layer.borderColor = UIColor.black.cgColor;
        hargaPerKgContentLabel.layer.borderColor = UIColor.black.cgColor;
        totalContentLabel.layer.borderColor = UIColor.black.cgColor;
        
        jenisAyamLabel.layer.borderWidth = 1.0;
        nettoLabel.layer.borderWidth = 1.0;
        hargaPerKgLabel.layer.borderWidth = 1.0;
        totalLabel.layer.borderWidth = 1.0;
        jenisAyamContentLabel.layer.borderWidth = 1.0;
        nettoContentLabel.layer.borderWidth = 1.0;
        hargaPerKgContentLabel.layer.borderWidth = 1.0;
        totalContentLabel.layer.borderWidth = 1.0;
        
    }
    
    @IBAction func createButtonPressed(_ sender: Any) {
        print("Create")
        createPDF ()
    }
    
    func getRekeningData() {
        //Get Cycle Number from Firebase
        let rangeBBRef = Firestore.firestore().collection("panenSettings").document("rekening")
        
        SVProgressHUD.show()
        createButton.isEnabled = false
        rangeBBRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let dataDescription = document.data()
                
                self.atasNameContentLabel.text = dataDescription!["nama"] as? String
                self.namaBankContentLabel.text = dataDescription!["bank"] as? String
                self.nomorRekeningContentLabel.text = dataDescription!["nomor"] as? String
                SVProgressHUD.dismiss()
                self.createButton.isEnabled = true
                
            } else {
                SVProgressHUD.dismiss()
                self.createButton.isEnabled = true
                let dialogMessage = UIAlertController(title: "Current Rekening Document does not exist", message: "Please Contact Administrator or Create a New One", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
            }
        }
    }
    
    func createPDF () {
        filePath = exportAsPdfFromView()
        let previewController = QLPreviewController()
        previewController.dataSource = self
        previewController.delegate = self
        present(previewController, animated: true)
    }
    
    // Export pdf from Save pdf in drectory and return pdf file path
    func exportAsPdfFromView() -> String {
        
        let pdfPageFrame = self.pdfView.bounds
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, pdfPageFrame, nil)
        UIGraphicsBeginPDFPageWithInfo(pdfPageFrame, nil)
        guard let pdfContext = UIGraphicsGetCurrentContext() else { return "" }
        self.pdfView.layer.render(in: pdfContext)
        UIGraphicsEndPDFContext()
        return self.saveViewPdf(data: pdfData)
        
    }
    
    // Save pdf file in document directory
    func saveViewPdf(data: NSMutableData) -> String {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docDirectoryPath = paths[0]
        var pdfPath = docDirectoryPath
        if isProforma {
            pdfPath = docDirectoryPath.appendingPathComponent("\(farmName.prefix(1).uppercased())\(cycleNumber)-\(Int(panen.creationTimestamp))PINV.pdf")
        }
        else {
            pdfPath = docDirectoryPath.appendingPathComponent("\(farmName.prefix(1).uppercased())\(cycleNumber)-\(Int(panen.creationTimestamp))INV.pdf")
        }
        if data.write(to: pdfPath, atomically: true) {
            return pdfPath.path
        } else {
            return ""
        }
    }
    
    //QLPreviewController Methods
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return URL(fileURLWithPath: filePath) as QLPreviewItem
    }
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        print("Preview Controller Dismissed")
        self.navigationController?.popToRootViewController(animated: true)
    }
}
