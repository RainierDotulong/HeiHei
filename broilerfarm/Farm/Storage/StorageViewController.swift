//
//  StorageViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 10/31/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import Reachability
import SVProgressHUD
import NotificationBannerSwift

class StorageTableViewCell : UITableViewCell {
    @IBOutlet var namaBarangLabel: UILabel!
    @IBOutlet var jumlahSatuanLabel: UILabel!
    @IBOutlet var categoryImageView: UIImageView!
    @IBOutlet var dateLabel: UILabel!
    
}

class StorageViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating {
    
    //Initalize Variables passed from previous VC
    var farmName : String = ""
    var fullName : String = ""
    var cycleNumber : Int  = 0
    var loginClass : String = ""
    
    var action : String = ""
    
    var storageDataArray : [[String]] = [[String]]()
    var filteredTableViewDataArray : [[String]] = [[String]]()
    var tableViewDataArray : [[String]] = [[String]]()
    var tableViewTitleArray : [String] = [String]()
    
    @IBOutlet var storageTableView: UITableView!
    @IBOutlet var refreshButton: UIBarButtonItem!
    @IBOutlet var navItem: UINavigationItem!
    
    var resultSearchController = UISearchController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        // Add reachability observer
        if let reachability = AppDelegate.sharedAppDelegate()?.reachability
        {
            NotificationCenter.default.addObserver( self, selector: #selector( self.reachabilityChanged ),name: Notification.Name.reachabilityChanged, object: reachability )
        }
        
        //SearchBar
        resultSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.obscuresBackgroundDuringPresentation = false
            controller.searchBar.sizeToFit()

            storageTableView.tableHeaderView = controller.searchBar

            return controller
        })()
        
        // Reload the table
        storageTableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navItem.title = "Storage"
        getStorageDataFromServer(collection: "\(farmName)\(cycleNumber)Storage")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    @IBAction func refreshButtonPressed(_ sender: Any) {
        getStorageDataFromServer(collection: "\(farmName)\(cycleNumber)Storage")
    }
    @IBAction func masukButtonPressed(_ sender: Any) {
        resultSearchController.isActive = false
        action = "Storage Import"
        self.performSegue(withIdentifier: "goToStorageInput", sender: self)
    }
    @IBAction func keluarButtonPressed(_ sender: Any) {
        resultSearchController.isActive = false
        action = "Storage Export"
        self.performSegue(withIdentifier: "goToStorageInput", sender: self)
    }
    @IBAction func historyButtonPressed(_ sender: Any) {
        resultSearchController.isActive = false
        self.performSegue(withIdentifier: "goToHistory", sender: self)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredTableViewDataArray.removeAll(keepingCapacity: false)

        let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchController.searchBar.text!)
        let array = (tableViewTitleArray as NSArray).filtered(using: searchPredicate)
        let filteredTableViewTitleArray = array as! [String]
        //construct Filtered Data Array
        for data in tableViewDataArray {
            for title in filteredTableViewTitleArray {
                if data[0] == title {
                    filteredTableViewDataArray.append(data)
                }
            }
        }
        self.storageTableView.reloadData()
    }
    
    func getStorageDataFromServer(collection : String) {
        refreshButton.isEnabled = false
        SVProgressHUD.show()
        let db = Firestore.firestore()
        db.collection(collection).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                SVProgressHUD.dismiss()
            } else {
                self.tableViewTitleArray.removeAll(keepingCapacity: false)
                self.storageDataArray.removeAll(keepingCapacity: false)
                self.tableViewDataArray.removeAll(keepingCapacity: false)
                for document in querySnapshot!.documents {
                    var subArray = [String]()
                    //Setting up data
                    subArray.append(document.documentID)
                    subArray.append(document.data()["category"] as! String)
                    subArray.append(document.data()["jumlah"] as! String)
                    subArray.append(document.data()["namaBarang"] as! String)
                    subArray.append(document.data()["reporterName"] as! String)
                    subArray.append(document.data()["satuan"] as! String)
                    subArray.append(document.data()["action"] as! String)
                    self.storageDataArray.append(subArray)
                }
                if self.storageDataArray.count > 0 {
                    self.calculateTableViewData()
                }
                else {
                    self.storageTableView.reloadData()
                }
                SVProgressHUD.dismiss()
                self.refreshButton.isEnabled = true
            }
        }
    }
    
    func calculateTableViewData() {
        for i in 0...storageDataArray.count - 1 {
            if tableViewTitleArray.contains(storageDataArray[i][3]) {
                for j in 0...tableViewDataArray.count - 1 {
                    if storageDataArray[i][3] == tableViewDataArray[j][0] {
                        //Update Current Value
                        if storageDataArray[i][6] == "Storage Import" {
                            tableViewDataArray[j][1] = String(Float(tableViewDataArray[j][1])! + Float(storageDataArray[i][2])!)
                            //Rewrite newest Timestamp
                            tableViewDataArray[j][4] = storageDataArray[i][0]
                        }
                        else if storageDataArray[i][6] == "Storage Export" {
                            tableViewDataArray[j][1] = String(Float(tableViewDataArray[j][1])! - Float(storageDataArray[i][2])!)
                            //Rewrite newest Timestamp
                            tableViewDataArray[j][4] = storageDataArray[i][0]
                        }
                    }
                }
            }
            else {
                tableViewTitleArray.append(storageDataArray[i][3])
                if storageDataArray[i][6] == "Storage Import" {
                    tableViewDataArray.append([storageDataArray[i][3],String(Float(storageDataArray[i][2])!),storageDataArray[i][5],storageDataArray[i][1],storageDataArray[i][0]])
                }
                else if storageDataArray[i][6] == "Storage Export" {
                    tableViewDataArray.append([storageDataArray[i][3],String(Float(0) - Float(storageDataArray[i][2])!),storageDataArray[i][5],storageDataArray[i][1],storageDataArray[i][0]])
                }
            }
        }
        self.storageTableView.reloadData()
    }
    
    // Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if  (resultSearchController.isActive) {
            return filteredTableViewDataArray.count
        }
        else {
            return tableViewDataArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.rowHeight = UITableView.automaticDimension
        
        func createCells(dataArray : [String]) -> StorageTableViewCell {
            //Format Date from timestamp
            let documentIdArray = dataArray[4].components(separatedBy: "-")
            let date = Date(timeIntervalSince1970: TimeInterval(Double(documentIdArray[1])!))
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: date)
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "storageCell", for: indexPath) as! StorageTableViewCell
            
            cell.namaBarangLabel.text = dataArray[0]
            cell.jumlahSatuanLabel.text = dataArray[1] + " " +  dataArray[2]
            //Mark as red when low in stock
            if Float(dataArray[1])! < 0.5 {
                cell.jumlahSatuanLabel.textColor = .systemRed
            }
            else {
                cell.jumlahSatuanLabel.textColor = .black
            }
            cell.dateLabel.text = stringDate
            
            cell.categoryImageView.image = UIImage(named: CategoryToImage(category: dataArray[3]))

            return cell
        }
        
        if (resultSearchController.isActive) {
            return createCells(dataArray: filteredTableViewDataArray[indexPath.row])
        }
        else {
            return createCells(dataArray: tableViewDataArray[indexPath.row])
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if  (resultSearchController.isActive) {
            print(self.filteredTableViewDataArray[indexPath.row][0])
        }
        else {
            print(self.tableViewDataArray[indexPath.row][0])
        }
        
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    @objc private func reachabilityChanged( notification: NSNotification )
    {
        guard let reachability = notification.object as? Reachability else
        {
            return
        }

        if reachability.connection != .unavailable
        {
            if reachability.connection == .wifi
            {
                print("Reachable via WiFi")
                let banner = StatusBarNotificationBanner(title: "Connected via WiFi", style: .success)
                banner.show()
            }
            else
            {
                print("Reachable via Cellular")
                let banner = StatusBarNotificationBanner(title: "Connected via Cellular", style: .success)
                banner.show()
            }
        }
        else
        {
            print("Network not reachable")
            let banner = StatusBarNotificationBanner(title: "Not Connected", style: .danger)
            banner.show()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is StorageInputViewController
        {
            let vc = segue.destination as? StorageInputViewController
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.cycleNumber = cycleNumber
            vc?.action = action
        }
        else if segue.destination is StorageHistoryTableViewController
        {
            let vc = segue.destination as? StorageHistoryTableViewController
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.cycleNumber = cycleNumber
            vc?.loginClass = loginClass
        }
    }
}
