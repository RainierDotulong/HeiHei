//
//  VentilationDataViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 6/29/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import UIEmptyState
import SVProgressHUD
import Firebase
import FirebaseFirestore

class VentilationDataViewController : UIViewController, sendToVentilationData {
    
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
    var numberOfFloors : Int = 0
    
    //Floor Specific Cycle Data Variables
    var floorDetails : [FarmFloorDetail] = [FarmFloorDetail]()
    
    //Ventilation Data
    var ventilationData : [Ventilation] = [Ventilation]()
    var ventilationData1 : [Ventilation] = [Ventilation]()
    var ventilationData2 : [Ventilation] = [Ventilation]()
    var ventilationData3 : [Ventilation] = [Ventilation]()
    var ventilationData4 : [Ventilation] = [Ventilation]()
    var ventilationData5 : [Ventilation] = [Ventilation]()
    var ventilationData6 : [Ventilation] = [Ventilation]()
    
    //Eff Temp Data
    var effTempData1 : [Float] = [Float]()
    var effTempData2 : [Float] = [Float]()
    var effTempData3 : [Float] = [Float]()
    var effTempData4 : [Float] = [Float]()
    var effTempData5 : [Float] = [Float]()
    var effTempData6 : [Float] = [Float]()
        
    var selectedDataArray : [Ventilation] = [Ventilation]()
    var selectedFloorDetail : FarmFloorDetail = FarmFloorDetail(farmName: "", cycleNumber: 0, floorNumber: 0, startingBodyWeight: 0, startingPopulation: 0, startTimestamp: 0, claimAge: 0, claimQuantity: 0, harvestedWeight: 0, harvestedQuantity: 0, pakanAwal: 0)
    var selectedEffTempArray : [Float] = [Float]()
    var selectedFloor : String = ""
    
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
    
    func dataReceivedFromVentilationDataDetails(dismiss: Bool) {
        //Set back to portrait mode
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func historyButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "goToTableView", sender: self)
    }
    @IBAction func floorButtonPressed(_ sender: UIButton) {
        if sender.currentTitle == "Lantai 1" {
            selectedFloor = "1"
            selectedDataArray = ventilationData1
            selectedEffTempArray = effTempData1
            for floorDetail in floorDetails {
                if floorDetail.floorNumber == 1 {
                    selectedFloorDetail = floorDetail
                }
            }
        }
        else if sender.currentTitle == "Lantai 2" {
            selectedFloor = "2"
            selectedDataArray = ventilationData2
            selectedEffTempArray = effTempData2
            for floorDetail in floorDetails {
                if floorDetail.floorNumber == 2 {
                    selectedFloorDetail = floorDetail
                }
            }
        }
        else if sender.currentTitle == "Lantai 3" {
            selectedFloor = "3"
            selectedDataArray = ventilationData3
            selectedEffTempArray = effTempData3
            for floorDetail in floorDetails {
                if floorDetail.floorNumber == 3 {
                    selectedFloorDetail = floorDetail
                }
            }
        }
        else if sender.currentTitle == "Lantai 4" {
            selectedFloor = "4"
            selectedDataArray = ventilationData4
            selectedEffTempArray = effTempData4
            for floorDetail in floorDetails {
                if floorDetail.floorNumber == 4 {
                    selectedFloorDetail = floorDetail
                }
            }
        }
        else if sender.currentTitle == "Lantai 5" {
            selectedFloor = "5"
            selectedDataArray = ventilationData5
            selectedEffTempArray = effTempData5
            for floorDetail in floorDetails {
                if floorDetail.floorNumber == 5 {
                    selectedFloorDetail = floorDetail
                }
            }
        }
        else if sender.currentTitle == "Lantai 6" {
            selectedFloor = "6"
            selectedDataArray = ventilationData6
            selectedEffTempArray = effTempData6
            for floorDetail in floorDetails {
                if floorDetail.floorNumber == 6 {
                    selectedFloorDetail = floorDetail
                }
            }
        }
        performSegue(withIdentifier: "goToVentilationDataDetails", sender: self)
    }
    
    @IBAction func statusButtonPressed(_ sender: UIButton) {
        if sender.currentTitle == "status1" {
            selectedFloor = "1"
            selectedDataArray = ventilationData1
        }
        else if sender.currentTitle == "status2" {
            selectedFloor = "2"
            selectedDataArray = ventilationData2
        }
        else if sender.currentTitle == "status3" {
            selectedFloor = "3"
            selectedDataArray = ventilationData3
        }
        else if sender.currentTitle == "status4" {
            selectedFloor = "4"
            selectedDataArray = ventilationData4
        }
        else if sender.currentTitle == "status5" {
            selectedFloor = "5"
            selectedDataArray = ventilationData5
        }
        else if sender.currentTitle == "status6" {
            selectedFloor = "6"
            selectedDataArray = ventilationData6
        }
        performSegue(withIdentifier: "goToVentilationDataStatus", sender: self)
    }
    
    func getFloorCycleData() {
        SVProgressHUD.show()
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
        Firestore.firestore().collection("\(farmName)\(cycleNumber)VentilationData").order(by: "timestamp").addSnapshotListener { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
              print("No documents")
              SVProgressHUD.dismiss()
              return
            }
            self.ventilationData = documents.compactMap { queryDocumentSnapshot -> Ventilation? in
              SVProgressHUD.dismiss()
              return try? queryDocumentSnapshot.data(as: Ventilation.self)
            }
            for ventilation in self.ventilationData {
                switch ventilation.floor {
                case 1:
                    self.ventilationData1.append(ventilation)
                    self.effTempData1.append(self.calculateEffectiveTemperature(ventilationRecord: ventilation))
                case 2:
                    self.ventilationData2.append(ventilation)
                    self.effTempData2.append(self.calculateEffectiveTemperature(ventilationRecord: ventilation))
                case 3:
                    self.ventilationData3.append(ventilation)
                    self.effTempData3.append(self.calculateEffectiveTemperature(ventilationRecord: ventilation))
                case 4:
                    self.ventilationData4.append(ventilation)
                    self.effTempData4.append(self.calculateEffectiveTemperature(ventilationRecord: ventilation))
                case 5:
                    self.ventilationData5.append(ventilation)
                    self.effTempData5.append(self.calculateEffectiveTemperature(ventilationRecord: ventilation))
                default:
                    self.ventilationData6.append(ventilation)
                    self.effTempData6.append(self.calculateEffectiveTemperature(ventilationRecord: ventilation))
                }
            }
            if self.ventilationData1.count > 0 {
                self.floor1Button.isEnabled = true
                self.floor1Button.backgroundColor = .link
                self.floor1StatusButton.isHidden = false
                self.floor1StatusButton.isEnabled = true
            }
            if self.ventilationData2.count > 0 {
                self.floor2Button.isEnabled = true
                self.floor2Button.backgroundColor = .link
                self.floor2StatusButton.isHidden = false
                self.floor2StatusButton.isEnabled = true
            }
            if self.ventilationData3.count > 0 {
                self.floor3Button.isEnabled = true
                self.floor3Button.backgroundColor = .link
                self.floor3StatusButton.isHidden = false
                self.floor3StatusButton.isEnabled = true
            }
            if self.ventilationData4.count > 0 {
                self.floor4Button.isEnabled = true
                self.floor4Button.backgroundColor = .link
                self.floor4StatusButton.isHidden = false
                self.floor4StatusButton.isEnabled = true
            }
            if self.ventilationData5.count > 0 {
                self.floor5Button.isEnabled = true
                self.floor5Button.backgroundColor = .link
                self.floor5StatusButton.isHidden = false
                self.floor5StatusButton.isEnabled = true
            }
            if self.ventilationData6.count > 0 {
                self.floor6Button.isEnabled = true
                self.floor6Button.backgroundColor = .link
                self.floor6StatusButton.isHidden = false
                self.floor6StatusButton.isEnabled = true
            }
            SVProgressHUD.dismiss()
        }
    }
    
    func calculateEffectiveTemperature (ventilationRecord : Ventilation) -> Float {

        let averageSuhu = (ventilationRecord.pintuBlowerSuhu + ventilationRecord.pintuCellDeckSuhu) / 2
        let averageRh = Float(ventilationRecord.pintuBlowerRh + ventilationRecord.pintuCellDeckRh) / 2
        let dewPointTemperature = averageSuhu - ((100 - averageRh) / 5)
        let wetBulbTemperature = averageSuhu - ((averageSuhu - dewPointTemperature) / 3)
        let averageWindSpeed = Float(ventilationRecord.pintuBlowerSpeed + ventilationRecord.pintuCellDeckSpeed) / 2
        
        //Effective Temperature Constants & Calculation
        let c : Float = 0.7
        let d : Float = 43
        let e : Float = 0.5
        let effectiveTemperature1 = 0.794 * averageSuhu + 0.25 * wetBulbTemperature + 0.70
        let effectiveTemperature2 = c * (d - averageSuhu)
        let effectiveTemperature3 = pow(averageWindSpeed,e) - pow(0.2,e)
        let effectiveTemperature = effectiveTemperature1 - effectiveTemperature2 * effectiveTemperature3
        
        return effectiveTemperature
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is VentilationDataDetailsViewController
        {
            let vc = segue.destination as? VentilationDataDetailsViewController
            vc?.floor = selectedFloor
            vc?.floorDetail = selectedFloorDetail
            vc?.data = selectedDataArray
            vc?.effTempArray = selectedEffTempArray
            vc?.farmName = farmName
            vc?.delegate = self
            
        }
        else if segue.destination is VentilationDataStatusViewController
        {
            let vc = segue.destination as? VentilationDataStatusViewController
            vc?.floor = selectedFloor
            vc?.floorDetail = selectedFloorDetail
            vc?.data = selectedDataArray
            vc?.effTempArray = selectedEffTempArray
            vc?.farmName = farmName
        }
        else if segue.destination is VentilationTableViewController
        {
            let vc = segue.destination as? VentilationTableViewController
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.cycleNumber = cycleNumber
            vc?.numberOfFloors = numberOfFloors
            vc?.dataArray = ventilationData
        }
    }
}
