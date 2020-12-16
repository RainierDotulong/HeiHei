//
//  PanenSuratJalanViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/26/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import QuickLook
import Firebase
import FirebaseFirestore
import FirebaseStorage
import NotificationBannerSwift

class PanenSuratJalanViewController: UIViewController, QLPreviewControllerDataSource, QLPreviewControllerDelegate, sendToDeliveryPermitVC {
    
    var farmName : String = ""
    var fullName : String = ""
    var email : String = ""
    var loginClass : String = ""
    var cycleNumber : Int  = 0
    var numberOfFloors : Int  = 0
    var panen : Panen = Panen(id: "", creationTimestamp: 0, isChecked: false, hargaPerKG: 0, mulaiMuatTimestamp: 0, selesaiMuatTimestamp: 0, jumlahKGDO: 0, namaPerusahaan: "", alamatPerusahaan: "", metodePembayaran: "", namaSopir: "", noKendaraaan: "", noSopir: "", pembuatDO: "", rangeBB: "", rangeBawah: 0, rangeAtas: 0, status: "", pengambilanTimestamp: 0, timestamps: [Double](), lantai: [Int](), jumlah: [Int](), isSubtract: [Bool](), isVoided: [Bool](), sekat: [String](), tara: [Float](), berat: [Float](), pemborongPanen: "", penimbang: "", accBy: "")

    @IBOutlet var uploadButton: UIBarButtonItem!
    @IBOutlet var pdfView: UIView!
    
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    var filePath : String = ""
    var exportFlag : Bool  = false
    var csvPath : URL = URL(string: "https://www.globalxtreme.net")!
    
    @IBOutlet var titleLabel: UnderlinedLabel!
    @IBOutlet var tanggalLabel: UILabel!
    @IBOutlet var alamatLabel: UILabel!
    
    @IBOutlet var kepadaContentLabel: UILabel!
    @IBOutlet var alamatContentLabel: UILabel!
    @IBOutlet var nomorPanenContentLabel: UILabel!
    @IBOutlet var namaSopirContentLabel: UILabel!
    @IBOutlet var noTelpSopirContentLabel: UILabel!
    @IBOutlet var nomorPolisiContentLabel: UILabel!
    @IBOutlet var jamSelesaiMuatContentLabel: UILabel!
    @IBOutlet var averageBwContentLabel: UILabel!
    
    @IBOutlet var jenisAyamLabel: UILabel!
    @IBOutlet var jenisAyamContentLabel: UILabel!
    @IBOutlet var jumlahEkorLabel: UILabel!
    @IBOutlet var jumlahEkorContentLabel: UILabel!
    @IBOutlet var beratNettoLabel: UILabel!
    @IBOutlet var beratNettoContentLabel: UILabel!
    
    @IBOutlet var kepalaKandangImageView: UIImageView!
    @IBOutlet var kepalaKandangLabel: UILabel!
    @IBOutlet var teamPanenImageView: UIImageView!
    @IBOutlet var teamPanenLabel: UILabel!
    @IBOutlet var sopirImageView: UIImageView!
    @IBOutlet var sopirLabel: UILabel!
    
    @IBOutlet var backButton: UIBarButtonItem!
    var signatureIdentifier : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        titleLabel.text = "Surat Jalan Pengambilan Ayam"
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
        
        let date = Date(timeIntervalSince1970: panen.selesaiMuatTimestamp )
        var dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let stringDate = dateFormatter.string(from: date)
        tanggalLabel.text = stringDate
        
        kepadaContentLabel.text = ": \(panen.namaPerusahaan)"
        alamatContentLabel.text = ": \(panen.alamatPerusahaan)"
        nomorPanenContentLabel.text = ": \(self.farmName.prefix(1).uppercased())\(self.cycleNumber)-\(Int(panen.creationTimestamp))"
        namaSopirContentLabel.text = ": \(panen.namaSopir)"
        noTelpSopirContentLabel.text = ": \(panen.noSopir)"
        nomorPolisiContentLabel.text = ": \(panen.noKendaraaan)"
        
        dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        let stringTime = dateFormatter.string(from: date)
        jamSelesaiMuatContentLabel.text = ": \(stringTime)"
        
        jenisAyamLabel.layer.borderColor = UIColor.black.cgColor;
        jenisAyamContentLabel.layer.borderColor = UIColor.black.cgColor;
        jumlahEkorLabel.layer.borderColor = UIColor.black.cgColor;
        jumlahEkorContentLabel.layer.borderColor = UIColor.black.cgColor;
        beratNettoLabel.layer.borderColor = UIColor.black.cgColor;
        beratNettoContentLabel.layer.borderColor = UIColor.black.cgColor;
        
        jenisAyamLabel.layer.borderWidth = 1.0;
        jenisAyamContentLabel.layer.borderWidth = 1.0;
        jumlahEkorLabel.layer.borderWidth = 1.0;
        jumlahEkorContentLabel.layer.borderWidth = 1.0;
        beratNettoLabel.layer.borderWidth = 1.0;
        beratNettoContentLabel.layer.borderWidth = 1.0;
        
        let panenTotals = PanenFunctions().calculateTotals(data: panen)
        averageBwContentLabel.text = ": \(String(format: "%.2f", panenTotals.averageBB)) KG"
        jumlahEkorContentLabel.text = "\(panenTotals.totalEkor)"
        beratNettoContentLabel.text = "\(String(format: "%.2f", panenTotals.netto)) KG"
        
        kepalaKandangImageView.image = UIImage(systemName: "signature")
        teamPanenImageView.image = UIImage(systemName: "signature")
        sopirImageView.image = UIImage(systemName: "signature")
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    func dataReceivedFromSignatureVC(signImage: UIImage, name: String, signatureIdentifier: String) {
        switch signatureIdentifier {
        case "kepalaKandang":
            kepalaKandangImageView.image = signImage
            kepalaKandangLabel.text = name
        case "teamPanen":
            teamPanenImageView.image = signImage
            teamPanenLabel.text = name
        case "sopir":
            sopirImageView.image = signImage
            sopirLabel.text = name
        default:
            print("Unknown Signature Identifier")
        }
    }
    
    @IBAction func recordingPanenButtonPressed(_ sender: Any) {
        print("Recording")
        exportFlag = true
        createRecordingCsv(data: panen)
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        print("Back")
        let dialogMessage = UIAlertController(title: "Konfirmasi", message: "Kembali ke menu Input Panen? Tanda tangan yang sudah di tanda tangani akan hilang!", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            self.navigationController?.popViewController(animated: true)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: { (action) -> Void in
            print("Cancel button tapped")
        })
        dialogMessage.addAction(cancel)
        dialogMessage.addAction(ok)
        self.present(dialogMessage, animated: true, completion: nil)
        
    }
    
    @IBAction func uploadButtonPressed(_ sender: Any) {
        guard kepalaKandangImageView.image != UIImage(systemName: "signature") else {
            let dialogMessage = UIAlertController(title: "Invalid Data", message: "TTD Kepala Kandang Kosong", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard teamPanenImageView.image != UIImage(systemName: "signature") else {
            let dialogMessage = UIAlertController(title: "Invalid Data", message: "TTD Team panen Kosong", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        guard sopirImageView.image != UIImage(systemName: "signature") else {
            let dialogMessage = UIAlertController(title: "Invalid Data", message: "TTD Sopir Kosong", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        print("Upload")
        uploadButton.isEnabled = false
        panen.status = "Finished"
        let isPanenUpdateSuccss = Panen.update(farmName: farmName, cycleNumber: cycleNumber, panen: panen)
        
        if isPanenUpdateSuccss {
            print("Panen Record Update Success")
            uploadButton.isEnabled = true
            createPDF()
            let totals = PanenFunctions().calculateTotals(data: panen)
            let telegramText = "*PANEN FINISH (\(self.farmName.prefix(1).uppercased())\(self.cycleNumber)-\(Int(panen.creationTimestamp)))*\n-------------------------------------\nPerusahaan: \(panen.namaPerusahaan)\nNo Kendaraan: \(panen.noKendaraaan)\nRange BB: \(panen.rangeBB)\nSopir:\(panen.namaSopir) (\(panen.noSopir))\nPemborong Panen: \(panen.pemborongPanen)\nPenimbang: \(self.fullName)\nJumlah: ```\(totals.totalEkor)``` Ekor\nBerat: ```\(String(format: "%.2f", totals.netto))``` KG\nAverage: ```\(String(format: "%.2f", totals.averageBB))``` KG"

            Telegram().postTelegramMessage(botToken: Telegram().ChickenAppBotToken, chatID: Telegram().TeamPanenChatID, text: telegramText, parse_mode: "Markdown")
        }
        else {
            let banner = StatusBarNotificationBanner(title: "Error Updating Panen Record!", style: .danger)
            banner.show()
            uploadButton.isEnabled = true
        }
    }
    
    @IBAction func kepalaKandangImageViewTapped(_ sender: Any) {
        print("Kepala Kandang Signature")
        signatureIdentifier = "kepalaKandang"
        self.performSegue(withIdentifier: "goToSignature", sender: self)
    }
    
    @IBAction func teamPanenImageViewTapped(_ sender: Any) {
        print("Team Panen Signature")
        signatureIdentifier = "teamPanen"
        self.performSegue(withIdentifier: "goToSignature", sender: self)
    }
    
    @IBAction func sopirImageViewTapped(_ sender: Any) {
        print("Sopir Signature")
        signatureIdentifier = "sopir"
        self.performSegue(withIdentifier: "goToSignature", sender: self)
    }
    
    func createPDF () {
        exportFlag = false
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
        let pdfPath = docDirectoryPath.appendingPathComponent("\(farmName.prefix(1).uppercased())\(cycleNumber)-\(Int(panen.creationTimestamp))SJ.pdf")
        if data.write(to: pdfPath, atomically: true) {
            uploadSJtoFirebaseStorage(filePath: pdfPath.path, fileRef: "\(farmName)\(cycleNumber)PanenSJ/" + panen.id! + ".pdf" )
            return pdfPath.path
        } else {
            return ""
        }
    }
    
    func createRecordingCsv(data: Panen) {
        guard data.berat.count > 0 else {
            print("Empty Recording")
            return
        }
        
        let fileName = "\(farmName.prefix(1).uppercased())\(cycleNumber)-\(Int(data.creationTimestamp))RP.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        let csvText = PanenFunctions().constructRecordingCsv(data: data)
        
        do {
            try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
            
            csvPath = path!
            let previewController = QLPreviewController()
            previewController.dataSource = self
            present(previewController, animated: true)
            
        } catch {
            print("Failed to create file")
            print("\(error)")
        }
    }
    
    func uploadSJtoFirebaseStorage(filePath: String, fileRef : String) {
        //Upload to Firebase Storage
        let storageRef = Storage.storage().reference()
        let deliveryPermitRef = storageRef.child(fileRef)
        // Create the file metadata
        let metadata = StorageMetadata()
        metadata.contentType = "application/pdf"
        
        // Upload file and metadata to the object
        let uploadTask = deliveryPermitRef.putFile(from: URL(fileURLWithPath: filePath), metadata: metadata)
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
                let dialogMessage = UIAlertController(title: "Error in Uploading File", message: "File does not exist", preferredStyle: .alert)
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
                let dialogMessage = UIAlertController(title: "Error in Uploading File", message: "User doesn't have permission to access file", preferredStyle: .alert)
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
                deliveryPermitRef.putFile(from: URL(fileURLWithPath: self.filePath), metadata: metadata)
              break
            }
          }
        }
        uploadTask.observe(.success) { snapshot in
          // Upload completed successfully
            print("File Upload completed successfully")
        }
    }
    
    //QLPreviewController Methods
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        if exportFlag ==  true {
            return csvPath as QLPreviewItem
        }
        else {
            return URL(fileURLWithPath: filePath) as QLPreviewItem
        }
    }
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        if exportFlag ==  true {
            print("Preview Controller Dismissed")
        }
        else {
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is SignatureViewController
        {
            let vc = segue.destination as? SignatureViewController
            vc?.signatureIdentifier = signatureIdentifier
            vc?.delegate = self
        }
    }
}

class UnderlinedLabel: UILabel {
    override var text: String? {
        didSet {
            guard let text = text else { return }
            let textRange = NSMakeRange(0, text.count)
            let attributedText = NSMutableAttributedString(string: text)
            attributedText.addAttribute(NSAttributedString.Key.underlineStyle , value: NSUnderlineStyle.single.rawValue, range: textRange)
            //Add Attributes
            self.attributedText = attributedText
        }
    }
}
