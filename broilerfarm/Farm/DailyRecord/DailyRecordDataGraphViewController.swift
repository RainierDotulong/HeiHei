//
//  DailyRecordDataGraphViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 10/24/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import Charts

class DailyRecordDataGraphViewController : UIViewController, ChartViewDelegate {
    
    var farmName : String = ""
    var floor : String = ""
    var data : [DetailedDailyRecord] = [DetailedDailyRecord]()
    var selectedReferenceArray : [String] = [String]()
    var selectionIdentifier : String = ""
    
    @IBOutlet var navItem: UINavigationItem!
    @IBOutlet var chartView: LineChartView!
    
    var ageArray : [Int] = [Int]()
    var graphArray : [Double] = [Double]()
    var graphReferenceArray : [Double] = [Double]()
    
    override func viewDidLoad() {
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        navItem.title = selectionIdentifier
        constructGraphArrays()
    }
    
    func constructGraphArrays() {
        var isNegativeAge : Bool = false
        for i in data {
            if i.age < 0 {
                isNegativeAge = true
            }
            ageArray.append(i.age)
        }
        guard isNegativeAge == false else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Invalid Age", message: "Invalid Age Index, please contact Administrator", preferredStyle: .alert)
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
        
        for age in ageArray {
            graphReferenceArray.append(Double(selectedReferenceArray[age])!)
        }
        
        graphArray = [Double]()
        switch selectionIdentifier {
        case "BW (gram)":
            for i in data {
                graphArray.append(Double(i.bodyWeight))
            }
        case "ADG (gram)":
            for i in data {
                graphArray.append(Double(i.adg))
            }
        case "DEPLESI (ekor)":
            for i in data {
                graphArray.append(Double(i.totalDeplesi))
            }
        case "PAKAN (zak)":
            for i in data {
                graphArray.append(Double(i.totalPakanPakai))
            }
        case "FCR":
            for i in data {
                graphArray.append(Double(i.fcr))
            }
        case "POPULASI":
            for i in data {
                graphArray.append(Double(i.population))
            }
        default:
            for i in data {
                graphArray.append(Double(i.ip))
            }
        }
        
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
        
        let chartDataSet = LineChartDataSet(entries: lineDataEntry, label: selectionIdentifier)
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
}

