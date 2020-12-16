//
//  DailyRecordDataStatusViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 10/23/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import SVProgressHUD

class DailyRecordDataStatusViewController : UIViewController {
    
    var farmName : String = ""
    var floor : String = ""
    var data : [DetailedDailyRecord] = [DetailedDailyRecord]()
    
    var bwReferenceArray : [String] = [String]()
    var adgReferenceArray : [String] = [String]()
    var deplesiReferenceArray : [String] = [String]()
    var pakanPakaiReferenceArray : [String] = [String]()
    var fcrReferenceArray : [String] = [String]()
    var populasiReferenceArray : [String] = [String]()
    var ipReferenceArray : [String] = [String]()
    
    var selectedReferenceArray : [String] = [String]()
    var selectionIdentifier : String = ""
    
    @IBOutlet var bwView: UIView!
    @IBOutlet var adgView: UIView!
    @IBOutlet var deplesiTotalView: UIView!
    @IBOutlet var pakanTotalView: UIView!
    @IBOutlet var fcrView: UIView!
    @IBOutlet var populasiView: UIView!
    @IBOutlet var ipView: UIView!
    
    @IBOutlet var bwCurrentLabel: UILabel!
    @IBOutlet var bwReferenceLabel: UILabel!
    @IBOutlet var bwLastReportLabel: UILabel!
    
    @IBOutlet var adgCurrentLabel: UILabel!
    @IBOutlet var adgReferenceLabel: UILabel!
    @IBOutlet var adgLastReportLabel: UILabel!
    
    @IBOutlet var deplesiCurrentLabel: UILabel!
    @IBOutlet var deplesiReferenceLabel: UILabel!
    @IBOutlet var deplesiLastReportLabel: UILabel!
    
    @IBOutlet var pakanCurrentLabel: UILabel!
    @IBOutlet var pakanReferenceLabel: UILabel!
    @IBOutlet var pakanLastReportLabel: UILabel!
    
    @IBOutlet var fcrCurrentLabel: UILabel!
    @IBOutlet var fcrReferenceLabel: UILabel!
    @IBOutlet var fcrLastReportLabel: UILabel!
    
    @IBOutlet var populasiCurrentLabel: UILabel!
    @IBOutlet var populasiReferenceLabel: UILabel!
    @IBOutlet var populasiLastReportLabel: UILabel!
    
    @IBOutlet var ipCurrentLabel: UILabel!
    @IBOutlet var ipReferenceLabel: UILabel!
    @IBOutlet var ipLastReportLabel: UILabel!
    
    @IBOutlet var navItem: UINavigationItem!
    override func viewDidLoad() {
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        navItem.title = farmName.uppercased() + "-LT." + floor
        
        getReferenceData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    func getReferenceData () {
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
                self.constructArrays()
                
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
    
    @IBAction func bwViewTapped(_ sender: Any) {
        selectedReferenceArray = bwReferenceArray
        selectionIdentifier = "BW (gram)"
        self.performSegue(withIdentifier: "goToGraph", sender: self)
        print("BW VIEW TAPPED")
    }
    @IBAction func adgViewTapped(_ sender: Any) {
        selectedReferenceArray = adgReferenceArray
        selectionIdentifier = "ADG (gram)"
        self.performSegue(withIdentifier: "goToGraph", sender: self)
        print("ADG VIEW TAPPED")
    }
    @IBAction func deplesiViewTapped(_ sender: Any) {
        selectedReferenceArray = deplesiReferenceArray
        selectionIdentifier = "DEPLESI (ekor)"
        self.performSegue(withIdentifier: "goToGraph", sender: self)
        print("DEPLESI VIEW TAPPED")
    }
    @IBAction func pakanViewTapped(_ sender: Any) {
        selectedReferenceArray = pakanPakaiReferenceArray
        selectionIdentifier = "PAKAN (zak)"
        self.performSegue(withIdentifier: "goToGraph", sender: self)
        print("PAKAN VIEW TAPPED")
    }
    @IBAction func fcrViewTapped(_ sender: Any) {
        selectedReferenceArray = fcrReferenceArray
        selectionIdentifier = "FCR"
        self.performSegue(withIdentifier: "goToGraph", sender: self)
        print("FCR VIEW TAPPED")
    }
    @IBAction func populasiViewTapped(_ sender: Any) {
        selectedReferenceArray = populasiReferenceArray
        selectionIdentifier = "POPULASI"
        self.performSegue(withIdentifier: "goToGraph", sender: self)
        print("POPULASI VIEW TAPPED")
    }
    @IBAction func ipViewTapped(_ sender: Any) {
        selectedReferenceArray = ipReferenceArray
        selectionIdentifier = "IP"
        self.performSegue(withIdentifier: "goToGraph", sender: self)
        print("IP VIEW TAPPED")
    }
    func constructArrays() {
        var deplesiRefArray : [Float] = [Float]()
        var pakanRefArray : [Float] = [Float]()
        
        for i in 0..<data.count {
            //Determine Deplesi Reference Array
            let deplesiReference = Float(deplesiReferenceArray[data[i].age])! * Float(data[i].population) / 100
            deplesiRefArray.append(deplesiReference)
            
            //Construct Pakan Reference array from pakan per gram reference
            let pakanPakaiPerEkor = Float(pakanPakaiReferenceArray[data[i].age])!
            let pakanPakai = pakanPakaiPerEkor * Float(data[i].population) / 1000 / 50
            pakanRefArray.append(pakanPakai)
        }

        determineStatus(deplesiRefTotal: deplesiRefArray.reduce(0,+), pakanRefTotal: pakanRefArray.reduce(0,+))
    }
    func determineStatus(deplesiRefTotal : Float, pakanRefTotal : Float) {
        print("Current Age: \(data[data.count - 1].age)")
        navItem.title = farmName.uppercased() + "-LT.\(floor) (\(data[data.count - 1].age) Hari)"
        guard data[data.count - 1].age < 46 else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "No Reference Document for current Age: \(data[data.count - 1].age)" , message: "Please Contact Administrator", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        //Get Last Report Date
        let date = Date(timeIntervalSince1970: data[data.count - 1].timestamp)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        let lastReport = dateFormatter.string(from: date)
        
        //Determine BW Status
        if Float(bwReferenceArray[data[data.count - 1].age])! - data[data.count - 1].bodyWeight < 0 {
            bwCurrentLabel.text = "Current: " + String(format: "%.2f", data[data.count - 1].bodyWeight) + " gram"
            bwReferenceLabel.text = "Reference: " + bwReferenceArray[data[data.count - 1].age] + " gram"
            bwLastReportLabel.text = lastReport
            bwView.backgroundColor = .systemGreen
        }
        else {
            bwCurrentLabel.text = "Current: " + String(format: "%.2f", data[data.count - 1].bodyWeight) + " gram"
            bwReferenceLabel.text = "Reference: " + bwReferenceArray[data[data.count - 1].age] + " gram"
            bwLastReportLabel.text = lastReport
            bwView.backgroundColor = .systemRed
        }
        
        //Determine ADG Status
        if Float(adgReferenceArray[data[data.count - 1].age])! - data[data.count - 1].adg < 0 {
            adgCurrentLabel.text = "Current: " + String(format: "%.2f", data[data.count - 1].adg) + " gram"
            adgReferenceLabel.text = "Reference: " + adgReferenceArray[data[data.count - 1].age] + " gram"
            adgLastReportLabel.text = lastReport
            adgView.backgroundColor = .systemGreen
        }
        else {
            adgCurrentLabel.text = "Current: " + String(format: "%.2f", data[data.count - 1].adg) + " gram"
            adgReferenceLabel.text = "Reference: " + adgReferenceArray[data[data.count - 1].age] + " gram"
            adgLastReportLabel.text = lastReport
            adgView.backgroundColor = .systemRed
        }
        
        //Determine Deplesi Total Status
        if deplesiRefTotal - Float(data[data.count - 1].totalDeplesi) > 0 {
            deplesiCurrentLabel.text = "Current: " + String(data[data.count - 1].totalDeplesi) + " ekor"
            deplesiReferenceLabel.text = "Reference: " + String(format: "%.0f",deplesiRefTotal) + " ekor"
            deplesiLastReportLabel.text = lastReport
            deplesiTotalView.backgroundColor = .systemGreen
        }
        else {
            deplesiCurrentLabel.text = "Current: " + String(data[data.count - 1].totalDeplesi) + " ekor"
            deplesiReferenceLabel.text = "Reference: " + String(format: "%.0f",deplesiRefTotal) + " ekor"
            deplesiLastReportLabel.text = lastReport
            deplesiTotalView.backgroundColor = .systemRed
        }
        
        //Determine Pakan Total Status
        if pakanRefTotal - Float(data[data.count - 1].totalPakanPakai) > 0 {
            pakanCurrentLabel.text = "Current: " + String(data[data.count - 1].totalPakanPakai) + " zak"
            pakanReferenceLabel.text = "Reference: " + String(format: "%.0f",pakanRefTotal) + " zak"
            pakanLastReportLabel.text = lastReport
            pakanTotalView.backgroundColor = .systemGreen
        }
        else {
            pakanCurrentLabel.text = "Current: " + String(data[data.count - 1].totalPakanPakai) + " zak"
            pakanReferenceLabel.text = "Reference: " + String(format: "%.0f",pakanRefTotal) + " zak"
            pakanLastReportLabel.text = lastReport
            pakanTotalView.backgroundColor = .systemRed
        }
        
        //Determine FCR Status
        if Float(fcrReferenceArray[data[data.count - 1].age])! - data[data.count - 1].fcr > 0 {
            fcrCurrentLabel.text = "Current: " + String(format: "%.2f", data[data.count - 1].fcr)
            fcrReferenceLabel.text = "Reference: " + fcrReferenceArray[data[data.count - 1].age]
            fcrLastReportLabel.text = lastReport
            fcrView.backgroundColor = .systemGreen
        }
        else {
            fcrCurrentLabel.text = "Current: " + String(format: "%.2f", data[data.count - 1].fcr)
            fcrReferenceLabel.text = "Reference: " + fcrReferenceArray[data[data.count - 1].age]
            fcrLastReportLabel.text = lastReport
            fcrView.backgroundColor = .systemRed
        }
        
        //Determine Populasi Status
        if Float(populasiReferenceArray[data[data.count - 1].age])! - Float(data[data.count - 1].population) < 0 {
            populasiCurrentLabel.text = "Current: " + String(data[data.count - 1].population)
            populasiReferenceLabel.text = "Reference: " + populasiReferenceArray[data[data.count - 1].age]
            populasiLastReportLabel.text = lastReport
            populasiView.backgroundColor = .systemGreen
        }
        else {
            populasiCurrentLabel.text = "Current: " + String(data[data.count - 1].population)
            populasiReferenceLabel.text = "Reference: " + populasiReferenceArray[data[data.count - 1].age]
            populasiLastReportLabel.text = lastReport
            populasiView.backgroundColor = .systemRed
        }
        
        //Determine IP Status
        if Float(ipReferenceArray[data[data.count - 1].age])! - Float(data[data.count - 1].ip) < 0 {
            ipCurrentLabel.text = "Current: " + String(format: "%.2f", data[data.count - 1].ip)
            ipReferenceLabel.text = "Reference: " + ipReferenceArray[data[data.count - 1].age]
            ipLastReportLabel.text = lastReport
            ipView.backgroundColor = .systemGreen
        }
        else {
            ipCurrentLabel.text = "Current: " + String(format: "%.2f", data[data.count - 1].ip)
            ipReferenceLabel.text = "Reference: " + ipReferenceArray[data[data.count - 1].age]
            ipLastReportLabel.text = lastReport
            ipView.backgroundColor = .systemRed
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is DailyRecordDataGraphViewController
        {
            let vc = segue.destination as? DailyRecordDataGraphViewController
            vc?.floor = floor
            vc?.farmName = farmName
            vc?.data = data
            vc?.selectedReferenceArray = selectedReferenceArray
            vc?.selectionIdentifier = selectionIdentifier
        }
    }
}
