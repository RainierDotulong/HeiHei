//
//  ListrikDataTableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/10/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import SVProgressHUD
import NotificationBannerSwift
import UIEmptyState

class ListrikDataTableViewCell : UITableViewCell {
    //listrikDataCell
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var kWhLabel: UILabel!
    @IBOutlet var reporterLabel: UILabel!
}

class ListrikDataTableViewController: UITableViewController, UIEmptyStateDataSource, UIEmptyStateDelegate, UISearchResultsUpdating {
    
    //Variables Received From Previous VC
    var farmName : String = ""
    var fullName : String = ""
    var loginClass : String = ""
    var cycleNumber : Int = 0
    var numberOfFloors : Int  = 0

    @IBOutlet var navItem: UINavigationItem!
    
    var dataArray : [Listrik] = [Listrik]()
    var filteredDataArray : [Listrik] = [Listrik]()
    var dateArray : [String] = [String]()
    var selectedData : Listrik = Listrik(id: "", timestamp: 0, kWh: 0, reporterName: "")
    
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
        
        for data in dataArray {
            let date = Date(timeIntervalSince1970: data.timestamp )
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: date)
            
            dateArray.append(stringDate)
        }
        
        //Pull to Refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:  #selector(refresh), for: .valueChanged)
        self.refreshControl = refreshControl
        
        let ListrikRecordChangeNotification = Notification.Name("listrikRecordChanged")
        NotificationCenter.default.addObserver(self, selector: #selector(listrikRecordChanged(_:)), name: ListrikRecordChangeNotification, object: nil)
        
        tableView.reloadData()
        reloadEmptyState()
    }
    
    @objc func refresh() {
        print("Refresh")
        getDataFromServer(pullDownRefresh : true)
    }
    
    @objc func listrikRecordChanged(_ notification:Notification) {
        getDataFromServer(pullDownRefresh : false)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredDataArray.removeAll(keepingCapacity: false)

        let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchController.searchBar.text!)
        let array = (dateArray as NSArray).filtered(using: searchPredicate)
        let filteredDateArray = array as! [String]
        //construct Filtered Data Array
        for data in dataArray {
            for date in filteredDateArray {
                let dataDate = Date(timeIntervalSince1970: data.timestamp )
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short
                let stringDate = dateFormatter.string(from: dataDate)
                
                if stringDate == date {
                    filteredDataArray.append(data)
                }
            }
        }
        self.tableView.reloadData()
        reloadEmptyState()
    }
    
    func getDataFromServer(pullDownRefresh : Bool) {
        if pullDownRefresh == false {
            SVProgressHUD.show()
        }
        Firestore.firestore().collection("\(farmName)\(cycleNumber)Listrik").order(by: "timestamp").addSnapshotListener { (querySnapshot, error) in
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

            self.dataArray = documents.compactMap { queryDocumentSnapshot -> Listrik? in
              return try? queryDocumentSnapshot.data(as: Listrik.self)
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
            
            self.tableView.reloadData()
            
            if pullDownRefresh == true {
                self.refreshControl?.endRefreshing()
            }
            else {
                SVProgressHUD.dismiss()
            }
        }
    }

    // MARK: Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if  (resultSearchController.isActive) {
            return filteredDataArray.count
        }
        else {
            return dataArray.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        func createProductCell(data : Listrik) -> ListrikDataTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "listrikDataCell", for: indexPath) as! ListrikDataTableViewCell
            
            let date = Date(timeIntervalSince1970: data.timestamp )
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: date)
            
            cell.dateLabel.text = "\(stringDate)"
            cell.kWhLabel.text = "Meteran: \(String(format: "%.2f", data.kWh)) KG"
            cell.reporterLabel.text = "Pelapor: \(data.reporterName)"
        
            return cell
        }
        if (resultSearchController.isActive) {
            return createProductCell(data: filteredDataArray[indexPath.row])
        }
        else {
            return createProductCell(data: dataArray[indexPath.row])
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
        self.performSegue(withIdentifier: "goToLapor", sender: self)
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
            vc?.selectedListrikRecord = selectedData
            vc?.isDatePick = isDatePick
            vc?.isEdit = isEdit
        }
    }
}
