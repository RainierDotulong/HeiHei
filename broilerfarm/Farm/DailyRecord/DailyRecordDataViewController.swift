//
//  DailyRecordDataViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 7/1/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import SVProgressHUD
import Firebase
import FirebaseFirestore

class DailyRecordDataViewController : UIViewController,sendToDailyRecordData {
    
    @IBOutlet var refreshButton: UIBarButtonItem!
    @IBOutlet var tableButton: UIBarButtonItem!
    
    @IBOutlet var floor1Button: UIButton!
    @IBOutlet var floor2Button: UIButton!
    @IBOutlet var floor3Button: UIButton!
    @IBOutlet var floor4Button: UIButton!
    @IBOutlet var floor5Button: UIButton!
    @IBOutlet var floor6Button: UIButton!
    @IBOutlet var floor1StatusButton: UIButton!
    @IBOutlet var floor2StatusButton: UIButton!
    @IBOutlet var floor3StatusButton: UIButton!
    @IBOutlet var floor4StatusButton: UIButton!
    @IBOutlet var floor5StatusButton: UIButton!
    @IBOutlet var floor6StatusButton: UIButton!
    //Variables received from previous view controller
    var farmName : String = ""
    var fullName : String = ""
    var loginClass : String = ""
    var cycleNumber : Int = 0
    var numberOfFloors : Int  = 0
    
    //Initialize Arrays
    var dailyRecordData : [DailyRecord] = [DailyRecord]()
    
    var dailyRecordData1 : [DailyRecord] = [DailyRecord]()
    var dailyRecordData2 : [DailyRecord] = [DailyRecord]()
    var dailyRecordData3 : [DailyRecord] = [DailyRecord]()
    var dailyRecordData4 : [DailyRecord] = [DailyRecord]()
    var dailyRecordData5 : [DailyRecord] = [DailyRecord]()
    var dailyRecordData6 : [DailyRecord] = [DailyRecord]()
    
    var detailedDailyRecordData1 : [DetailedDailyRecord] = [DetailedDailyRecord]()
    var detailedDailyRecordData2 : [DetailedDailyRecord] = [DetailedDailyRecord]()
    var detailedDailyRecordData3 : [DetailedDailyRecord] = [DetailedDailyRecord]()
    var detailedDailyRecordData4 : [DetailedDailyRecord] = [DetailedDailyRecord]()
    var detailedDailyRecordData5 : [DetailedDailyRecord] = [DetailedDailyRecord]()
    var detailedDailyRecordData6 : [DetailedDailyRecord] = [DetailedDailyRecord]()
    
    var selectedData : [DetailedDailyRecord] = [DetailedDailyRecord]()
    var selectedFloorDetail : FarmFloorDetail = FarmFloorDetail(farmName: "", cycleNumber: 0, floorNumber: 0, startingBodyWeight: 0, startingPopulation: 0, startTimestamp: 0, claimAge: 0, claimQuantity: 0, harvestedWeight: 0, harvestedQuantity: 0, pakanAwal: 0)
    var selectedFloor : String = ""
    
    //Floor Specific Cycle Data Variables
    var floorDetails : [FarmFloorDetail] = [FarmFloorDetail]()
    
    override func viewDidLoad() {
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        //Disable data table view for non admins
        if loginClass == "superadmin" || loginClass == "administrator" {
            tableButton.isEnabled = true
        }
        else {
            tableButton.isEnabled = false
        }
        
        getFloorCycleData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    func dataReceivedFromDailyRecordDataDetails(dismiss: Bool) {
        //Set back to portrait mode
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
    }
    @IBAction func backButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func tableViewButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "goToTableView", sender: self)
    }
    @IBAction func refreshButtonPressed(_ sender: Any) {
        getFloorCycleData()
    }
    
    @IBAction func floorButtonPressed(_ sender: UIButton) {
        if sender.currentTitle == "Lantai 1" {
            selectedFloor = "1"
            selectedData = detailedDailyRecordData1
            for floorDetail in floorDetails {
                if floorDetail.floorNumber == 1 {
                    selectedFloorDetail = floorDetail
                }
            }
        }
        else if sender.currentTitle == "Lantai 2" {
            selectedFloor = "2"
            selectedData = detailedDailyRecordData2
            for floorDetail in floorDetails {
                if floorDetail.floorNumber == 2 {
                    selectedFloorDetail = floorDetail
                }
            }
        }
        else if sender.currentTitle == "Lantai 3" {
            selectedFloor = "3"
            selectedData = detailedDailyRecordData3
            for floorDetail in floorDetails {
                if floorDetail.floorNumber == 3 {
                    selectedFloorDetail = floorDetail
                }
            }
        }
        else if sender.currentTitle == "Lantai 4" {
            selectedFloor = "4"
            selectedData = detailedDailyRecordData4
            for floorDetail in floorDetails {
                if floorDetail.floorNumber == 4 {
                    selectedFloorDetail = floorDetail
                }
            }
        }
        else if sender.currentTitle == "Lantai 5" {
            selectedFloor = "5"
            selectedData = detailedDailyRecordData5
            for floorDetail in floorDetails {
                if floorDetail.floorNumber == 5 {
                    selectedFloorDetail = floorDetail
                }
            }
        }
        else if sender.currentTitle == "Lantai 6" {
            selectedFloor = "6"
            selectedData = detailedDailyRecordData6
            for floorDetail in floorDetails {
                if floorDetail.floorNumber == 6 {
                    selectedFloorDetail = floorDetail
                }
            }
        }
        performSegue(withIdentifier: "goToDailyRecordDataDetails", sender: self)
    }
    
    
    @IBAction func statusButtonPressed(_ sender: UIButton) {
        if sender.currentTitle == "status1" {
            selectedFloor = "1"
            selectedData = detailedDailyRecordData1
        }
        else if sender.currentTitle == "status2" {
            selectedFloor = "2"
            selectedData = detailedDailyRecordData2
        }
        else if sender.currentTitle == "status3" {
            selectedFloor = "3"
            selectedData = detailedDailyRecordData3
        }
        else if sender.currentTitle == "status4" {
            selectedFloor = "4"
            selectedData = detailedDailyRecordData4
        }
        else if sender.currentTitle == "status5" {
            selectedFloor = "5"
            selectedData = detailedDailyRecordData5
        }
        else if sender.currentTitle == "status6" {
            selectedFloor = "6"
            selectedData = detailedDailyRecordData6
        }
        performSegue(withIdentifier: "goToDailyRecordDataStatus", sender: self)
    }
    func getFloorCycleData() {
        SVProgressHUD.show()
        floorDetails.removeAll(keepingCapacity: false)
        for floor in 1...numberOfFloors {
            let cycle = Firestore.firestore().collection(self.farmName + "Details").document("floor\(floor)Cycle\(cycleNumber)Details")
            
            cycle.getDocument { (document, error) in
                if let document = document, document.exists {
                    var floorDetail : FarmFloorDetail = FarmFloorDetail(farmName: self.farmName, cycleNumber: self.cycleNumber, floorNumber: floor, startingBodyWeight: 0, startingPopulation: 0, startTimestamp: 0, claimAge: 0, claimQuantity: 0, harvestedWeight: 0, harvestedQuantity: 0, pakanAwal : 0)
                    floorDetail.startingBodyWeight = Float(truncating: document.data()!["startingBodyWeight"] as! NSNumber)
                    floorDetail.startingPopulation = document.data()!["startingPopulation"] as! Int
                    floorDetail.startTimestamp = document.data()!["startTimestamp"] as! Double
                    floorDetail.claimAge = document.data()!["claimAge"] as! Int
                    floorDetail.claimQuantity = document.data()!["claimQuantity"] as! Int
                    floorDetail.harvestedWeight = Float(truncating: document.data()!["harvestedWeight"] as! NSNumber)
                    floorDetail.harvestedQuantity = document.data()!["harvestedQuantity"] as! Int
                    floorDetail.pakanAwal = document.data()!["pakanAwal"] as! Int
                    self.floorDetails.append(floorDetail)
                    
                    if self.floorDetails.count == self.numberOfFloors {
                        self.getDataFromServer()
                    }
                }
                else {
                    print("Floor Cycle Document does not exist")
                    SVProgressHUD.dismiss()
                    let dialogMessage = UIAlertController(title: "Floor \(floor) Cycle Document does not exist", message: "Please Contact Administrator", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                        print("Ok button tapped")
                    })
                    dialogMessage.addAction(ok)
                    self.present(dialogMessage, animated: true, completion: nil)
                }
            }
        }
    }
    
    func getDataFromServer() {
        SVProgressHUD.show()
        Firestore.firestore().collection("\(farmName)\(cycleNumber)DailyRecordings").order(by: "timestamp").addSnapshotListener { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
              print("No documents")
              SVProgressHUD.dismiss()
              return
            }
            //Initialize Variables
            self.dailyRecordData.removeAll(keepingCapacity: false)
            self.dailyRecordData1.removeAll(keepingCapacity: false)
            self.dailyRecordData2.removeAll(keepingCapacity: false)
            self.dailyRecordData3.removeAll(keepingCapacity: false)
            self.dailyRecordData4.removeAll(keepingCapacity: false)
            self.dailyRecordData5.removeAll(keepingCapacity: false)
            self.dailyRecordData6.removeAll(keepingCapacity: false)
            
            self.dailyRecordData = documents.compactMap { queryDocumentSnapshot -> DailyRecord? in
              return try? queryDocumentSnapshot.data(as: DailyRecord.self)
            }
            for dailyRecord in self.dailyRecordData {
                switch dailyRecord.lantai {
                case 1:
                    self.dailyRecordData1.append(dailyRecord)
                case 2:
                    self.dailyRecordData2.append(dailyRecord)
                case 3:
                    self.dailyRecordData3.append(dailyRecord)
                case 4:
                    self.dailyRecordData4.append(dailyRecord)
                case 5:
                    self.dailyRecordData5.append(dailyRecord)
                default:
                    self.dailyRecordData6.append(dailyRecord)
                }
            }
            SVProgressHUD.dismiss()
            self.calculate()
        }
    }
    
    func calculate() {
        if dailyRecordData1.count > 0 {
            var floorDetail1 : FarmFloorDetail = FarmFloorDetail(farmName: "", cycleNumber: 0, floorNumber: 0, startingBodyWeight: 0, startingPopulation: 0, startTimestamp: 0, claimAge: 0, claimQuantity: 0, harvestedWeight: 0, harvestedQuantity: 0, pakanAwal: 0)
            for floorDetail in floorDetails {
                if floorDetail.floorNumber == 1 {
                    floorDetail1 = floorDetail
                }
            }
            detailedDailyRecordData1 = calculateData(floorButton: floor1Button, floorStatusButton: floor1StatusButton, floorDetail: floorDetail1, data: dailyRecordData1)
        }
        if dailyRecordData2.count > 0 {
            var floorDetail2 : FarmFloorDetail = FarmFloorDetail(farmName: "", cycleNumber: 0, floorNumber: 0, startingBodyWeight: 0, startingPopulation: 0, startTimestamp: 0, claimAge: 0, claimQuantity: 0, harvestedWeight: 0, harvestedQuantity: 0, pakanAwal: 0)
            for floorDetail in floorDetails {
                if floorDetail.floorNumber == 2 {
                    floorDetail2 = floorDetail
                }
            }
            detailedDailyRecordData2 = calculateData(floorButton: floor2Button, floorStatusButton: floor2StatusButton, floorDetail: floorDetail2, data: dailyRecordData2)
        }
        if dailyRecordData3.count > 0 {
            var floorDetail3 : FarmFloorDetail = FarmFloorDetail(farmName: "", cycleNumber: 0, floorNumber: 0, startingBodyWeight: 0, startingPopulation: 0, startTimestamp: 0, claimAge: 0, claimQuantity: 0, harvestedWeight: 0, harvestedQuantity: 0, pakanAwal: 0)
            for floorDetail in floorDetails {
                if floorDetail.floorNumber == 3 {
                    floorDetail3 = floorDetail
                }
            }
            detailedDailyRecordData3 = calculateData(floorButton: floor3Button, floorStatusButton: floor3StatusButton, floorDetail: floorDetail3, data: dailyRecordData3)
        }
        if dailyRecordData4.count > 0 {
            var floorDetail4 : FarmFloorDetail = FarmFloorDetail(farmName: "", cycleNumber: 0, floorNumber: 0, startingBodyWeight: 0, startingPopulation: 0, startTimestamp: 0, claimAge: 0, claimQuantity: 0, harvestedWeight: 0, harvestedQuantity: 0, pakanAwal: 0)
            for floorDetail in floorDetails {
                if floorDetail.floorNumber == 4 {
                    floorDetail4 = floorDetail
                }
            }
            detailedDailyRecordData4 = calculateData(floorButton: floor4Button, floorStatusButton: floor4StatusButton, floorDetail: floorDetail4, data: dailyRecordData4)
        }
        if dailyRecordData5.count > 0 {
            var floorDetail5 : FarmFloorDetail = FarmFloorDetail(farmName: "", cycleNumber: 0, floorNumber: 0, startingBodyWeight: 0, startingPopulation: 0, startTimestamp: 0, claimAge: 0, claimQuantity: 0, harvestedWeight: 0, harvestedQuantity: 0, pakanAwal: 0)
            for floorDetail in floorDetails {
                if floorDetail.floorNumber == 5 {
                    floorDetail5 = floorDetail
                }
            }
            detailedDailyRecordData5 = calculateData(floorButton: floor5Button, floorStatusButton: floor5StatusButton, floorDetail: floorDetail5, data: dailyRecordData5)
        }
        if dailyRecordData6.count > 0 {
            var floorDetail6 : FarmFloorDetail = FarmFloorDetail(farmName: "", cycleNumber: 0, floorNumber: 0, startingBodyWeight: 0, startingPopulation: 0, startTimestamp: 0, claimAge: 0, claimQuantity: 0, harvestedWeight: 0, harvestedQuantity: 0, pakanAwal: 0)
            for floorDetail in floorDetails {
                if floorDetail.floorNumber == 6 {
                    floorDetail6 = floorDetail
                }
            }
            detailedDailyRecordData6 = calculateData(floorButton: floor6Button, floorStatusButton: floor6StatusButton, floorDetail: floorDetail6, data: dailyRecordData6)
        }
    }
    
    func calculateData(floorButton : UIButton, floorStatusButton : UIButton, floorDetail : FarmFloorDetail, data : [DailyRecord]) -> [DetailedDailyRecord] {
        var outputData : [DetailedDailyRecord] = [DetailedDailyRecord]()
        for i in 0..<data.count {
            //Calculate Population, Pakan & RGR
            var deplesiArray : [Int] = [Int]()
            var pakanPakaiArray : [Int] = [Int]()
            
            //Calculate Age
            let floorStartingDate = Date(timeIntervalSince1970: floorDetail.startTimestamp)
            let currentDate = Date(timeIntervalSince1970: data[i].timestamp)
            let diffInDays : Int = Calendar.current.dateComponents([.day], from: floorStartingDate, to: currentDate).day!
            
            for j in 0..<data.count {
                if data[j].timestamp <= data[i].timestamp {
                    pakanPakaiArray.append(data[j].pakanPakai)
                    
                    //Calculate Age
                    let startDate = Date(timeIntervalSince1970: floorDetail.startTimestamp)
                    let currentDate = Date(timeIntervalSince1970: data[j].timestamp)
                    let age : Int = Calendar.current.dateComponents([.day], from: startDate, to: currentDate).day!
                    
                    if age > floorDetail.claimAge {
                        deplesiArray.append(data[j].deplesiCuling)
                        deplesiArray.append(data[j].deplesiMati)
                    }
                }
            }
            let totalDeplesi = deplesiArray.reduce(0, +)
            let totalPakanPakai = pakanPakaiArray.reduce(0, +)
            
            //Calculate RGR
            let rgr = (data[i].bodyWeight - floorDetail.startingBodyWeight) / floorDetail.startingBodyWeight * 100
            
            //Calculate ADG
            var adg : Float = 0
            if i > 0 {
                adg = data[i].bodyWeight - data[i-1].bodyWeight
            }
            else {
                adg = data[i].bodyWeight - floorDetail.startingBodyWeight
            }
            
            //Calculate Population
            var currentPopulation : Int = 0
            if  diffInDays <= floorDetail.claimAge {
                currentPopulation = floorDetail.startingPopulation - totalDeplesi - floorDetail.harvestedQuantity
            }
            else {
                currentPopulation = floorDetail.startingPopulation - totalDeplesi  - floorDetail.harvestedQuantity - floorDetail.claimQuantity
            }
            
            //Calculate FCR (TotalPakan Terpakai/Population*BW)
            let fcr = Float(totalPakanPakai * 50000) / (Float(currentPopulation) * data[i].bodyWeight)
            
            //Calculate Kepadatan (Population*BW/LuasKandang)
            var kepadatan : Float = 0
            if farmName == "pinantik" {
                kepadatan = (Float(currentPopulation) * data[i].bodyWeight) / 2520000
            }
            else {
                kepadatan = (Float(currentPopulation) * data[i].bodyWeight) / 2880000
            }
                        
            //Calculate Persen Deplesi
            let persenDeplesi = (Float(totalDeplesi) / Float(currentPopulation)) * 100
                        
            //Calculate IP
            let ip = (100 - persenDeplesi) * data[i].bodyWeight / 1000 / fcr / Float(diffInDays) * 100
            
            //Estimasi Tonase
            let estimatedKg = (Float(currentPopulation) * data[i].bodyWeight / 1000 / 1000)
            
            let detailedDailyRecord : DetailedDailyRecord = DetailedDailyRecord(timestamp: data[i].timestamp, deplesiMati: data[i].deplesiMati, deplesiCuling: data[i].deplesiCuling, pakanPakai: data[i].pakanPakai, bodyWeight: data[i].bodyWeight, kesehatanAyam: data[i].kesehatanAyam, notes: data[i].notes, lantai: data[i].lantai, reporterName: data[i].reporterName, age: diffInDays, adg: adg, rgr: rgr, population: currentPopulation, totalDeplesi: totalDeplesi, totalPakanPakai: totalPakanPakai, fcr: fcr, kepadatan: kepadatan, ip: ip, estimatedKg: estimatedKg)
            
            outputData.append(detailedDailyRecord)
            
            floorButton.isEnabled = true
            floorButton.backgroundColor = .link
            floorStatusButton.isHidden = false
            floorStatusButton.isEnabled = true
            
        }
        return outputData
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is DailyRecordDataDetailsViewController {
            let vc = segue.destination as? DailyRecordDataDetailsViewController
            vc?.floor = selectedFloor
            vc?.data = selectedData
            vc?.selectedFloorDetail = selectedFloorDetail
            vc?.farmName = farmName
            vc?.delegate = self

        }
        else if segue.destination is DailyRecordDataStatusViewController {
            let vc = segue.destination as? DailyRecordDataStatusViewController
            vc?.floor = selectedFloor
            vc?.data = selectedData
            vc?.farmName = farmName
        }
        else if segue.destination is DailyRecordDataTableViewController {
            let vc = segue.destination as? DailyRecordDataTableViewController
            vc?.cycleNumber = cycleNumber
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.numberOfFloors = numberOfFloors
            vc?.dailyRecordData = dailyRecordData
        }
    }
}
