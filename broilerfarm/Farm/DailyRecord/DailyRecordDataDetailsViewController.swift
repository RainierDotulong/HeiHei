//
//  DailyRecordDataDetailsViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 7/1/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import SwiftSpreadsheet
import QuickLook
import Firebase
import FirebaseFirestore
import SVProgressHUD

class DailyRecordDefaultCollectionViewCell : UICollectionViewCell {
    @IBOutlet var infoLabel: UILabel!
}

class DailyRecordSpreadsheetCollectionReusableView: UICollectionReusableView {
    @IBOutlet var infoLabel: UILabel!
    
}

protocol sendToDailyRecordData {
    
    func dataReceivedFromDailyRecordDataDetails(dismiss : Bool)
    
}

class DailyRecordDataDetailsViewController : UIViewController, QLPreviewControllerDataSource {
    
   
    var delegate : sendToDailyRecordData?
    
    var csvPath : URL = URL(string: "https://www.globalxtreme.net")!
    
    let defaultCellIdentifier = "DailyRecordDefaultCellIdentifier"
    let defaultSupplementaryViewIdentifier = "DailyRecordDefaultSupplementaryViewIdentifier"
    
    struct DecorationViewNames {
        static let topLeft = "DailyRecordSpreadsheetTopLeftDecorationView"
        static let topRight = "DailyRecordSpreadsheetTopRightDecorationView"
        static let bottomLeft = "DailyRecordSpreadsheetBottomLeftDecorationView"
        static let bottomRight = "DailyRecordSpreadsheetBottomRightDecorationView"
    }
    
    struct SupplementaryViewNames {
        static let left = "DailyRecordSpreadsheetLeftRowView"
        static let right = "DailyRecordSpreadsheetRightRowView"
        static let top = "DailyRecordSpreadsheetTopColumnView"
        static let bottom = "DailyRecordSpreadsheetBottomColumnView"
    }
    
    @IBOutlet var collectionView: UICollectionView!
    
    @IBOutlet var navBar: UINavigationItem!
    
    @IBOutlet var detailBarButton: UIBarButtonItem!
    
    var farmName : String = ""
    var floor : String = ""
    var data : [DetailedDailyRecord] = [DetailedDailyRecord]()
    var selectedFloorDetail : FarmFloorDetail = FarmFloorDetail(farmName: "", cycleNumber: 0, floorNumber: 0, startingBodyWeight: 0, startingPopulation: 0, startTimestamp: 0, claimAge: 0, claimQuantity: 0, harvestedWeight: 0, harvestedQuantity: 0, pakanAwal: 0)
    
    var dataArray : [[String]] = [[String]]()
    var umurArray : [String] = [String]()
    var dateArray : [String] = [String]()
    var titleArray = ["BW", "ADG", "RGR", "Populasi", "Total Deplesi", "Deplesi Culing", "Deplesi Mati", "Pakan Terpakai", "Pakan Pakai", "FCR", "Kepadatan", "IP","Estimasi Tonase","Pelapor" ]
    let maxRows = 135
    let lightGreyColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
    
    var bwReferenceArray : [String] = [String]()
    var adgReferenceArray : [String] = [String]()
    var deplesiReferenceArray : [String] = [String]()
    var pakanPakaiReferenceArray : [String] = [String]()
    var fcrReferenceArray : [String] = [String]()
    var populasiReferenceArray : [String] = [String]()
    var ipReferenceArray : [String] = [String]()
    
    override func viewDidLoad() {
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        //Construct Data Array
        for i in data {
            dataArray.append([String(format: "%.1f",i.bodyWeight),
                              String(format: "%.1f",i.adg),
                              String(format: "%.2f",i.rgr),
                              String(i.population),
                              String(i.totalDeplesi),
                              String(i.deplesiCuling),
                              String(i.deplesiMati),
                              String(i.totalPakanPakai),
                              String(i.pakanPakai),
                              String(format: "%.2f",i.fcr),
                              String(format: "%.2f",i.kepadatan),
                              String(format: "%.2f",i.ip),
                              String(format: "%.2f",i.estimatedKg),
                              i.reporterName])
            
            umurArray.append(String(i.age))
            
            let date = Date(timeIntervalSince1970: i.timestamp )
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: date)
            dateArray.append(stringDate.replacingOccurrences(of: ",", with: ""))
        }
        
        navBar.title = farmName.uppercased() + "-LT." + floor
        
        //Helper Method for collection view
        collectionView.reloadData()
        
        //DecorationView Nibs
        let topLeftDecorationViewNib = UINib(nibName: DecorationViewNames.topLeft, bundle: nil)
        let topRightDecorationViewNib = UINib(nibName: DecorationViewNames.topRight, bundle: nil)
        let bottomLeftDecorationViewNib = UINib(nibName: DecorationViewNames.bottomLeft, bundle: nil)
        let bottomRightDecorationViewNib = UINib(nibName: DecorationViewNames.bottomRight, bundle: nil)
        
        //SupplementaryView Nibs
        let topSupplementaryViewNib = UINib(nibName: SupplementaryViewNames.top, bundle: nil)
        let bottomSupplementaryViewNib = UINib(nibName: SupplementaryViewNames.bottom, bundle: nil)
        let leftSupplementaryViewNib = UINib(nibName: SupplementaryViewNames.left, bundle: nil)
        let rightSupplementaryViewNib = UINib(nibName: SupplementaryViewNames.right, bundle: nil)
        
        //Setup Layout
        let layout = SpreadsheetLayout(delegate: self,
                                       topLeftDecorationViewType: .asNib(topLeftDecorationViewNib),
                                       topRightDecorationViewType: .asNib(topRightDecorationViewNib),
                                       bottomLeftDecorationViewType: .asNib(bottomLeftDecorationViewNib),
                                       bottomRightDecorationViewType: .asNib(bottomRightDecorationViewNib))
        
        //Default is true, set false here if you do not want some of these sides to remain sticky
        layout.stickyLeftRowHeader = true
        layout.stickyRightRowHeader = true
        layout.stickyTopColumnHeader = true
        layout.stickyBottomColumnFooter = false
        
        self.collectionView.collectionViewLayout = layout
        
        
        //Register Supplementary-View nibs for the given ViewKindTypes
        self.collectionView.register(leftSupplementaryViewNib, forSupplementaryViewOfKind: SpreadsheetLayout.ViewKindType.leftRowHeadline.rawValue, withReuseIdentifier: self.defaultSupplementaryViewIdentifier)
        self.collectionView.register(rightSupplementaryViewNib, forSupplementaryViewOfKind: SpreadsheetLayout.ViewKindType.rightRowHeadline.rawValue, withReuseIdentifier: self.defaultSupplementaryViewIdentifier)
        self.collectionView.register(topSupplementaryViewNib, forSupplementaryViewOfKind: SpreadsheetLayout.ViewKindType.topColumnHeader.rawValue, withReuseIdentifier: self.defaultSupplementaryViewIdentifier)
        self.collectionView.register(bottomSupplementaryViewNib, forSupplementaryViewOfKind: SpreadsheetLayout.ViewKindType.bottomColumnFooter.rawValue, withReuseIdentifier: self.defaultSupplementaryViewIdentifier)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        // Go back to the previous ViewController
        delegate?.dataReceivedFromDailyRecordDataDetails(dismiss : true)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func detailButtonPressed(_ sender: Any) {
        detailBarButton.isEnabled = false
        getReferenceData()
    }
    @IBAction func informationButtonPressed(_ sender: Any) {
        let date = Date(timeIntervalSince1970: selectedFloorDetail.startTimestamp )
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        let startingDate = dateFormatter.string(from: date)
        
        //Declare Alert message
        let message = "Tanggal Mulai: \(startingDate)\n BW Awal: \(selectedFloorDetail.startingBodyWeight) Gram\n Populasi Awal: \(selectedFloorDetail.startingPopulation) Ekor\n Umur Claim : \(selectedFloorDetail.claimAge) Hari\n Jumlah Claim: \(selectedFloorDetail.claimQuantity) Ekor"
        let dialogMessage = UIAlertController(title: "Floor Data", message: message, preferredStyle: .alert)
        // Create OK button with action handler
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
        })
        //Add OK and Cancel button to dialog message
        dialogMessage.addAction(ok)
        // Present dialog message to user
        self.present(dialogMessage, animated: true, completion: nil)
    }
    @IBAction func exportButtonPressed(_ sender: Any) {
        let fileName = "\(farmName.uppercased() + "-LT." + floor + "-DailyRecord").csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        var csvText = "Umur,Tanggal,BW,ADG,RGR,Populasi,Total Deplesi,Deplesi Culing,Deplesi Mati,Pakan Terpakai,Pakan Pakai,Ekor Panen,KG Panen,Panen,FCR,Kepadatan,IP,Pelapor\n"
        
        let count = dataArray.count
        
        if count > 0 {
            for i in 1...dataArray.count {
                let newLine = "\(umurArray[i-1]),\(dateArray[i-1])\(dataArray[i-1][0]),\(dataArray[i-1][1]),\(dataArray[i-1][2]),\(dataArray[i-1][3]),\(dataArray[i-1][4]),\(dataArray[i-1][5]),\(dataArray[i-1][6]),\(dataArray[i-1][7]),\(dataArray[i-1][8]),\(dataArray[i-1][9]),\(dataArray[i-1][10]),\(dataArray[i-1][11]),\(dataArray[i-1][12]),\(dataArray[i-1][13]),\(dataArray[i-1][14]),\(dataArray[i-1][15]),\(dataArray[i-1][16])\n"

                csvText.append(newLine)
            }
            
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
            
        } else {
            print("There is no data to export")
        }
    }
    
    func getReferenceData () {
        bwReferenceArray.removeAll(keepingCapacity: false)
        adgReferenceArray.removeAll(keepingCapacity: false)
        deplesiReferenceArray.removeAll(keepingCapacity: false)
        pakanPakaiReferenceArray.removeAll(keepingCapacity: false)
        fcrReferenceArray.removeAll(keepingCapacity: false)
        populasiReferenceArray.removeAll(keepingCapacity: false)
        ipReferenceArray.removeAll(keepingCapacity: false)
        //Get Deplesi Reference Data from Firebase
        let cycle = Firestore.firestore().collection("reference").document(farmName.lowercased() + "floor" + floor)
        let zerosArray : [String] = Array(repeating: "0", count: 46)
        SVProgressHUD.show()
        cycle.getDocument { (document, error) in
            if let document = document, document.exists {
                let dataDescription = document.data()
                self.deplesiReferenceArray = dataDescription!["deplesi"] as? [String] ?? zerosArray
                self.bwReferenceArray = dataDescription!["bw"] as? [String] ?? zerosArray
                self.adgReferenceArray = dataDescription!["adg"] as? [String] ?? zerosArray
                self.pakanPakaiReferenceArray = dataDescription!["pakan"] as? [String] ?? zerosArray
                self.fcrReferenceArray = dataDescription!["fcr"] as? [String] ?? zerosArray
                self.populasiReferenceArray = dataDescription!["populasi"] as? [String] ?? zerosArray
                self.ipReferenceArray = dataDescription!["ip"] as? [String] ?? zerosArray
                SVProgressHUD.dismiss()
                self.reconstructDataArray()
            } else {
                SVProgressHUD.dismiss()
                print("Reference Document does not exist")
                //Declare Alert message
                let dialogMessage = UIAlertController(title: "Reference Document does not exist", message: "Please Contact Administrator", preferredStyle: .alert)
                
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
    }
    
    func reconstructDataArray() {
        
        titleArray = ["BW","REF BW","ADG","REF ADG","RGR","Populasi","REF Populasi","Total Deplesi","REF Total Deplesi","Deplesi Culing", "Deplesi Mati","REF Deplesi", "Pakan Terpakai","REF Pakan Terpakai","Pakan Pakai","REF Pakan Pakai","FCR","REF FCR","Kepadatan", "IP","REF IP","Estimasi Tonase","Pelapor" ]
        
        var deplesiRefArray : [Float] = [Float]()
        var pakanRefArray : [Float] = [Float]()
        
        for i in 0..<dataArray.count {
            if Int(umurArray[i])! < 46 {
                dataArray[i].insert(bwReferenceArray[Int(umurArray[i])!], at:1)
                dataArray[i].insert(adgReferenceArray[Int(umurArray[i])!], at:3)
                dataArray[i].insert(populasiReferenceArray[Int(umurArray[i])!], at:6)
                
                //Determine Deplesi Reference Array
                let deplesiReference = Float(deplesiReferenceArray[Int(umurArray[i])!])! * Float(dataArray[i][5])! / 100
                dataArray[i].insert(String(format: "%.0f", deplesiReference), at:10)
                deplesiRefArray.append(deplesiReference)
                
                //Determine Pakan Reference
                let pakanPakaiPerEkor = Float(pakanPakaiReferenceArray[Int(umurArray[i])!])!
                let pakanPakai = pakanPakaiPerEkor * Float(dataArray[i][5])! / 1000 / 50
                dataArray[i].insert(String(format: "%.0f",pakanPakai), at:13)
                pakanRefArray.append(pakanPakai)
                
                dataArray[i].insert(fcrReferenceArray[Int(umurArray[i])!], at:15)
                dataArray[i].insert(ipReferenceArray[Int(umurArray[i])!], at:18)
            }
            else {
                dataArray[i].insert("0", at:1)
                dataArray[i].insert("0", at:3)
                dataArray[i].insert("0", at:6)
                dataArray[i].insert("0", at:10)
                dataArray[i].insert("0", at:13)
                dataArray[i].insert("0", at:15)
                dataArray[i].insert("0", at:18)
            }
        }
        //Determine Total Deplesi REF & Total Pakan REF
        for i in 0..<dataArray.count {
            if Int(umurArray[i])! < 46 {
                //Determine Deplesi Total Reference
                var deplesiTotalReference : [Float] = [Float]()
                for j in 0..<deplesiRefArray.count {
                    if j <= i {
                        deplesiTotalReference.append(deplesiRefArray[j])
                    }
                }
                let deplesiTotal = deplesiTotalReference.reduce(0,+)
                dataArray[i].insert(String(format: "%.0f",deplesiTotal), at:8)
                
                //Determine Pakan Total Reference
                var pakanReferenceArray : [Float] = [Float]()
                for j in 0..<pakanRefArray.count {
                     if j <= i {
                        pakanReferenceArray.append(pakanRefArray[j])
                    }
                }
                let pakanPakaiTotal = pakanReferenceArray.reduce(0,+)
                dataArray[i].insert(String(format: "%.0f",pakanPakaiTotal), at:13)
            }
            else {
                dataArray[i].insert("0", at:8)
                dataArray[i].insert("0", at:13)
            }
            
        }
        collectionView.reloadData()
        
        //DecorationView Nibs
        let topLeftDecorationViewNib = UINib(nibName: DecorationViewNames.topLeft, bundle: nil)
        let topRightDecorationViewNib = UINib(nibName: DecorationViewNames.topRight, bundle: nil)
        let bottomLeftDecorationViewNib = UINib(nibName: DecorationViewNames.bottomLeft, bundle: nil)
        let bottomRightDecorationViewNib = UINib(nibName: DecorationViewNames.bottomRight, bundle: nil)
        
        //SupplementaryView Nibs
        let topSupplementaryViewNib = UINib(nibName: SupplementaryViewNames.top, bundle: nil)
        let bottomSupplementaryViewNib = UINib(nibName: SupplementaryViewNames.bottom, bundle: nil)
        let leftSupplementaryViewNib = UINib(nibName: SupplementaryViewNames.left, bundle: nil)
        let rightSupplementaryViewNib = UINib(nibName: SupplementaryViewNames.right, bundle: nil)
        
        //Setup Layout
        let layout = SpreadsheetLayout(delegate: self,
                                       topLeftDecorationViewType: .asNib(topLeftDecorationViewNib),
                                       topRightDecorationViewType: .asNib(topRightDecorationViewNib),
                                       bottomLeftDecorationViewType: .asNib(bottomLeftDecorationViewNib),
                                       bottomRightDecorationViewType: .asNib(bottomRightDecorationViewNib))
        
        //Default is true, set false here if you do not want some of these sides to remain sticky
        layout.stickyLeftRowHeader = true
        layout.stickyRightRowHeader = true
        layout.stickyTopColumnHeader = true
        layout.stickyBottomColumnFooter = false
        layout.resetLayoutCache()
        
        self.collectionView.collectionViewLayout = layout
        
        //Register Supplementary-View nibs for the given ViewKindTypes
        self.collectionView.register(leftSupplementaryViewNib, forSupplementaryViewOfKind: SpreadsheetLayout.ViewKindType.leftRowHeadline.rawValue, withReuseIdentifier: self.defaultSupplementaryViewIdentifier)
        self.collectionView.register(rightSupplementaryViewNib, forSupplementaryViewOfKind: SpreadsheetLayout.ViewKindType.rightRowHeadline.rawValue, withReuseIdentifier: self.defaultSupplementaryViewIdentifier)
        self.collectionView.register(topSupplementaryViewNib, forSupplementaryViewOfKind: SpreadsheetLayout.ViewKindType.topColumnHeader.rawValue, withReuseIdentifier: self.defaultSupplementaryViewIdentifier)
        self.collectionView.register(bottomSupplementaryViewNib, forSupplementaryViewOfKind: SpreadsheetLayout.ViewKindType.bottomColumnFooter.rawValue, withReuseIdentifier: self.defaultSupplementaryViewIdentifier)

    }
    
    //QLPreviewController Methods
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return csvPath as QLPreviewItem
    }
}

extension DailyRecordDataDetailsViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataArray[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.defaultCellIdentifier, for: indexPath) as? DailyRecordDefaultCollectionViewCell else { fatalError("Invalid cell dequeued") }
        
        let value = self.dataArray[indexPath.section][indexPath.item]
        cell.infoLabel.text = value
        
        cell.backgroundColor = indexPath.item % 2 == 1 ? self.lightGreyColor : UIColor.white
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let viewKind = SpreadsheetLayout.ViewKindType(rawValue: kind) else { fatalError("View Kind not available for string: \(kind)") }
        
        let supplementaryView = collectionView.dequeueReusableSupplementaryView(ofKind: viewKind.rawValue, withReuseIdentifier: self.defaultSupplementaryViewIdentifier, for: indexPath) as! DailyRecordSpreadsheetCollectionReusableView
        switch viewKind {
        case .leftRowHeadline:
            supplementaryView.infoLabel.text = dateArray[indexPath.section]
        case .rightRowHeadline:
            supplementaryView.infoLabel.text = umurArray[indexPath.section]
        case .topColumnHeader:
            supplementaryView.infoLabel.text = titleArray[indexPath.item]
            supplementaryView.backgroundColor = indexPath.item % 2 == 1 ? self.lightGreyColor : UIColor.white
        case .bottomColumnFooter:
            supplementaryView.infoLabel.text = "END"
            supplementaryView.backgroundColor = indexPath.item % 2 == 1 ? self.lightGreyColor : UIColor.white
        default:
            break
        }
        
        return supplementaryView
    }
    
}

//MARK: - Spreadsheet Layout Delegate

extension DailyRecordDataDetailsViewController: SpreadsheetLayoutDelegate {
    
    func spreadsheet(layout: SpreadsheetLayout, heightForRowsInSection section: Int) -> CGFloat {
        return 40
    }
    
    func widthsOfSideRowsInSpreadsheet(layout: SpreadsheetLayout) -> (left: CGFloat?, right: CGFloat?) {
        return (120, 50)
    }
    
    func spreadsheet(layout: SpreadsheetLayout, widthForColumnAtIndex index: Int) -> CGFloat {
        return 120
    }
    
    func heightsOfHeaderAndFooterColumnsInSpreadsheet(layout: SpreadsheetLayout) -> (headerHeight: CGFloat?, footerHeight: CGFloat?) {
        return (50, nil)
    }
}


