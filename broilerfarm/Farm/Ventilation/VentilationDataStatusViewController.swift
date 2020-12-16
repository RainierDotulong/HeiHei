//
//  VentilationDataStatusViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 10/24/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import Charts
import Firebase
import FirebaseFirestore
import SVProgressHUD

class VentilationDataStatusViewController : UIViewController, ChartViewDelegate {
    var farmName : String = ""
    var floor : String = ""
    var floorDetail : FarmFloorDetail = FarmFloorDetail(farmName: "", cycleNumber: 0, floorNumber: 0, startingBodyWeight: 0, startingPopulation: 0, startTimestamp: 0, claimAge: 0, claimQuantity: 0, harvestedWeight: 0, harvestedQuantity: 0, pakanAwal: 0)
    var data : [Ventilation] = [Ventilation]()
    var effTempArray : [Float] = [Float]()
    
    var effTempReferenceArray : [String] = [String]()
    
    @IBOutlet var navBar: UINavigationItem!
    @IBOutlet var chartView: LineChartView!
    
    @IBOutlet var effTempView: UIView!
    @IBOutlet var effTempCurrentLabel: UILabel!
    @IBOutlet var effTempReferenceLabel: UILabel!
    @IBOutlet var effTempLastReportLabel: UILabel!
    
    var ageArray : [Int] = [Int]()
    var graphArray : [Double] = [Double]()
    var graphReferenceArray : [Double] = [Double]()
        
    override func viewDidLoad() {
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        navBar.title = farmName.uppercased() + "-LT." + floor
        print(effTempArray)
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
    
    func getReferenceData() {
        //Get Deplesi Reference Data from Firebase
        let cycle = Firestore.firestore().collection("reference").document(farmName.lowercased() + "floor" + floor)
        let zerosArray : [String] = ["0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0","0"]
        SVProgressHUD.show()
        cycle.getDocument { (document, error) in
            if let document = document, document.exists {
                let dataDescription = document.data()
                self.effTempReferenceArray = dataDescription!["effTemp"] as? [String] ?? zerosArray
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
    
    func constructArrays() {
        
        //Calculate Age
        let startDate = Date(timeIntervalSince1970: floorDetail.startTimestamp)
        let currentDate = Date(timeIntervalSince1970: data[data.count - 1].timestamp)
        let age : Int = Calendar.current.dateComponents([.day], from: startDate, to: currentDate).day!
        
        guard age < 36 else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "No Reference Document for current Age: \(age)" , message: "Please Contact Administrator", preferredStyle: .alert)
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
        
        //Determine Effective Temperature Status
        if abs(Float(effTempReferenceArray[age])! - Float(effTempArray[effTempArray.count - 1])) < 3 {
            effTempCurrentLabel.text = "Current: " + String(format: "%.2f", effTempArray[age]) + " °C"
            effTempReferenceLabel.text = "Reference: " + effTempReferenceArray[age] + " °C"
            effTempLastReportLabel.text = lastReport
            effTempView.backgroundColor = .systemGreen
        }
        else {
            effTempCurrentLabel.text = "Current: " + String(format: "%.2f", effTempArray[effTempArray.count - 1]) + " °C"
            effTempReferenceLabel.text = "Reference: " + effTempReferenceArray[age] + " °C"
            effTempLastReportLabel.text = lastReport
            effTempView.backgroundColor = .systemRed
        }
        
        constructGraphArrays()
    }
    
    func constructGraphArrays() {
        for i in data {
            //Calculate Age
            let startDate = Date(timeIntervalSince1970: floorDetail.startTimestamp)
            let currentDate = Date(timeIntervalSince1970: i.timestamp)
            let age : Int = Calendar.current.dateComponents([.day], from: startDate, to: currentDate).day!
            
            ageArray.append(age)
            graphReferenceArray.append(Double(effTempReferenceArray[age])!)
        }
        graphArray = effTempArray.compactMap(Double.init)
        
        customizeChart()
    }
    
    func customizeChart() {
        
        chartView.delegate = self
        
        chartView.chartDescription?.enabled = false

        chartView.leftAxis.enabled = false
        chartView.rightAxis.drawAxisLineEnabled = false
        chartView.xAxis.drawAxisLineEnabled = false
        
        chartView.drawBordersEnabled = false
        chartView.setScaleEnabled(true)
        
        var lineDataEntry : [ChartDataEntry] = []
        
        for i in 0..<graphArray.count {
            let dataPoint = ChartDataEntry(x: Double(ageArray[i]), y: graphArray[i])
            lineDataEntry.append(dataPoint)
        }
        
        var referenceLineDataEntry : [ChartDataEntry] = []
        
        for i in 0..<graphReferenceArray.count {
            let dataPoint = ChartDataEntry(x: Double(ageArray[i]), y: graphReferenceArray[i])
            referenceLineDataEntry.append(dataPoint)
        }
        
        let chartDataSet = LineChartDataSet(entries: lineDataEntry, label: "Eff Temp (°C)")
        chartDataSet.setColor(.systemRed)
        chartDataSet.setCircleColor(.systemRed)
        let chartReferenceDataSet = LineChartDataSet(entries: referenceLineDataEntry, label: "Reference")
        let chartData = LineChartData()
        chartData.addDataSet(chartDataSet)
        chartData.addDataSet(chartReferenceDataSet)
        
        chartView.leftAxis.enabled = true
        chartView.rightAxis.enabled = false
        chartView.xAxis.labelPosition = .bottom
        chartView.animate(xAxisDuration: 2, yAxisDuration: 2)
        chartView.data = chartData
    }
}
