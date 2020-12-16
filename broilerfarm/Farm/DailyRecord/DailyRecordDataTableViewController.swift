//
//  DailyRecordDataTableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 7/30/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import NotificationBannerSwift
import SVProgressHUD
import UIEmptyState

class DailyRecordDataTableViewCell: UITableViewCell {
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var bodyWeightLabel: UILabel!
    @IBOutlet var reportedByLabel: UILabel!
}

class DailyRecordDataTableViewController: UITableViewController, UIEmptyStateDataSource, UIEmptyStateDelegate, UISearchResultsUpdating {
    
    var farmName : String = ""
    var loginClass : String = ""
    var fullName : String = ""
    var cycleNumber : Int = 0
    var numberOfFloors : Int  = 0
    var filteredDailyRecordData : [DailyRecord] = [DailyRecord]()
    var dailyRecordData : [DailyRecord] = [DailyRecord]()
    
    var selectedDailyRecordData : DailyRecord = DailyRecord(timestamp: 0, deplesiMati: 0, deplesiCuling: 0, pakanPakai: 0, bodyWeight: 0, kesehatanAyam: "", notes: "", lantai: 0, reporterName: "")
    
    var dateArray : [String] = [String]()

    @IBOutlet var navItem: UINavigationItem!
    @IBOutlet var addButton: UIBarButtonItem!
    
    var isEdit : Bool = false
    var isDatePick : Bool = false
    
    var resultSearchController = UISearchController()
    
    //UI Empty State Variables
    var emptyStateTitle: NSAttributedString {
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor(red: 0.882, green: 0.890, blue: 0.859, alpha: 1.00),
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22)]
        return NSAttributedString(string: "No Data Available", attributes: attrs)
    }
    
    var emptyStateImage: UIImage? {
        return UIImage(named: "redLogo")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for dailyRecord in dailyRecordData {
            let date = Date(timeIntervalSince1970: dailyRecord.timestamp )
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: date)
            
            dateArray.append(stringDate)
        }
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        // Set the data source and delegate
        self.emptyStateDataSource = self
        self.emptyStateDelegate = self
        
        // Remove seperator lines from empty cells
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        //SearchBar
        resultSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.obscuresBackgroundDuringPresentation = false
            controller.searchBar.sizeToFit()

            tableView.tableHeaderView = controller.searchBar

            return controller
        })()
        
        navItem.title = "\(farmName.uppercased()) - \(cycleNumber)"
        
        //Pull to Refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:  #selector(refresh), for: .valueChanged)
        self.refreshControl = refreshControl
        
        let DailyRecordChangeNotification = Notification.Name("dailyRecordChanged")
        NotificationCenter.default.addObserver(self, selector: #selector(dailyRecordChanged(_:)), name: DailyRecordChangeNotification, object: nil)
        
        tableView.reloadData()
        reloadEmptyState()
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    @objc func refresh() {
        print("Refresh")
        getDataFromServer(pullDownRefresh : true)
    }
    
    @objc func dailyRecordChanged(_ notification:Notification) {
        getDataFromServer(pullDownRefresh : false)
    }
    
    func getDataFromServer(pullDownRefresh : Bool) {
        if pullDownRefresh == false {
            SVProgressHUD.show()
        }
        Firestore.firestore().collection("\(farmName)\(cycleNumber)DailyRecordings").order(by: "timestamp").addSnapshotListener { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
              print("No documents")
              if pullDownRefresh == true {
                  self.refreshControl?.endRefreshing()
              }
              else {
                  SVProgressHUD.dismiss()
              }
              return
            }
            
            self.dailyRecordData = documents.compactMap { queryDocumentSnapshot -> DailyRecord? in
              return try? queryDocumentSnapshot.data(as: DailyRecord.self)
            }
            
            self.dateArray.removeAll(keepingCapacity: false)
            for dailyRecord in self.dailyRecordData {
                let date = Date(timeIntervalSince1970: dailyRecord.timestamp )
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short
                let stringDate = dateFormatter.string(from: date)
                
                self.dateArray.append(stringDate)
            }
            
            if pullDownRefresh == true {
                self.refreshControl?.endRefreshing()
            }
            else {
                SVProgressHUD.dismiss()
            }
            self.tableView.reloadData()
            self.reloadEmptyState()
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredDailyRecordData.removeAll(keepingCapacity: false)

        let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchController.searchBar.text!)
        let array = (dateArray as NSArray).filtered(using: searchPredicate)
        let filteredDateArray = array as! [String]
        //construct Filtered Data Array
        for dailyRecord in dailyRecordData {
            for date in filteredDateArray {
                let dailyRecordDate = Date(timeIntervalSince1970: dailyRecord.timestamp )
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short
                let stringDate = dateFormatter.string(from: dailyRecordDate)
                
                if stringDate == date {
                    filteredDailyRecordData.append(dailyRecord)
                }
            }
        }
        self.tableView.reloadData()
        reloadEmptyState()
    }

    @IBAction func addButtonPressed(_ sender: Any) {
        isDatePick = true
        isEdit = false
        self.performSegue(withIdentifier: "goToDailyRecord", sender: self)
    }
    
    //MARK: Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if  (resultSearchController.isActive) {
            return filteredDailyRecordData.count
        }
        else {
            return dailyRecordData.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        func createProductCell(data : DailyRecord) -> DailyRecordDataTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "dailyRecordDataCell", for: indexPath) as! DailyRecordDataTableViewCell
            
            let date = Date(timeIntervalSince1970: data.timestamp )
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: date)
            
            cell.dateLabel.text = "LT.\(data.lantai) - \(stringDate)"
            cell.bodyWeightLabel.text = "Body Weight: \(String(format: "%.2f", data.bodyWeight)) KG"
            cell.reportedByLabel.text = "Pelapor: \(data.reporterName)"
        
            return cell
        }
        if (resultSearchController.isActive) {
            return createProductCell(data: filteredDailyRecordData[indexPath.row])
        }
        else {
            return createProductCell(data: dailyRecordData[indexPath.row])
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if (resultSearchController.isActive) {
            selectedDailyRecordData = filteredDailyRecordData[indexPath.row]
        }
        else {
            selectedDailyRecordData = dailyRecordData[indexPath.row]
        }
        isDatePick = true
        isEdit = true
        self.performSegue(withIdentifier: "goToDailyRecord", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is DailyRecordViewController {
            let vc = segue.destination as? DailyRecordViewController
            vc?.farmName = farmName
            vc?.loginClass = loginClass
            vc?.fullName = fullName
            vc?.cycleNumber = cycleNumber
            vc?.numberOfFloors = numberOfFloors
            vc?.isEdit = isEdit
            vc?.isDatePick = isDatePick
            vc?.selectedDailyRecordData = selectedDailyRecordData
        }
    }
}
