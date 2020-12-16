//
//  VentilationTableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/1/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import NotificationBannerSwift
import SVProgressHUD
import UIEmptyState

class VentilationHistoryTableViewCell : UITableViewCell {
    //ventilationHistoryCell
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var reporterLabel: UILabel!
}

class VentilationTableViewController: UITableViewController, UIEmptyStateDataSource, UIEmptyStateDelegate, UISearchResultsUpdating {
    
    var farmName : String = ""
    var fullName : String = ""
    var cycleNumber : Int = 0
    var numberOfFloors : Int  = 0
    var dataArray : [Ventilation] = [Ventilation]()
    
    @IBOutlet var navItem: UINavigationItem!
    
    var filteredDataArray : [Ventilation] = [Ventilation]()
    var selectedData : Ventilation = Ventilation(id: "", timestamp: 99999, ventilasiManual: 99999, ventilasiIntermittent: 99999, ventilasiOn: 99999, ventilasiOff: 99999, ventilasiHeater: 99999, inverter: 99999, inverterPinggir: 99999, inverterTengah: 99999, floor: 99999, reporterName: "", pintuBlowerSuhu: 99999, pintuBlowerSpeed: 99999, pintuBlowerRh: 99999, pintuBlowerNh3: 99999, pintuBlowerCo2: 99999, pintuCellDeckSuhu: 99999, pintuCellDeckSpeed: 99999, pintuCellDeckRh: 99999, pintuCellDeckNh3: 99999, pintuCellDeckCo2: 99999, luarKandangSuhu: 99999, luarKandangSpeed: 99999, luarKandangRh: 99999, luarKandangNh3: 99999, luarKandangCo2: 99999)
    var dateArray : [String] = [String]()
    
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

        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        navItem.title = "\(farmName.uppercased()) - \(cycleNumber)"
        
        for ventilation in dataArray {
            let date = Date(timeIntervalSince1970: ventilation.timestamp )
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: date)
            
            dateArray.append(stringDate)
        }
        
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
        
        //Pull to Refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:  #selector(refresh), for: .valueChanged)
        self.refreshControl = refreshControl
        
        let VentilationChangeNotification = Notification.Name("ventilationChanged")
        NotificationCenter.default.addObserver(self, selector: #selector(ventilationChanged(_:)), name: VentilationChangeNotification, object: nil)
        
    }
    
    @objc func refresh() {
        print("Refresh")
        getDataFromServer(pullDownRefresh : true)
    }
       
    @objc func ventilationChanged(_ notification:Notification) {
        print("Ventilation Changed")
        getDataFromServer(pullDownRefresh : false)
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        isDatePick = true
        isEdit = false
        selectedData = Ventilation(id: "", timestamp: 99999, ventilasiManual: 99999, ventilasiIntermittent: 99999, ventilasiOn: 99999, ventilasiOff: 99999, ventilasiHeater: 99999, inverter: 99999, inverterPinggir: 99999, inverterTengah: 99999, floor: 99999, reporterName: "", pintuBlowerSuhu: 99999, pintuBlowerSpeed: 99999, pintuBlowerRh: 99999, pintuBlowerNh3: 99999, pintuBlowerCo2: 99999, pintuCellDeckSuhu: 99999, pintuCellDeckSpeed: 99999, pintuCellDeckRh: 99999, pintuCellDeckNh3: 99999, pintuCellDeckCo2: 99999, luarKandangSuhu: 99999, luarKandangSpeed: 99999, luarKandangRh: 99999, luarKandangNh3: 99999, luarKandangCo2: 99999)
        self.performSegue(withIdentifier: "goToVentilation", sender: self)
    }
    
    func getDataFromServer(pullDownRefresh : Bool) {
        if pullDownRefresh == false {
            SVProgressHUD.show()
        }
        Firestore.firestore().collection("\(farmName)\(cycleNumber)VentilationData").order(by: "timestamp").addSnapshotListener { (querySnapshot, error) in
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
            
            self.dataArray = documents.compactMap { queryDocumentSnapshot -> Ventilation? in
              return try? queryDocumentSnapshot.data(as: Ventilation.self)
            }
            
            self.dateArray.removeAll(keepingCapacity: false)
            for data in self.dataArray {
                let date = Date(timeIntervalSince1970: data.timestamp )
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
        filteredDataArray.removeAll(keepingCapacity: false)

        let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchController.searchBar.text!)
        let array = (dateArray as NSArray).filtered(using: searchPredicate)
        let filteredDateArray = array as! [String]
        //construct Filtered Data Array
        for ventilation in dataArray {
            for date in filteredDateArray {
                let ventilationDate = Date(timeIntervalSince1970: ventilation.timestamp )
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short
                let stringDate = dateFormatter.string(from: ventilationDate)
                
                if stringDate == date {
                    filteredDataArray.append(ventilation)
                }
            }
        }
        self.tableView.reloadData()
        reloadEmptyState()
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if  (resultSearchController.isActive) {
            return filteredDataArray.count
        }
        else {
            return dataArray.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        func createCell(data : Ventilation) -> VentilationHistoryTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ventilationHistoryCell", for: indexPath) as! VentilationHistoryTableViewCell
            
            let date = Date(timeIntervalSince1970: data.timestamp )
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: date)
            
            cell.titleLabel.text = "LT.\(data.floor) - \(stringDate)"
            cell.reporterLabel.text = "Pelapor: \(data.reporterName)"
        
            return cell
        }
        if (resultSearchController.isActive) {
            return createCell(data: filteredDataArray[indexPath.row])
        }
        else {
            return createCell(data: dataArray[indexPath.row])
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if (resultSearchController.isActive) {
            selectedData = filteredDataArray[indexPath.row]
        }
        else {
            selectedData = dataArray[indexPath.row]
        }
        isDatePick = true
        isEdit = true
        self.performSegue(withIdentifier: "goToVentilation", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is VentilationViewController {
            let vc = segue.destination as? VentilationViewController
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.cycleNumber = cycleNumber
            vc?.numberOfFloors = numberOfFloors
            vc?.isEdit = isEdit
            vc?.isDatePick = isDatePick
            vc?.ventilation = selectedData
        }
    }
}
