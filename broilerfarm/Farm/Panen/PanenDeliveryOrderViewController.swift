//
//  PanenDeliveryOrderViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/24/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import QuickLook

class PanenDeliveryOrderViewController: UIViewController, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    
    //Initalize Variables passed from previous VC
    var farmName : String = ""
    var fullName : String = ""
    var cycleNumber : Int  = 0
    var panen : Panen = Panen(id: "", creationTimestamp: 0, isChecked: false, hargaPerKG: 0, mulaiMuatTimestamp: 0, selesaiMuatTimestamp: 0, jumlahKGDO: 0, namaPerusahaan: "", alamatPerusahaan: "", metodePembayaran: "", namaSopir: "", noKendaraaan: "", noSopir: "", pembuatDO: "", rangeBB: "", rangeBawah: 0, rangeAtas: 0, status: "", pengambilanTimestamp: 0, timestamps: [Double](), lantai: [Int](), jumlah: [Int](), isSubtract: [Bool](), isVoided: [Bool](), sekat: [String](), tara: [Float](), berat: [Float](), pemborongPanen: "", penimbang: "", accBy: "")
    
    @IBOutlet var pdfView: UIView!
    @IBOutlet var barButton: UIBarButtonItem!
    
    //Header
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var tanggalDoLabel: UILabel!
    @IBOutlet var alamatLabel: UILabel!
    
    @IBOutlet var perusahaanContentLabel: UILabel!
    @IBOutlet var noDeliveryOrderContentLabel: UILabel!
    @IBOutlet var tanggalPengambilanContentLabel: UILabel!
    @IBOutlet var rangeBBContentLabel: UILabel!
    @IBOutlet var jumlahEkorContentLabel: UILabel!
    @IBOutlet var totalTonaseContentLabel: UILabel!
    
    @IBOutlet var noKendaraanContentLabel: UILabel!
    @IBOutlet var namaSopirContentLabel: UILabel!
    @IBOutlet var noTelpSopirContentLabel: UILabel!
    @IBOutlet var jamMulaiMuatContentLabel: UILabel!
    
    @IBOutlet var metodePembayaranContentLabel: UILabel!
    
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    var filePath : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        titleLabel.text = "Delivery Order"
        if farmName.lowercased() == "pinantik" {
            alamatLabel.text = "Jln Raya Perusahaan, 31 A, Karanglo, Malang."
        }
        else if farmName.lowercased() == "kejayan" {
            alamatLabel.text = "Dusun Monjo, Desa Ketangirejo, Kec Kejayan, Pasuruan."
        }
        else if farmName.lowercased() == "lewih" {
            alamatLabel.text = "Dusun Sumberejo, Desa Sumberejo, Kec Poncokusumo, Malang."
        }
        else {
            alamatLabel.text = farmName + ", Lowoksoro, Mangliawan, Malang"
        }
        var date = Date(timeIntervalSince1970: panen.creationTimestamp )
        var dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let creationDate = dateFormatter.string(from: date)
        tanggalDoLabel.text = creationDate
        
        perusahaanContentLabel.text = ": \(panen.namaPerusahaan)"
        noDeliveryOrderContentLabel.text = ": \(farmName.prefix(1).uppercased())\(cycleNumber)-\(Int(panen.creationTimestamp))"
        
        date = Date(timeIntervalSince1970: panen.pengambilanTimestamp )
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        let tanggalPengambilan = dateFormatter.string(from: date)
        tanggalPengambilanContentLabel.text = ": \(tanggalPengambilan)"
        
        rangeBBContentLabel.text = ": \(panen.rangeBB)"
        
        let estimatedJumlahEkor = panen.jumlahKGDO / ((panen.rangeBawah + panen.rangeAtas)/2)
        jumlahEkorContentLabel.text = ": \(Int(estimatedJumlahEkor))"
        totalTonaseContentLabel.text = ": \(panen.jumlahKGDO) KG"
        
        noKendaraanContentLabel.text = ": \(panen.noKendaraaan)"
        namaSopirContentLabel.text = ": \(panen.namaSopir)"
        noTelpSopirContentLabel.text = ": \(panen.noSopir)"
        date = Date(timeIntervalSince1970: panen.pengambilanTimestamp )
        dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        let jamPengambilan = dateFormatter.string(from: date)
        jamMulaiMuatContentLabel.text = ": \(jamPengambilan)"
        
        metodePembayaranContentLabel.text = ": \(panen.metodePembayaran)"
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    @IBAction func barButtonPressed(_ sender: Any) {
        print("Create")
        createPDF()
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
        let pdfPath = docDirectoryPath.appendingPathComponent("\(farmName.prefix(1).uppercased())\(cycleNumber)-\(Int(panen.creationTimestamp))DO.pdf")
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
    }
}
