//
//  RetailStockOperationHistoryTableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 5/25/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import UIEmptyState
import Firebase
import FirebaseFirestore
import SVProgressHUD
import NotificationBannerSwift
import QuickLook

class RetailStockOperationTableViewCell : UITableViewCell {
    @IBOutlet var productNameLabel: UILabel!
    @IBOutlet var quantityUnitLabel: UILabel!
    @IBOutlet var notesLabel: UILabel!
    @IBOutlet var authorLabel: UILabel!
    @IBOutlet var actionImageView: UIImageView!
}

class RetailStockOperationHistoryTableViewController: UITableViewController, UIEmptyStateDataSource, UIEmptyStateDelegate, UISearchResultsUpdating, QLPreviewControllerDataSource {
    
    var fullName : String = ""
    var loginClass : String = ""
    
    var selectedStockOperation : RetailStockOperation!
    
    var dataArray : [RetailStockOperation] = [RetailStockOperation]()
    var filteredDataArray : [RetailStockOperation] = [RetailStockOperation]()
    
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
    
    var csvPath : URL = URL(string: "https://www.globalxtreme.net")!

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
        
        getDataFromServer(pullDownRefresh : false)
    }
    
    @objc func refresh() {
        print("Refresh")
        getDataFromServer(pullDownRefresh : true)
    }
    
    @IBAction func shareButtonPressed(_ sender: Any) {
        let fileName : String = "Stock-History.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        var csvText = "Date,Add,Cancelled,Automatically Generated,Product Name,Quantity,Unit,Notes,Created By\n"
        for i in 0..<dataArray.count {
            let date = Date(timeIntervalSince1970: dataArray[i].timestamp)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let stringDate = dateFormatter.string(from: date).replacingOccurrences(of: ",", with: " ")
            let newLine = "\(stringDate),\(dataArray[i].add),\(dataArray[i].isCancelled),\(dataArray[i].isAutomaticallyGenerated),\(dataArray[i].productName),\(String(format: "%.2f",dataArray[i].quantity)),\(dataArray[i].unit),\(dataArray[i].notes),\(dataArray[i].createdBy)\n"
            csvText.append(newLine)
        }
        
        do {
            try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
            
            csvPath = path!
            let previewController = QLPreviewController()
            previewController.dataSource = self
            present(previewController, animated: true)
            
        } catch {
            
            print("Failed to create file")
            print("\(error)")
        }
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
    
    func getDataFromServer(pullDownRefresh : Bool) {
        if pullDownRefresh == false {
            SVProgressHUD.show()
        }
        let db = Firestore.firestore()
        db.collection("retailStockOperations").order(by: "timestamp").getDocuments() { (querySnapshot, err) in
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
                    
                    var retailStockOperation : RetailStockOperation = RetailStockOperation(document: "", add: false, isCancelled: false, isAutomaticallyGenerated: false, productName: "", quantity: 0, unit: "", notes: "", createdBy: "", timestamp: 0)
                    
                    retailStockOperation.document = document.documentID
                    retailStockOperation.add = document.data()["add"] as! Bool
                    retailStockOperation.isCancelled = document.data()["isCancelled"] as! Bool
                    retailStockOperation.isAutomaticallyGenerated = document.data()["isAutomaticallyGenerated"] as! Bool
                    retailStockOperation.productName = document.data()["productName"] as! String
                    retailStockOperation.quantity = document.data()["quantity"] as! Float
                    retailStockOperation.unit = document.data()["unit"] as? String ?? ""
                    retailStockOperation.notes = document.data()["notes"] as! String
                    retailStockOperation.createdBy = document.data()["createdBy"] as! String
                    retailStockOperation.timestamp = document.data()["timestamp"] as! Double
                    self.dataArray.append(retailStockOperation)
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
        
        func createCells(data : RetailStockOperation) -> RetailStockOperationTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RetailStockOperationCell", for: indexPath) as! RetailStockOperationTableViewCell
            
            let date = Date(timeIntervalSince1970: data.timestamp )
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: date)
            
            cell.productNameLabel.text = "\(data.productName)"
            cell.quantityUnitLabel.text = "Qty: \(String(format: "%.2f",data.quantity)) \(data.unit)"
            cell.notesLabel.text = "Notes: \(data.notes)"
            cell.authorLabel.text = "\(stringDate) by: \(data.createdBy)"
            if data.add {
                cell.actionImageView.image = UIImage(named: "import")
            }
            else {
                cell.actionImageView.image = UIImage(named: "export")
            }
            return cell
        }
        
        if (resultSearchController.isActive) {
            return createCells(data: filteredDataArray[self.filteredDataArray.count - indexPath.row - 1])
        }
        else {
            return createCells(data: dataArray[self.dataArray.count - indexPath.row - 1])
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (resultSearchController.isActive) {
            selectedStockOperation = filteredDataArray[self.filteredDataArray.count - indexPath.row - 1]
            resultSearchController.isActive = false
            self.performSegue(withIdentifier: "goToStockHistoryDetail", sender: self)
        }
        else {
            selectedStockOperation = dataArray[self.dataArray.count - indexPath.row - 1]
            self.performSegue(withIdentifier: "goToStockHistoryDetail", sender: self)
        }
    }
    
    //QLPreviewController Methods
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return csvPath as QLPreviewItem
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is RetailStockOperationDetailsViewController
        {
            let vc = segue.destination as? RetailStockOperationDetailsViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.selectedStockOperation = selectedStockOperation
        }
    }
}
