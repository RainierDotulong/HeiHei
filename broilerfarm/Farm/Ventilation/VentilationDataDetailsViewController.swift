//
//  VentilationDataDetailsViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 6/30/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import SwiftSpreadsheet
import QuickLook

class DefaultCollectionViewCell: UICollectionViewCell {
    @IBOutlet var infoLabel: UILabel!
}
class SpreadsheetCollectionReusableView: UICollectionReusableView {
    @IBOutlet weak var infoLabel: UILabel!
}

protocol sendToVentilationData {
    
    func dataReceivedFromVentilationDataDetails(dismiss : Bool)
    
}

class VentilationDataDetailsViewController : UIViewController, QLPreviewControllerDataSource {
    
    var farmName : String = ""
    var floor : String = ""
    var delegate : sendToVentilationData?
    
    var csvPath : URL = URL(string: "https://www.globalxtreme.net")!
    
    let defaultCellIdentifier = "DefaultCellIdentifier"
    let defaultSupplementaryViewIdentifier = "DefaultSupplementaryViewIdentifier"
    
    struct DecorationViewNames {
        static let topLeft = "VentilationSpreadsheetTopLeftDecorationView"
        static let topRight = "VentilationSpreadsheetTopRightDecorationView"
        static let bottomLeft = "VentilationSpreadsheetBottomLeftDecorationView"
        static let bottomRight = "VentilationSpreadsheetBottomRightDecorationView"
    }
    
    struct SupplementaryViewNames {
        static let left = "VentilationSpreadsheetLeftRowView"
        static let right = "VentilationSpreadsheetRightRowView"
        static let top = "VentilationSpreadsheetTopColumnView"
        static let bottom = "VentilationSpreadsheetBottomColumnView"
    }
    
    @IBOutlet var collectionView: UICollectionView!
    
    @IBOutlet var navBar: UINavigationItem!
    
    var floorDetail : FarmFloorDetail = FarmFloorDetail(farmName: "", cycleNumber: 0, floorNumber: 0, startingBodyWeight: 0, startingPopulation: 0, startTimestamp: 0, claimAge: 0, claimQuantity: 0, harvestedWeight: 0, harvestedQuantity: 0, pakanAwal: 0)
    var data : [Ventilation] = [Ventilation]()
    var effTempArray : [Float] = [Float]()
    
    var dataArray : [[String]] = [[String]]()
    var prettyDateArray : [String] = [String]()
    var titleArray = ["Manual", "Intermittent", "ON(s)", "OFF(s)","Heater(°C)", "Inverter", "Pinggir(Hz)", "Tengah(Hz)", "SuhuPB(°C)", "WSPB(FPM)", "RHPB(%)", "NH3PB(ppm)", "CO2PB(ppm)", "SuhuPC(°C)", "WSPC(FPM)", "RHPC(%)", "NH3PC(ppm)", "CO2PC(ppm)", "SuhuLK(°C)", "WSLK(FPM)", "RHLK(%)", "NH3LK(ppm)", "CO2LK(ppm)", "UMUR", "Pelapor" ]
    let numberFormatter = NumberFormatter()
    let maxRows = 6000
    let lightGreyColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
    
    override func viewDidLoad() {
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        navBar.title = farmName.uppercased() + "-LT." + floor
        
        self.navBar.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "Back", style: UIBarButtonItem.Style.plain, target: self, action: #selector(VentilationDataDetailsViewController.back(sender:)))
        self.navBar.leftBarButtonItem = newBackButton
        
        for i in data {
            
            //Calculate Age
            let startDate = Date(timeIntervalSince1970: floorDetail.startTimestamp)
            let currentDate = Date(timeIntervalSince1970: i.timestamp)
            let age : Int = Calendar.current.dateComponents([.day], from: startDate, to: currentDate).day!
            
            let subArray1 = [String(i.ventilasiManual),
                              String(i.ventilasiIntermittent),
                              String(i.ventilasiOn),
                              String(i.ventilasiOff),
                              String(i.ventilasiHeater),
                              String(i.inverter),
                              String(i.inverterPinggir),
                              String(i.inverterTengah),
                              String(format: "%.2f", i.pintuBlowerSuhu),
                              String(i.pintuBlowerSpeed),
                              String(i.pintuBlowerRh)]
            
            let subArray2 = [String(i.pintuBlowerNh3),
                             String(i.pintuBlowerCo2),
                             String(format: "%.2f", i.pintuCellDeckSuhu),
                             String(i.pintuCellDeckSpeed),
                             String(i.pintuCellDeckRh),
                             String(i.pintuCellDeckNh3),
                             String(i.pintuCellDeckCo2),
                             String(format: "%.2f", i.luarKandangSuhu)]
            
            let subArray3 = [String(i.luarKandangSpeed),
                             String(i.luarKandangRh),
                             String(i.luarKandangNh3),
                             String(i.luarKandangCo2),
                             String(age),
                             i.reporterName]
            
            var array : [String] = [String]()
            for data in subArray1 {
                array.append(data)
            }
            for data in subArray2 {
                array.append(data)
            }
            for data in subArray3 {
                array.append(data)
            }
            
            dataArray.append(array)
            
            let date = Date(timeIntervalSince1970: i.timestamp )
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: date)
            prettyDateArray.append(stringDate)
            
            
        }
        
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
    
    @objc func back(sender: UIBarButtonItem) {
        // Go back to the previous ViewController
        delegate?.dataReceivedFromVentilationDataDetails(dismiss : true)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func exportButtonPressed(_ sender: Any) {
        let fileName = "\(farmName.uppercased() + "-LT." + floor + "-Ventilation").csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        var csvText = "Tanggal,Eff. Temp(°C),Manual,Intermittent,ON(s),OFF(s),Heater(°C),Inverter,Pinggir(Hz),Tengah(Hz),SuhuPB(°C),WSPB(FPM),RHPB(%),NH3PB(ppm),CO2PB(ppm),SuhuPC(°C),WSPC(FPM),RHPC(%),NH3PC(ppm),CO2PC(ppm),SuhuLK(°C),WSLK(FPM),RHLK(%),NH3LK(ppm),CO2LK(ppm),UMUR,Pelapor\n"
        
        let count = dataArray.count
        
        if count > 0 {
            for i in 1...dataArray.count {
                let newLine = "\(prettyDateArray[i-1].replacingOccurrences(of: ",", with: "")),\(effTempArray[i-1]),\(dataArray[i-1][0]),\(dataArray[i-1][1]),\(dataArray[i-1][2]),\(dataArray[i-1][3]),\(dataArray[i-1][4]),\(dataArray[i-1][5]),\(dataArray[i-1][6]),\(dataArray[i-1][7]),\(dataArray[i-1][8]),\(dataArray[i-1][9]),\(dataArray[i-1][10]),\(dataArray[i-1][11]),\(dataArray[i-1][12]),\(dataArray[i-1][13]),\(dataArray[i-1][14]),\(dataArray[i-1][15]),\(dataArray[i-1][16]),\(dataArray[i-1][17]),\(dataArray[i-1][18]),\(dataArray[i-1][19]),\(dataArray[i-1][20]),\(dataArray[i-1][21]),\(dataArray[i-1][22]),\(dataArray[i-1][23]),\(dataArray[i-1][24])\n"

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
    
    //QLPreviewController Methods
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return csvPath as QLPreviewItem
    }
    
}

extension VentilationDataDetailsViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.dataArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataArray[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.defaultCellIdentifier, for: indexPath) as? DefaultCollectionViewCell else { fatalError("Invalid cell dequeued") }
        
        let value = self.dataArray[indexPath.section][indexPath.item]
        cell.infoLabel.text = value
        
        cell.backgroundColor = indexPath.item % 2 == 1 ? self.lightGreyColor : UIColor.white
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let viewKind = SpreadsheetLayout.ViewKindType(rawValue: kind) else { fatalError("View Kind not available for string: \(kind)") }
        
        let supplementaryView = collectionView.dequeueReusableSupplementaryView(ofKind: viewKind.rawValue, withReuseIdentifier: self.defaultSupplementaryViewIdentifier, for: indexPath) as! SpreadsheetCollectionReusableView
        switch viewKind {
        case .leftRowHeadline:
            supplementaryView.infoLabel.text = prettyDateArray[indexPath.section]
        case .rightRowHeadline:
            supplementaryView.infoLabel.text = String(format: "%.2f", effTempArray[indexPath.section]) + "°C"
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

extension VentilationDataDetailsViewController: SpreadsheetLayoutDelegate {
    
    func spreadsheet(layout: SpreadsheetLayout, heightForRowsInSection section: Int) -> CGFloat {
        return 40
    }
    
    func widthsOfSideRowsInSpreadsheet(layout: SpreadsheetLayout) -> (left: CGFloat?, right: CGFloat?) {
        return (120, 80)
    }
    
    func spreadsheet(layout: SpreadsheetLayout, widthForColumnAtIndex index: Int) -> CGFloat {
        return 90
    }
    
    func heightsOfHeaderAndFooterColumnsInSpreadsheet(layout: SpreadsheetLayout) -> (headerHeight: CGFloat?, footerHeight: CGFloat?) {
        return (50, nil)
    }
}

