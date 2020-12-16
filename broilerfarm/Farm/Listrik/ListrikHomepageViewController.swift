//
//  ListrikHomepageViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/6/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import SVProgressHUD
import NotificationBannerSwift
import Charts

class ListrikHomepageViewController: UIViewController, ChartViewDelegate {
    
    //Variables Received From Previous VC
    var farmName : String = ""
    var fullName : String = ""
    var loginClass : String = ""
    var cycleNumber : Int = 0
    var numberOfFloors : Int  = 0
    var hargaPerKwh : Float  = 0
    
    var dataArray : [Listrik] = [Listrik]()

    @IBOutlet var navItem: UINavigationItem!
    @IBOutlet var refreshButton: UIBarButtonItem!
    
    @IBOutlet var meteranAwalLabel: UILabel!
    @IBOutlet var meteranTerakhirLabel: UILabel!
    @IBOutlet var kWhTerpakaiLabel: UILabel!
    @IBOutlet var totalPengeluaranListrikLabel: UILabel!
    @IBOutlet var dataButton: UIButton!
    @IBOutlet var laporButton: UIButton!
    @IBOutlet var chartView: LineChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        navItem.title = "Listrik - \(farmName.uppercased()) \(cycleNumber)"
        
        getDataFromServer()
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    @IBAction func refreshButtonPressed(_ sender: Any) {
        getDataFromServer()
    }
    
    func getDataFromServer() {
        refreshButton.isEnabled = false
        SVProgressHUD.show()
        Firestore.firestore().collection("\(farmName)\(cycleNumber)Listrik").order(by: "timestamp").addSnapshotListener { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("No documents")
                SVProgressHUD.dismiss()
                self.refreshButton.isEnabled = true
                return
            }
            //Initialize Variables
            self.dataArray.removeAll(keepingCapacity: false)

            self.dataArray = documents.compactMap { queryDocumentSnapshot -> Listrik? in
              return try? queryDocumentSnapshot.data(as: Listrik.self)
            }
            SVProgressHUD.dismiss()
            self.refreshButton.isEnabled = true
            if self.dataArray.count > 0 {
                let firstData = self.dataArray.first!
                let currentData = self.dataArray.last!
                self.meteranAwalLabel.text = "Awal: \(String(format: "%.2f", firstData.kWh)) kWh"
                self.meteranTerakhirLabel.text = "Akhir: \(String(format: "%.2f", currentData.kWh)) kWh"
                
                let kwhTerpakai = currentData.kWh - firstData.kWh
                self.kWhTerpakaiLabel.text = "\(String(format: "%.2f", kwhTerpakai)) kWh"
                
                let totalCostListrik = kwhTerpakai * self.hargaPerKwh
                
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .decimal
                let formattedTotalCost = numberFormatter.string(from: NSNumber(value:totalCostListrik))
                
                self.totalPengeluaranListrikLabel.text = "Rp. \(formattedTotalCost!)"
                
                self.customizeChart()
            }
        }
    }
    
    @IBAction func laporButtonPressed(_ sender: Any) {
        print("Lapor")
        self.performSegue(withIdentifier: "goToLapor", sender: self)
    }
    
    @IBAction func dataButtonPressed(_ sender: Any) {
        print("Data")
        self.performSegue(withIdentifier: "goToData", sender: self)
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
        
        for i in 0..<dataArray.count {
            let dataPoint = ChartDataEntry(x: Double(i), y: Double(dataArray[i].kWh))
            lineDataEntry.append(dataPoint)
        }

        
        let chartDataSet = LineChartDataSet(entries: lineDataEntry, label: "kWh")
        chartDataSet.setColor(.systemRed)
        chartDataSet.setCircleColor(.systemRed)
        let chartData = LineChartData()
        chartData.addDataSet(chartDataSet)
        
        chartView.leftAxis.enabled = true
        chartView.rightAxis.enabled = false
        chartView.xAxis.labelPosition = .bottom
        chartView.animate(xAxisDuration: 2, yAxisDuration: 2)
        chartView.data = chartData
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is ListrikLaporViewController
        {
            let vc = segue.destination as? ListrikLaporViewController
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.cycleNumber = cycleNumber
            vc?.numberOfFloors = numberOfFloors
            vc?.isDatePick = false
            vc?.isEdit = false
        }
        else if segue.destination is ListrikDataTableViewController
        {
            let vc = segue.destination as? ListrikDataTableViewController
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.cycleNumber = cycleNumber
            vc?.numberOfFloors = numberOfFloors
            vc?.dataArray = dataArray
        }
    }
}
