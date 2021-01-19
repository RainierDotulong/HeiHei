//
//  WholesaleTableViewController.swift
//  broilerfarm
//
//  Created by Rainier Dotulong on 1/4/21.
//  Copyright © 2021 Troy Dotulong. All rights reserved.
//

import UIKit
import UIEmptyState
import Firebase
import FirebaseFirestore
import FirebaseStorage
import SVProgressHUD
import JGProgressHUD
import NotificationBannerSwift
import QuickLook
import CoreLocation

class WholesaleTableViewCell: UITableViewCell {
    @IBOutlet var purchaseOrderNumberLabel: UILabel!
    @IBOutlet var perusahaanLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var contactLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var reporterNameLabel: UILabel!
}

class WholesaleTableViewController: UITableViewController, UIEmptyStateDataSource, UIEmptyStateDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredDataArray.removeAll(keepingCapacity: false)
        
        var names : [String] = [String]()
        for data in dataArray {
            if names.contains(data.name) == false {
                names.append(data.name)
            }
        }

        let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchController.searchBar.text!)
        let array = (names as NSArray).filtered(using: searchPredicate)
        let filteredProductNames = array as! [String]
        //construct Filtered Data Array
        for data in dataArray {
            for name in filteredProductNames {
                if data.name == name {
                    filteredDataArray.append(data)
                }
            }
        }
        self.tableView.reloadData()
        self.reloadEmptyState()
    }
    
    
    var loginClass : String = ""
    var fullName : String = ""
    var previousMenu : String = ""
    var isArchive : Bool = false
    var isCSVExport : Bool = false
    
    var allDataArray : [WholesalePurchaseOrder] = [WholesalePurchaseOrder]()
    var createdDataArray : [WholesalePurchaseOrder] = [WholesalePurchaseOrder]()
    var preppedDataArray : [WholesalePurchaseOrder] = [WholesalePurchaseOrder]()
    var qualityCheckedDataArray : [WholesalePurchaseOrder] = [WholesalePurchaseOrder]()
    var deliveryInProgressDataArray : [WholesalePurchaseOrder] = [WholesalePurchaseOrder]()
    var deliveredDataArray : [WholesalePurchaseOrder] = [WholesalePurchaseOrder]()
    var cancelledDataArray : [WholesalePurchaseOrder] = [WholesalePurchaseOrder]()
    var paidDataArray : [WholesalePurchaseOrder] = [WholesalePurchaseOrder]()
    var unpaidDataArray : [WholesalePurchaseOrder] = [WholesalePurchaseOrder]()
    
    var dataArray : [WholesalePurchaseOrder] = [WholesalePurchaseOrder]()
    var filteredDataArray : [WholesalePurchaseOrder] = [WholesalePurchaseOrder]()
    
    var filterBy : String = "None"
    
    var selectedPurchaseOrder : WholesalePurchaseOrder!
    
    var resultSearchController = UISearchController()
    
    //UI Empty State Variables
    var emptyStateTitle: NSAttributedString {
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor(red: 0.882, green: 0.890, blue: 0.859, alpha: 1.00),
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22)]
        return NSAttributedString(string: "No Purchase Orders Found", attributes: attrs)
    }
    
    var emptyStateImage: UIImage? {
        return UIImage(named: "redLogo")
    }
    
    @IBOutlet var navItem: UINavigationItem!
    @IBOutlet var newButton: UIBarButtonItem!
    @IBOutlet var actionButton: UIBarButtonItem!

    var csvPath : URL = URL(string: "https://www.globalxtreme.net")!
    
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    var filePath : String = ""
    
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

    }
    @objc func refresh() {
        print("Refresh")
        getDataFromServer(pullDownRefresh : true)
    }
    
    func getDataFromServer(pullDownRefresh : Bool) {
        if pullDownRefresh == false {
            SVProgressHUD.show()
        }
        var collection : String = ""
        if isArchive {
            collection = "wholesalePurchaseOrderArchive"
        }
        else {
            collection = "wholesalePurchaseOrders"
        }
        let db = Firestore.firestore()
        db.collection(collection).getDocuments() { (querySnapshot, err) in
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
                self.allDataArray.removeAll(keepingCapacity: false)
                self.createdDataArray.removeAll(keepingCapacity: false)
                self.preppedDataArray.removeAll(keepingCapacity: false)
                self.qualityCheckedDataArray.removeAll(keepingCapacity: false)
                self.deliveryInProgressDataArray.removeAll(keepingCapacity: false)
                self.deliveredDataArray.removeAll(keepingCapacity: false)
                self.cancelledDataArray.removeAll(keepingCapacity: false)
                self.paidDataArray.removeAll(keepingCapacity: false)
                self.unpaidDataArray.removeAll(keepingCapacity: false)
                
                for document in querySnapshot!.documents {
                    
                    var purchaseOrder : WholesalePurchaseOrder = WholesalePurchaseOrder(purchaseOrderNumber: "", name: "", address: "", phone: "", status: "", orderedItems: [WholesaleProduct](), orderedItemNotes: [String](), orderedItemQuantities: [Int](), realItems: [WholesaleProduct](), realItemNotes: [String](), realItemQuantities: [Float](), preppedBy: "", qualityCheckedBy: "", createdBy: "", timestamp: 0, isPaid: false)
                    
                    purchaseOrder.purchaseOrderNumber = document.documentID
                    purchaseOrder.name = document.data()["name"] as! String
                    purchaseOrder.address = document.data()["address"] as! String
                    purchaseOrder.phone = document.data()["phone"] as? String ?? ""
                    purchaseOrder.status = document.data()["status"] as! String
                    
                    let wholesaleProductNames : [String] = document.data()["wholesaleProductNames"] as! [String]
                    let wholesaleProductDescriptions : [String] = document.data()["wholesaleProductDescriptions"] as! [String]
                    let wholesaleProductPricePerUnits : [Int] = document.data()["wholesaleProductPricePerUnits"] as! [Int]
                    let wholesaleProductUnits : [String] = document.data()["wholesaleProductUnits"] as! [String]
                    let wholesaleProductCreatedBys : [String] = document.data()["wholesaleProductCreatedBys"] as! [String]
                    let wholesaleProductTimestamps : [Double] = document.data()["wholesaleProductTimestamps"] as! [Double]
                    var wholesaleProducts : [WholesaleProduct] = [WholesaleProduct]()
                    for i in 0..<wholesaleProductNames.count {
                        let wholesaleProductName = wholesaleProductNames[i]
                        let wholesaleProductDescription = wholesaleProductDescriptions[i]
                        let wholesaleProductPricePerUnit = wholesaleProductPricePerUnits[i]
                        let wholesaleProductUnit = wholesaleProductUnits[i]
                        let wholesaleProductCreatedBy = wholesaleProductCreatedBys[i]
                        let wholesaleProductTimestamp = wholesaleProductTimestamps[i]
                        let wholesaleProduct : WholesaleProduct = WholesaleProduct(name: wholesaleProductName, description: wholesaleProductDescription, pricePerUnit: wholesaleProductPricePerUnit, unit: wholesaleProductUnit, createdBy: wholesaleProductCreatedBy, timestamp: wholesaleProductTimestamp)
                        wholesaleProducts.append(wholesaleProduct)
                    }
                    
                    let realWholesaleProductNames : [String] = document.data()["realWholesaleProductNames"] as? [String] ?? [String]()
                    let realWholesaleProductDescriptions : [String] = document.data()["wholesaleProductDescriptions"] as? [String] ?? [String]()
                    let realWholesaleProductPricePerUnits : [Int] = document.data()["wholesaleProductPricePerUnits"] as? [Int] ?? [Int]()
                    let realWholesaleProductUnits : [String] = document.data()["wholesaleProductUnits"] as? [String] ?? [String]()
                    let realWholesaleProductCreatedBys : [String] = document.data()["wholesaleProductCreatedBys"] as? [String] ?? [String]()
                    let realWholesaleProductTimestamps : [Double] = document.data()["wholesaleProductTimestamps"] as? [Double] ?? [Double]()
                    var realWholesaleProducts : [WholesaleProduct] = [WholesaleProduct]()
                    for i in 0..<realWholesaleProductNames.count {
                        let wholesaleProductName = realWholesaleProductNames[i]
                        let wholesaleProductDescription = realWholesaleProductDescriptions[i]
                        let wholesaleProductPricePerUnit = realWholesaleProductPricePerUnits[i]
                        let wholesaleProductUnit = realWholesaleProductUnits[i]
                        let wholesaleProductCreatedBy = realWholesaleProductCreatedBys[i]
                        let wholesaleProductTimestamp = realWholesaleProductTimestamps[i]
                        let wholesaleProduct : WholesaleProduct = WholesaleProduct(name: wholesaleProductName, description: wholesaleProductDescription, pricePerUnit: wholesaleProductPricePerUnit, unit: wholesaleProductUnit, createdBy: wholesaleProductCreatedBy, timestamp: wholesaleProductTimestamp)
                        realWholesaleProducts.append(wholesaleProduct)
                    }
                    
                    purchaseOrder.orderedItems = wholesaleProducts
                    purchaseOrder.orderedItemNotes = document.data()["orderedItemNotes"] as? [String] ?? [String]()
                    purchaseOrder.orderedItemQuantities = document.data()["orderedItemQuantities"] as! [Int]
                    purchaseOrder.realItems = realWholesaleProducts
                    purchaseOrder.realItemNotes = document.data()["realItemNotes"] as? [String] ?? [String]()
                    purchaseOrder.realItemQuantities = document.data()["realItemQuantities"] as? [Float] ?? [Float]()
                    purchaseOrder.preppedBy = document.data()["preppedBy"] as? String ?? ""
                    purchaseOrder.qualityCheckedBy = document.data()["qualityCheckedBy"] as? String ?? ""
                    purchaseOrder.createdBy = document.data()["createdBy"] as! String
                    purchaseOrder.timestamp = document.data()["timestamp"] as! Double
                    purchaseOrder.isPaid = document.data()["isPaid"] as? Bool ?? false
                    
                    self.allDataArray.append(purchaseOrder)
                    
                    switch purchaseOrder.status {
                    case "Created":
                        self.createdDataArray.append(purchaseOrder)
                    case "Prepped":
                        self.preppedDataArray.append(purchaseOrder)
                    case "Quality Checked":
                        self.qualityCheckedDataArray.append(purchaseOrder)
                    case "Delivery In Progress":
                        self.deliveryInProgressDataArray.append(purchaseOrder)
                    case "Delivered":
                        self.deliveredDataArray.append(purchaseOrder)
                    case "Cancelled":
                        self.cancelledDataArray.append(purchaseOrder)
                    default :
                        print("Unknown Status")
                    }
                    
                    if purchaseOrder.isPaid {
                        self.paidDataArray.append(purchaseOrder)
                    }
                    else {
                        self.unpaidDataArray.append(purchaseOrder)
                    }
                    
                    switch self.filterBy {
                    case "None":
                        self.dataArray = self.allDataArray
                    case "Created":
                        self.dataArray = self.createdDataArray
                    case "Prepped":
                        self.dataArray = self.preppedDataArray
                    case "Quality Checked":
                        self.dataArray = self.qualityCheckedDataArray
                    case "Delivery In Progress":
                        self.dataArray = self.deliveryInProgressDataArray
                    case "Delivered":
                        self.dataArray = self.deliveredDataArray
                    case "Cancelled":
                        self.dataArray = self.cancelledDataArray
                    case "Quality Checked & Delivery In Progress":
                        self.dataArray.removeAll()
                        self.dataArray.append(contentsOf: self.qualityCheckedDataArray)
                        self.dataArray.append(contentsOf: self.deliveryInProgressDataArray)
                    case "Paid":
                        self.dataArray = self.paidDataArray
                    case "Unpaid":
                        self.dataArray = self.unpaidDataArray
                    default :
                        print("Unknown Filter")
                    }
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

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }
}
