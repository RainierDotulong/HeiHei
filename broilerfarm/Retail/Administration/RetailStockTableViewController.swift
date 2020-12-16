//
//  RetailStockTableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 5/23/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import UIEmptyState
import Firebase
import FirebaseFirestore
import SVProgressHUD
import NotificationBannerSwift

class RetailStockTableViewCell : UITableViewCell {
    @IBOutlet var productNameLabel: UILabel!
    @IBOutlet var quantityUnitLabel: UILabel!
    @IBOutlet var authorLabel: UILabel!
}

class RetailStockTableViewController: UITableViewController, UIEmptyStateDataSource, UIEmptyStateDelegate, UISearchResultsUpdating {
    
    var fullName : String = ""
    var loginClass : String = ""
    var add : Bool = false
    
    var dataArray : [RetailStock] = [RetailStock]()
    var filteredDataArray : [RetailStock] = [RetailStock]()
    
    //UI Empty State Variables
    var emptyStateTitle: NSAttributedString {
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor(red: 0.882, green: 0.890, blue: 0.859, alpha: 1.00),
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22)]
        return NSAttributedString(string: "No Items Found", attributes: attrs)
    }
    
    var emptyStateImage: UIImage? {
        return UIImage(named: "redLogo")
    }
    
    var resultSearchController = UISearchController()

    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        // Set the data source and delegate
        self.emptyStateDataSource = self
        self.emptyStateDelegate = self
        
        // Remove seperator lines from empty cells
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        //Pull to Refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:  #selector(refresh), for: .valueChanged)
        self.refreshControl = refreshControl
        
        //SearchBar
        resultSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.obscuresBackgroundDuringPresentation = false
            controller.searchBar.sizeToFit()

            tableView.tableHeaderView = controller.searchBar

            return controller
        })()
        
        let RetailStockChangeNotification = Notification.Name("retailStockChanged")
        NotificationCenter.default.addObserver(self, selector: #selector(retailStockChanged(_:)), name: RetailStockChangeNotification, object: nil)
        
        getDataFromServer(pullDownRefresh : false)
    }
    
    @objc func refresh() {
        print("Refresh")
        getDataFromServer(pullDownRefresh : true)
    }
    
    @objc func retailStockChanged(_ notification:Notification) {
        print("Retail Stock Changed.")
        getDataFromServer(pullDownRefresh : false)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredDataArray.removeAll(keepingCapacity: false)
        
        var names : [String] = [String]()
        for data in dataArray {
            if names.contains(data.productName) == false {
                names.append(data.productName)
            }
        }

        let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchController.searchBar.text!)
        let array = (names as NSArray).filtered(using: searchPredicate)
        let filteredProductNames = array as! [String]
        //construct Filtered Data Array
        for data in dataArray {
            for productName in filteredProductNames {
                if data.productName == productName {
                    filteredDataArray.append(data)
                }
            }
        }
        self.tableView.reloadData()
        self.reloadEmptyState()
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func historyButtonPressed(_ sender: Any) {
        print("History Button Pressed")
        self.performSegue(withIdentifier: "goToStockOperationHistory", sender: self)
    }
    @IBAction func plusButtonPressed(_ sender: Any) {
        print("Plus")
        add = true
        self.performSegue(withIdentifier: "goToOperation", sender: self)
    }
    
    @IBAction func minusButtonPressed(_ sender: Any) {
        print("Minus")
        add = false
        self.performSegue(withIdentifier: "goToOperation", sender: self)
    }
    
    func getDataFromServer(pullDownRefresh : Bool) {
        if pullDownRefresh == false {
            SVProgressHUD.show()
        }
        let db = Firestore.firestore()
        db.collection("retailStock").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                if pullDownRefresh == true {
                    self.refreshControl?.endRefreshing()
                }
                else {
                    SVProgressHUD.dismiss()
                }
                let banner = StatusBarNotificationBanner(title: "Error getting documents", style: .danger)
                banner.show()
            } else {
                self.dataArray.removeAll(keepingCapacity: false)
                self.filteredDataArray.removeAll(keepingCapacity: false)
                
                for document in querySnapshot!.documents {
                    
                    var retailStock : RetailStock = RetailStock(productName: "", quantity: 0, unit: "", createdBy: "", timestamp: 0)
                    
                    retailStock.productName = document.documentID
                    retailStock.quantity = document.data()["quantity"] as! Float
                    retailStock.unit = document.data()["unit"] as! String
                    retailStock.createdBy = document.data()["createdBy"] as! String
                    retailStock.timestamp = document.data()["timestamp"] as! Double
                    
                    self.dataArray.append(retailStock)
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
        tableView.rowHeight = UITableView.automaticDimension
        
        func createCells(data : RetailStock) -> RetailStockTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RetailStockCell", for: indexPath) as! RetailStockTableViewCell
            
            let date = Date(timeIntervalSince1970: data.timestamp )
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: date)
            
            cell.productNameLabel.text = "\(data.productName)"
            cell.quantityUnitLabel.text = "Qty: \(String(format: "%.2f",data.quantity)) \(data.unit)"
            cell.authorLabel.text = "Last Update: \(stringDate) by: \(data.createdBy)"
            return cell
        }
        
        if (resultSearchController.isActive) {
            return createCells(data: filteredDataArray[self.filteredDataArray.count - indexPath.row - 1])
        }
        else {
            return createCells(data: dataArray[self.dataArray.count - indexPath.row - 1])
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is RetailStockOperationViewController
        {
            let vc = segue.destination as? RetailStockOperationViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.add = add
        }
        else if segue.destination is RetailStockOperationHistoryTableViewController
        {
            let vc = segue.destination as? RetailStockOperationHistoryTableViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
        }
    }
}
