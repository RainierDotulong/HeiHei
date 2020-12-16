//
//  RetailPurchaseOrdersTableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 4/22/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
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

class RetailPurchaseOrdersTableViewCell : UITableViewCell {
    @IBOutlet var purchaseOrderNumber: UILabel!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var deliverByLabel: UILabel!
    @IBOutlet var deliveryContactLabel: UILabel!
    @IBOutlet var deliveryAddressLabel: UILabel!
    @IBOutlet var deliveryZoneLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var createdByLabel: UILabel!
    @IBOutlet var statusImageView: UIImageView!
}

class RetailPurchaseOrdersTableViewController: UITableViewController, UIEmptyStateDataSource, UIEmptyStateDelegate, UISearchResultsUpdating, QLPreviewControllerDataSource {
    
    var loginClass : String = ""
    var fullName : String = ""
    var previousMenu : String = ""
    var isArchive : Bool = false
    var isCSVExport : Bool = false
    
    var isNewPurchaseOrder : Bool = true
    
    var allDataArray : [RetailPurchaseOrder] = [RetailPurchaseOrder]()
    var createdDataArray : [RetailPurchaseOrder] = [RetailPurchaseOrder]()
    var preppedDataArray : [RetailPurchaseOrder] = [RetailPurchaseOrder]()
    var qualityCheckedDataArray : [RetailPurchaseOrder] = [RetailPurchaseOrder]()
    var deliveryInProgressDataArray : [RetailPurchaseOrder] = [RetailPurchaseOrder]()
    var deliveredDataArray : [RetailPurchaseOrder] = [RetailPurchaseOrder]()
    var cancelledDataArray : [RetailPurchaseOrder] = [RetailPurchaseOrder]()
    var paidDataArray : [RetailPurchaseOrder] = [RetailPurchaseOrder]()
    var unpaidDataArray : [RetailPurchaseOrder] = [RetailPurchaseOrder]()
    
    var dataArray : [RetailPurchaseOrder] = [RetailPurchaseOrder]()
    var filteredDataArray : [RetailPurchaseOrder] = [RetailPurchaseOrder]()
    
    var filterBy : String = "None"
    
    var selectedPurchaseOrder : RetailPurchaseOrder!
    
    var resultSearchController = UISearchController()
    
    var hud = JGProgressHUD(style: .dark)
        
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
        
        //Add long press recognizer
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress(longPressGestureRecognizer:)))
        self.view.addGestureRecognizer(longPressRecognizer)
        
        //SearchBar
        resultSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.obscuresBackgroundDuringPresentation = false
            controller.searchBar.sizeToFit()

            tableView.tableHeaderView = controller.searchBar

            return controller
        })()
        
        let PurchaseOrderCreationNotification = Notification.Name("purchaseOrderCreated")
        NotificationCenter.default.addObserver(self, selector: #selector(purchaseOrderCreated(_:)), name: PurchaseOrderCreationNotification, object: nil)
        
        if previousMenu == "Administration" && isArchive == false {
            navItem.title = "Purchase Order(s)"
            newButton.isEnabled = true
            newButton.image = UIImage(systemName: "plus")
            actionButton.image = UIImage(systemName: "slider.horizontal.3")
        }
        else if previousMenu == "Administration" && isArchive {
            navItem.title = "Archive"
            newButton.isEnabled = false
            newButton.image = UIImage(systemName: "plus")
            actionButton.image = UIImage(systemName: "slider.horizontal.3")
        }
        else if previousMenu == "Retail"{
            if filterBy == "Created" {
                navItem.title = "Preparation Tickets"
                newButton.isEnabled = false
                newButton.image = UIImage(systemName: "plus")
                actionButton.isEnabled = false
            }
            else if filterBy == "Quality Checked & Delivery In Progress" {
                navItem.title = "Deliveries"
                newButton.isEnabled = true
                newButton.image = UIImage(systemName: "mappin.and.ellipse")
                actionButton.image = UIImage(systemName: "location.north")
            }
        }
        getDataFromServer(pullDownRefresh : false)
    }
    
    @objc func purchaseOrderCreated(_ notification:Notification) {
        print("Purchase Order Successfully Created.")
        getDataFromServer(pullDownRefresh : false)
    }
    
    @objc func refresh() {
        print("Refresh")
        getDataFromServer(pullDownRefresh : true)
    }
    
    @objc func longPress(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        
        guard loginClass == "superadmin" else {
            print("Not Superadmin")
            return
        }

        if longPressGestureRecognizer.state == UIGestureRecognizer.State.began {
            let touchPoint = longPressGestureRecognizer.location(in: self.view)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                
                if (resultSearchController.isActive) {
                    print("Long Press \(filteredDataArray[self.filteredDataArray.count - indexPath.row - 1].purchaseOrderNumber)")
                    let alert = UIAlertController(title: "Mark as Paid?", message: "Mark Purchase Order as Paid", preferredStyle: .alert)
                    
                    let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                        print("Ok button tapped")
                        self.markPurchaseOrderAsPaid(purchaseOrderNumber: self.filteredDataArray[self.filteredDataArray.count - indexPath.row - 1].purchaseOrderNumber)
                    })
                    
                    let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
                        print("Cancel button tapped")
                    }
                    
                    alert.addAction(ok)
                    alert.addAction(cancel)
                    
                    self.present(alert, animated: true, completion: nil)
                }
                else {
                    print("Long Press \(dataArray[self.dataArray.count - indexPath.row - 1].purchaseOrderNumber)")
                    let alert = UIAlertController(title: "Mark as Paid?", message: "Mark Purchase Order as Paid", preferredStyle: .alert)
                    
                    let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                        print("Ok button tapped")
                        self.markPurchaseOrderAsPaid(purchaseOrderNumber: self.dataArray[self.dataArray.count - indexPath.row - 1].purchaseOrderNumber)
                    })
                    
                    let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
                        print("Cancel button tapped")
                    }
                    
                    alert.addAction(ok)
                    alert.addAction(cancel)
                    
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
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

    @IBAction func backButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func shareButtonPressed(_ sender: Any) {
        let dialogMessage = UIAlertController(title: "Export", message: "", preferredStyle: .alert)
        
        let summary = UIAlertAction(title: "Summary", style: .default, handler: { (action) -> Void in
            print("Summary button tapped")
            self.createCsv(detailed: false)
        })
        let detailed = UIAlertAction(title: "Detailed", style: .default, handler: { (action) -> Void in
            print("Detailed button tapped")
            self.createCsv(detailed: true)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: { (action) -> Void in
            print("Cancel button tapped")
        })
        
        dialogMessage.addAction(summary)
        dialogMessage.addAction(detailed)
        dialogMessage.addAction(cancel)
        
        self.present(dialogMessage, animated: true, completion: nil)
        
    }
    @IBAction func actionButtonPressed(_ sender: Any) {
        if previousMenu == "Administration" {
            createFilterDialog ()
        }
        else if previousMenu == "Retail"{
            if filterBy == "Created" {
                print("Preparation Ticket Actions")
            }
            else if filterBy == "Quality Checked & Delivery In Progress" {
                print("Deliveries Action")
                self.performSegue(withIdentifier: "goToGoogleMaps", sender: self)
            }
        }
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        if previousMenu == "Retail" && filterBy == "Quality Checked & Delivery In Progress" {
            print("Auto Assign Delivery Zones")

            let alert = UIAlertController(title: "Auto Assign Delivery Zones", message: "Specify number of driver(s)", preferredStyle: .alert)
            
            alert.addTextField { (textField) in
                textField.placeholder = "6"
                textField.keyboardType = .numberPad
            }
            
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
                let textField = alert.textFields![0]
                print(textField.text ?? "")
                guard textField.text ?? "" != ""  else {
                    print("Incomplete Data")
                    let dialogMessage = UIAlertController(title: "Incomplete Data", message: "Text Field Empty", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                        print("Ok button tapped")
                    })
                    dialogMessage.addAction(ok)
                    self.present(dialogMessage, animated: true, completion: nil)
                    return
                }
                guard Int(textField.text ?? "0") ?? 0 != 0  else {
                    print("Invalid Data")
                    let dialogMessage = UIAlertController(title: "Invalid Data", message: "Integer Value Required.", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                        print("Ok button tapped")
                    })
                    dialogMessage.addAction(ok)
                    self.present(dialogMessage, animated: true, completion: nil)
                    return
                }
                print("AUTO ASSIGN ZONES")
                self.autoAssignDeliveryZones(numberOfDrivers: Int(textField.text ?? "0") ?? 0, data: self.dataArray)
            })
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
                print("Cancel button tapped")
            }
            
            alert.addAction(ok)
            alert.addAction(cancel)
            
            self.present(alert, animated: true, completion: nil)
        }
        else {
            isNewPurchaseOrder = true
            self.performSegue(withIdentifier: "goToNewPurchaseOrder", sender: self)
        }
    }
    
    func autoAssignDeliveryZones (numberOfDrivers: Int, data : [RetailPurchaseOrder]) {
        let startingCoordinate = CLLocation(latitude: -7.973884, longitude: 112.596732)
        struct poZone {
            var distanceFromStart : CLLocationDistance
            var purchaseOrder : RetailPurchaseOrder
            var deliveryZone : String
        }
        var poZones : [poZone] = [poZone]()
        for i in data {
            let coordinate = CLLocation(latitude: i.deliveryLatitude, longitude: i.deliveryLongitude)
            let distanceInMeters = coordinate.distance(from: startingCoordinate) // result is in meters
            poZones.append(poZone(distanceFromStart: distanceInMeters, purchaseOrder: i, deliveryZone : ""))
        }
        //Sort from closest distance from start
        poZones.sort { $0.distanceFromStart < $1.distanceFromStart }
        
        //Get Unique Distances
        var uniqueDistances : [CLLocationDistance] = [CLLocationDistance]()
        for i in 0..<poZones.count {
            if uniqueDistances.contains(poZones[i].distanceFromStart) == false {
                uniqueDistances.append(poZones[i].distanceFromStart)
            }
        }
        print(uniqueDistances)
        print(uniqueDistances.count)
    }
    
    func createFilterDialog() {
        let dialogMessage = UIAlertController(title: "Filter By", message: "Select Filter Type", preferredStyle: .alert)
        
        let none = UIAlertAction(title: "None", style: .default, handler: { (action) -> Void in
            print("None Stock button tapped")
            self.filterBy = "None"
            self.dataArray = self.allDataArray
            self.tableView.reloadData()
            self.reloadEmptyStateForTableView(self.tableView)
            self.navItem.title = "Purchase Orders"
        })
        let created = UIAlertAction(title: "Created", style: .default, handler: { (action) -> Void in
            print("Created Stock button tapped")
            self.filterBy = "Created"
            self.dataArray = self.createdDataArray
            self.tableView.reloadData()
            self.reloadEmptyStateForTableView(self.tableView)
            self.navItem.title = "Created PO(s)"
        })
        let prepped = UIAlertAction(title: "Prepped", style: .default, handler: { (action) -> Void in
            print("Prepped button tapped")
            self.filterBy = "Prepped"
            self.dataArray = self.preppedDataArray
            self.tableView.reloadData()
            self.reloadEmptyStateForTableView(self.tableView)
            self.navItem.title = "Prepped PO(s)"
        })
        let qualityChecked = UIAlertAction(title: "Quality Checked", style: .default, handler: { (action) -> Void in
            print("Quality Checked button tapped")
            self.filterBy = "Quality Checked"
            self.dataArray = self.qualityCheckedDataArray
            self.tableView.reloadData()
            self.reloadEmptyStateForTableView(self.tableView)
            self.navItem.title = "Quality Checked PO(s)"
        })
        let deliveryInProgress = UIAlertAction(title: "Delivery In Progress", style: .default, handler: { (action) -> Void in
            print("Delivery In Progress button tapped")
            self.filterBy = "Delivery In Progress"
            self.dataArray = self.deliveryInProgressDataArray
            self.tableView.reloadData()
            self.reloadEmptyStateForTableView(self.tableView)
            self.navItem.title = "Delivery In Progress PO(s)"
        })
        let delivered = UIAlertAction(title: "Delivered", style: .default, handler: { (action) -> Void in
            print("Delivered button tapped")
            self.filterBy = "Delivered"
            self.dataArray = self.deliveredDataArray
            self.tableView.reloadData()
            self.reloadEmptyStateForTableView(self.tableView)
            self.navItem.title = "Delivered PO(s)"
        })
        let cancelled = UIAlertAction(title: "Cancelled", style: .default, handler: { (action) -> Void in
            print("Cancelled button tapped")
            self.filterBy = "Cancelled"
            self.dataArray = self.cancelledDataArray
            self.tableView.reloadData()
            self.reloadEmptyStateForTableView(self.tableView)
            self.navItem.title = "Cancelled PO(s)"
        })
        let paid = UIAlertAction(title: "Paid", style: .default, handler: { (action) -> Void in
            print("Cancelled button tapped")
            self.filterBy = "Paid"
            self.dataArray = self.paidDataArray
            self.tableView.reloadData()
            self.reloadEmptyStateForTableView(self.tableView)
            self.navItem.title = "Paid PO(s)"
        })
        let unpaid = UIAlertAction(title: "Unpaid", style: .default, handler: { (action) -> Void in
            print("Unpaid button tapped")
            self.filterBy = "Unpaid"
            self.dataArray = self.unpaidDataArray
            self.tableView.reloadData()
            self.reloadEmptyStateForTableView(self.tableView)
            self.navItem.title = "Unpaid PO(s)"
        })
        
        dialogMessage.addAction(none)
        dialogMessage.addAction(created)
        dialogMessage.addAction(prepped)
        dialogMessage.addAction(qualityChecked)
        dialogMessage.addAction(deliveryInProgress)
        dialogMessage.addAction(delivered)
        dialogMessage.addAction(cancelled)
        dialogMessage.addAction(paid)
        dialogMessage.addAction(unpaid)
        
        self.present(dialogMessage, animated: true, completion: nil)
    }
    
    func createCsv(detailed: Bool) {
        isCSVExport = true
        var fileName : String = ""
        if detailed {
            fileName = "PurchaseOrders-Detailed.csv"
        }
        else {
            fileName = "PurchaseOrders.csv"
        }
        
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        var csvText = ""
        if detailed {
            csvText = "Date,Date Delivered,PO#,Name,Address,Status,Delivery Contact,Delivery Contact Phone,Delivery Address,Deliver Latitude,Delivery Longitude,Delivery Zone,Delivery Number,Order Total (Rp.),Total KG,Payment Method,Marketing\n"
        }
        else {
            csvText = "Date,Date Delivered,PO#,Name,Status,Delivery Zone,Delivery Number,Order Total (Rp.),Total KG,Payment Method,Marketing\n"
        }
        
        let count = dataArray.count
        
        if count > 0 {
            struct soldItemTotal {
                var itemName : String
                var quantities : [Float]
                var values : [Float]
                var unit : String
            }
            var soldItemNames : [String] = [String]()
            var soldItemTotals : [soldItemTotal] = [soldItemTotal]()
            for i in 0..<dataArray.count {
                //Calculate Total
                var total : Float = 0
                var tonase : Float = 0
                if dataArray[i].realItems.isEmpty == false {
                    var subtotals : [Float] = [Float]()
                    var quantities : [Float] = [Float]()
                    for j in 0..<dataArray[i].realItems.count {
                        subtotals.append(Float(dataArray[i].realItems[j].pricePerUnit) * dataArray[i].realItemQuantities[j])
                        if dataArray[i].realItems[j].unit.uppercased() == "KG" {
                            quantities.append(dataArray[i].realItemQuantities[j])
                        }
                    }
                    total = subtotals.reduce(0,+) - Float(dataArray[i].discount) + Float(dataArray[i].deliveryFee)
                    tonase = quantities.reduce(0,+)
                }
                else {
                    total = 0
                }
                
                let date = Date(timeIntervalSince1970: Double(dataArray[i].purchaseOrderNumber.components(separatedBy: "-")[1])!)
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                let stringDate = dateFormatter.string(from: date).replacingOccurrences(of: ",", with: " ")
                
                var stringDeliveryDate : String = ""
                if dataArray[i].status == "Delivered" {
                    let deliveryDate = Date(timeIntervalSince1970: dataArray[i].deliveryTimestamp)
                    stringDeliveryDate = dateFormatter.string(from: deliveryDate).replacingOccurrences(of: ",", with: " ")
                }
                else {
                    stringDeliveryDate = "-"
                }
                
                if detailed {
                    let newLine = "\(stringDate),\(stringDeliveryDate),\(dataArray[i].purchaseOrderNumber),\(dataArray[i].name),\((dataArray[i].address).replacingOccurrences(of: ",", with: " ")),\(dataArray[i].status),\(dataArray[i].deliveryContactName),\(dataArray[i].deliveryContactPhone),\(dataArray[i].deliveryAddress.replacingOccurrences(of: ",", with: " ")),\(dataArray[i].deliveryLatitude),\(dataArray[i].deliveryLongitude),\(dataArray[i].deliveryZone),\(dataArray[i].deliveryNumber),\(String(format: "%.0f", total)),\(String(format: "%.2f", tonase)),\(dataArray[i].paymentMethod),\(dataArray[i].marketing)\n"

                    csvText.append(newLine)
                    csvText.append(",,,,,,,,,,Item Name,Quantity,Unit,Price Per Unit,Subtotal\n")
                    
                    if dataArray[i].realItems.isEmpty == false {
                        for j in 0..<dataArray[i].realItems.count {
                            let subtotal = Float(dataArray[i].realItems[j].pricePerUnit) * dataArray[i].realItemQuantities[j]
                            let newLine = ",,,,,,,,,,\(dataArray[i].realItems[j].name),\(dataArray[i].realItemQuantities[j]),\(dataArray[i].realItems[j].unit),\(dataArray[i].realItems[j].pricePerUnit),\(subtotal)\n"
                            csvText.append(newLine)
                            
                            if soldItemNames.contains(dataArray[i].realItems[j].name) {
                                for k in 0..<soldItemTotals.count {
                                    if soldItemTotals[k].itemName == dataArray[i].realItems[j].name {
                                        soldItemTotals[k].quantities.append(dataArray[i].realItemQuantities[j])
                                        soldItemTotals[k].values.append(subtotal - Float(dataArray[i].discount) + Float(dataArray[i].deliveryFee))
                                    }
                                }
                            }
                            else {
                                //New Item
                                soldItemNames.append(dataArray[i].realItems[j].name)
                                let soldItemTotal : soldItemTotal = soldItemTotal(itemName: dataArray[i].realItems[j].name, quantities: [dataArray[i].realItemQuantities[j]], values: [subtotal - Float(dataArray[i].discount) + Float(dataArray[i].deliveryFee)], unit: dataArray[i].realItems[j].unit)
                                soldItemTotals.append(soldItemTotal)
                            }
                        }
                    }
                }
                else {
                    let newLine = "\(stringDate),\(stringDeliveryDate),\(dataArray[i].purchaseOrderNumber),\(dataArray[i].name),\(dataArray[i].status),\(dataArray[i].deliveryZone),\(dataArray[i].deliveryNumber),\(String(format: "%.0f", total)),\(String(format: "%.2f", tonase)),\(dataArray[i].paymentMethod),\(dataArray[i].marketing)\n"

                    csvText.append(newLine)
                }
            }
            
            if detailed {
                csvText.append(",,,,,,,,,,,,,,\n")
                csvText.append(",,,,,,,,,,,SOLD PRODUCTS,,,\n")
                csvText.append(",,,,,,,,,,,Product Name,Quantity,Unit,Value (Rp.)\n")
                for soldItemTotal in soldItemTotals {
                    let newLine = ",,,,,,,,,,,\(soldItemTotal.itemName),\(soldItemTotal.quantities.reduce(0,+)),\(soldItemTotal.unit),\(soldItemTotal.values.reduce(0,+))\n"
                    csvText.append(newLine)
                }
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
            
        } else {
            print("There is no data to export")
        }
    }
    
    func getDataFromServer(pullDownRefresh : Bool) {
        if pullDownRefresh == false {
            SVProgressHUD.show()
        }
        var collection : String = ""
        if isArchive {
            collection = "retailPurchaseOrdersArchive"
        }
        else {
            collection = "retailPurchaseOrders"
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
                    
                    var purchaseOrder : RetailPurchaseOrder = RetailPurchaseOrder(purchaseOrderNumber: "", name: "", address: "", phone: "", marketing: "", status: "", deliveryContactName: "", deliveryContactPhone: "", deliveryAddress: "", deliveryLatitude: 0, deliveryLongitude: 0, deliverByDate: 0, paymentMethod: "", orderedItems: [RetailProduct](), orderedItemNotes: [String](), orderedItemQuantities: [Int](), realItems: [RetailProduct](), realItemNotes: [String](), realItemQuantities: [Float](), preppedBy: "", qualityCheckedBy: "", deliveredBy: "", deliveryZone: "", deliveryNumber: 0, deliveryTimestamp: 0, deliveryFee: 0, discount : 0, createdBy: "", timestamp: 0, isPaid: false)
                    
                    purchaseOrder.purchaseOrderNumber = document.documentID
                    purchaseOrder.name = document.data()["name"] as! String
                    purchaseOrder.address = document.data()["address"] as! String
                    purchaseOrder.phone = document.data()["phone"] as? String ?? ""
                    purchaseOrder.marketing = document.data()["marketing"] as? String ?? ""
                    purchaseOrder.status = document.data()["status"] as! String
                    purchaseOrder.deliveryContactName = document.data()["deliveryContactName"] as! String
                    purchaseOrder.deliveryContactPhone = document.data()["deliveryContactPhone"] as! String
                    purchaseOrder.deliveryAddress = document.data()["deliveryAddress"] as! String
                    purchaseOrder.deliveryLatitude = document.data()["deliveryLatitude"] as! Double
                    purchaseOrder.deliveryLongitude = document.data()["deliveryLongitude"] as! Double
                    purchaseOrder.deliverByDate = document.data()["deliverByDate"] as! Double
                    purchaseOrder.paymentMethod = document.data()["paymentMethod"] as? String ?? ""
                    
                    let retailProductNames : [String] = document.data()["retailProductNames"] as! [String]
                    let retailProductDescriptions : [String] = document.data()["retailProductDescriptions"] as! [String]
                    let retailProductPricePerUnits : [Int] = document.data()["retailProductPricePerUnits"] as! [Int]
                    let retailProductUnits : [String] = document.data()["retailProductUnits"] as! [String]
                    let retailProductCreatedBys : [String] = document.data()["retailProductCreatedBys"] as! [String]
                    let retailProductTimestamps : [Double] = document.data()["retailProductTimestamps"] as! [Double]
                    var retailProducts : [RetailProduct] = [RetailProduct]()
                    for i in 0..<retailProductNames.count {
                        let retailProductName = retailProductNames[i]
                        let retailProductDescription = retailProductDescriptions[i]
                        let retailProductPricePerUnit = retailProductPricePerUnits[i]
                        let retailProductUnit = retailProductUnits[i]
                        let retailProductCreatedBy = retailProductCreatedBys[i]
                        let retailProductTimestamp = retailProductTimestamps[i]
                        let retailProduct : RetailProduct = RetailProduct(name: retailProductName, description: retailProductDescription, pricePerUnit: retailProductPricePerUnit, unit: retailProductUnit, createdBy: retailProductCreatedBy, timestamp: retailProductTimestamp)
                        retailProducts.append(retailProduct)
                    }
                    
                    let realRetailProductNames : [String] = document.data()["realRetailProductNames"] as? [String] ?? [String]()
                    let realRetailProductDescriptions : [String] = document.data()["retailProductDescriptions"] as? [String] ?? [String]()
                    let realRetailProductPricePerUnits : [Int] = document.data()["retailProductPricePerUnits"] as? [Int] ?? [Int]()
                    let realRetailProductUnits : [String] = document.data()["retailProductUnits"] as? [String] ?? [String]()
                    let realRetailProductCreatedBys : [String] = document.data()["retailProductCreatedBys"] as? [String] ?? [String]()
                    let realRetailProductTimestamps : [Double] = document.data()["retailProductTimestamps"] as? [Double] ?? [Double]()
                    var realRetailProducts : [RetailProduct] = [RetailProduct]()
                    for i in 0..<realRetailProductNames.count {
                        let retailProductName = realRetailProductNames[i]
                        let retailProductDescription = realRetailProductDescriptions[i]
                        let retailProductPricePerUnit = realRetailProductPricePerUnits[i]
                        let retailProductUnit = realRetailProductUnits[i]
                        let retailProductCreatedBy = realRetailProductCreatedBys[i]
                        let retailProductTimestamp = realRetailProductTimestamps[i]
                        let retailProduct : RetailProduct = RetailProduct(name: retailProductName, description: retailProductDescription, pricePerUnit: retailProductPricePerUnit, unit: retailProductUnit, createdBy: retailProductCreatedBy, timestamp: retailProductTimestamp)
                        realRetailProducts.append(retailProduct)
                    }
                    
                    purchaseOrder.orderedItems = retailProducts
                    purchaseOrder.orderedItemNotes = document.data()["orderedItemNotes"] as? [String] ?? [String]()
                    purchaseOrder.orderedItemQuantities = document.data()["orderedItemQuantities"] as! [Int]
                    purchaseOrder.realItems = realRetailProducts
                    purchaseOrder.realItemNotes = document.data()["realItemNotes"] as? [String] ?? [String]()
                    purchaseOrder.realItemQuantities = document.data()["realItemQuantities"] as? [Float] ?? [Float]()
                    purchaseOrder.preppedBy = document.data()["preppedBy"] as? String ?? ""
                    purchaseOrder.qualityCheckedBy = document.data()["qualityCheckedBy"] as? String ?? ""
                    purchaseOrder.deliveredBy = document.data()["deliveredBy"] as? String ?? ""
                    purchaseOrder.deliveryZone = document.data()["deliveryZone"] as? String ?? "UNASSIGNED"
                    purchaseOrder.deliveryNumber = document.data()["deliveryNumber"] as? Int ?? 0
                    purchaseOrder.deliveryTimestamp = document.data()["deliveryTimestamp"] as? Double ?? 0
                    purchaseOrder.deliveryFee = document.data()["deliveryFee"] as? Int ?? 0
                    purchaseOrder.discount = document.data()["discount"] as? Int ?? 0
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
    
    func moveDocumentToArchive (purchaseOrder : RetailPurchaseOrder) {
        print("Archive \(purchaseOrder.purchaseOrderNumber)")
        //Construct Arrays from RetailProduct
        var retailProductNames : [String] = [String]()
        var retailProductDescriptions : [String] = [String]()
        var retailProductPricePerUnits : [Int] = [Int]()
        var retailProductUnits : [String] = [String]()
        var retailProductCreatedBys : [String] = [String]()
        var retailProductTimestamps : [Double] = [Double]()
        
        var realRetailProductNames : [String] = [String]()
        var realRetailProductDescriptions : [String] = [String]()
        var realRetailProductPricePerUnits : [Int] = [Int]()
        var realRetailProductUnits : [String] = [String]()
        var realRetailProductCreatedBys : [String] = [String]()
        var realRetailProductTimestamps : [Double] = [Double]()
        
        for i in purchaseOrder.orderedItems {
            retailProductNames.append(i.name)
            retailProductDescriptions.append(i.description)
            retailProductPricePerUnits.append(i.pricePerUnit)
            retailProductUnits.append(i.unit)
            retailProductCreatedBys.append(i.createdBy)
            retailProductTimestamps.append(i.timestamp)
        }
        
        for i in purchaseOrder.realItems {
            realRetailProductNames.append(i.name)
            realRetailProductDescriptions.append(i.description)
            realRetailProductPricePerUnits.append(i.pricePerUnit)
            realRetailProductUnits.append(i.unit)
            realRetailProductCreatedBys.append(i.createdBy)
            realRetailProductTimestamps.append(i.timestamp)
        }
        
        //Write PO Document in Archive Collection
        let doc = Firestore.firestore().collection("retailPurchaseOrdersArchive").document(purchaseOrder.purchaseOrderNumber)
        doc.setData([
            "name" : purchaseOrder.name,
            "address" : purchaseOrder.address,
            "phone" : purchaseOrder.phone,
            "status" : purchaseOrder.status,
            "deliveryContactName" : purchaseOrder.deliveryContactName,
            "deliveryContactPhone" : purchaseOrder.deliveryContactPhone,
            "deliveryAddress" : purchaseOrder.deliveryAddress,
            "deliveryLatitude" : purchaseOrder.deliveryLatitude,
            "deliveryLongitude" : purchaseOrder.deliveryLongitude,
            "deliverByDate" : purchaseOrder.deliverByDate,
            "paymentMethod" : purchaseOrder.paymentMethod,

            //RetailProduct
            "retailProductNames" : retailProductNames,
            "retailProductDescriptions" : retailProductDescriptions,
            "retailProductPricePerUnits" : retailProductPricePerUnits,
            "retailProductUnits" : retailProductUnits,
            "retailProductCreatedBys" : retailProductCreatedBys,
            "retailProductTimestamps" : retailProductTimestamps,
            "orderedItemNotes" : purchaseOrder.orderedItemNotes,
            "orderedItemQuantities" : purchaseOrder.orderedItemQuantities,
            
            //RealRetailProduct
            "realRetailProductNames" : realRetailProductNames,
            "realRetailProductDescriptions" : realRetailProductDescriptions,
            "realRetailProductPricePerUnits" : realRetailProductPricePerUnits,
            "realRetailProductUnits" : realRetailProductUnits,
            "realRetailProductCreatedBys" : realRetailProductCreatedBys,
            "realRetailProductTimestamps" : realRetailProductTimestamps,
            "realItemNotes" : purchaseOrder.realItemNotes,
            "realItemQuantities" : purchaseOrder.realItemQuantities,
            
            "preppedBy" : purchaseOrder.preppedBy,
            "qualityCheckedBy" : purchaseOrder.qualityCheckedBy,
            "deliveredBy" : purchaseOrder.deliveredBy,
            "deliveryZone" : purchaseOrder.deliveryZone,
            "deliveryNumber" : purchaseOrder.deliveryNumber,
            "deliveryFee" : purchaseOrder.deliveryFee,
            "discount" : purchaseOrder.discount,
            "deliveryTimestamp" : purchaseOrder.deliveryTimestamp,
            "createdBy" : purchaseOrder.createdBy,
            "timestamp" : purchaseOrder.timestamp,
            "isPaid" : purchaseOrder.isPaid
            
        ]) { err in
            if let err = err {
                print("Error writing new archive product document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error writing New Archive Purchase Order Document", style: .danger)
                banner.show()
                self.getDataFromServer(pullDownRefresh: false)
                
            } else {
                print("Archive Purchase Order successfully Created!")
                //Delete Document in Collection
                print("Delete \(purchaseOrder.purchaseOrderNumber)")
                self.deletePurchaseOrder(purchaseOrder: purchaseOrder)
            }
        }
    }
    
    func deletePurchaseOrder(purchaseOrder : RetailPurchaseOrder) {
        print("Deleting \(purchaseOrder.purchaseOrderNumber)")
        let doc = Firestore.firestore().collection("retailPurchaseOrders").document(purchaseOrder.purchaseOrderNumber)
        doc.delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
                SVProgressHUD.dismiss()
                let banner = StatusBarNotificationBanner(title: "Error removing document", style: .danger)
                banner.show()
                self.getDataFromServer(pullDownRefresh: false)
            } else {
                print("Document successfully removed!")
            }
        }
    }
    
    func updateQualityCheckStatusPurchaseOrder (purchaseOrderNumber : String) {
        //Set Local Data Values
        if (self.resultSearchController.isActive) {
            for i in 0..<self.filteredDataArray.count {
                if purchaseOrderNumber == self.filteredDataArray[i].purchaseOrderNumber {
                    self.filteredDataArray[i].status = "Quality Checked"
                    self.filteredDataArray[i].qualityCheckedBy = self.fullName
                }
            }
            for i in 0..<self.dataArray.count {
                if purchaseOrderNumber == self.dataArray[i].purchaseOrderNumber {
                    self.dataArray[i].status = "Quality Checked"
                    self.dataArray[i].qualityCheckedBy = self.fullName
                }
            }
        }
        else {
            for i in 0..<self.dataArray.count {
                if purchaseOrderNumber == self.dataArray[i].purchaseOrderNumber {
                    self.dataArray[i].status = "Quality Checked"
                    self.dataArray[i].qualityCheckedBy = self.fullName
                }
            }
        }
        self.tableView.reloadData()
        self.reloadEmptyState()
        
        print("Quality Check Purchase Order")
        let doc = Firestore.firestore().collection("retailPurchaseOrders").document(purchaseOrderNumber)
        doc.updateData([
            "status" : "Quality Checked",
            "qualityCheckedBy" : fullName,
        ]) { err in
            if let err = err {
                print("Error writing new product document: \(err)")
                self.getDataFromServer(pullDownRefresh : false)
                let banner = StatusBarNotificationBanner(title: "Error writing New Purchase Order Document", style: .danger)
                banner.show()
            } else {
                print("Purchase Order successfully Updated!")
                let banner = StatusBarNotificationBanner(title: "Purchase Order Successfully Updated!", style: .success)
                banner.show()
            }
        }
    }
    
    func markPurchaseOrderAsPaid (purchaseOrderNumber : String) {
        //Set Local Data Values
        if (self.resultSearchController.isActive) {
            for i in 0..<self.filteredDataArray.count {
                if purchaseOrderNumber == self.filteredDataArray[i].purchaseOrderNumber {
                    self.filteredDataArray[i].isPaid = true
                }
            }
            for i in 0..<self.dataArray.count {
                if purchaseOrderNumber == self.dataArray[i].purchaseOrderNumber {
                    self.dataArray[i].isPaid = true
                }
            }
        }
        else {
            for i in 0..<self.dataArray.count {
                if purchaseOrderNumber == self.dataArray[i].purchaseOrderNumber {
                    self.dataArray[i].isPaid = true
                }
            }
        }
        self.tableView.reloadData()
        self.reloadEmptyState()
        
        print("Mark Purchase Order as Paid")
        var collection : String = ""
        if isArchive {
            collection = "retailPurchaseOrdersArchive"
        }
        else {
            collection = "retailPurchaseOrders"
        }
        let doc = Firestore.firestore().collection(collection).document(purchaseOrderNumber)
        doc.updateData([
            "isPaid" : true
        ]) { err in
            if let err = err {
                print("Error writing new product document: \(err)")
                self.getDataFromServer(pullDownRefresh : false)
                let banner = StatusBarNotificationBanner(title: "Error writing New Purchase Order Document", style: .danger)
                banner.show()
            } else {
                print("Purchase Order successfully Updated!")
                let banner = StatusBarNotificationBanner(title: "Purchase Order Successfully Updated!", style: .success)
                banner.show()
            }
        }
    }
    
    func updateCancelledStatusPurchaseOrder (purchaseOrder : RetailPurchaseOrder) {
        //Set Local Data Values
        if (self.resultSearchController.isActive) {
            for i in 0..<self.filteredDataArray.count {
                if purchaseOrder.purchaseOrderNumber == self.filteredDataArray[i].purchaseOrderNumber {
                    self.filteredDataArray[i].status = "Cancelled"
                }
            }
            for i in 0..<self.dataArray.count {
                if purchaseOrder.purchaseOrderNumber == self.dataArray[i].purchaseOrderNumber {
                    self.dataArray[i].status = "Cancelled"
                }
            }
        }
        else {
            for i in 0..<self.dataArray.count {
                if purchaseOrder.purchaseOrderNumber == self.dataArray[i].purchaseOrderNumber {
                    self.dataArray[i].status = "Cancelled"
                }
            }
        }
        self.tableView.reloadData()
        self.reloadEmptyState()
        
        print("Cancel Purchase Order")
        let doc = Firestore.firestore().collection("retailPurchaseOrders").document(purchaseOrder.purchaseOrderNumber)
        doc.updateData([
            "status" : "Cancelled",
        ]) { err in
            if let err = err {
                print("Error writing new product document: \(err)")
                self.getDataFromServer(pullDownRefresh : false)
                let banner = StatusBarNotificationBanner(title: "Error writing New Purchase Order Document", style: .danger)
                banner.show()
            } else {
                print("Purchase Order successfully Updated!")
                let banner = StatusBarNotificationBanner(title: "Purchase Order Successfully Updated!", style: .success)
                banner.show()
            }
        }
        
        //Exception when PO is Created (Don't Increment Stock)
        guard purchaseOrder.status != "Created" else {
            print("Created Purchase Order")
            return
        }
        
        //MARK: Check for Stock Document Existance
        for i in 0..<purchaseOrder.realItems.count {
            var currentQuantity : Float = 0
            let cycle = Firestore.firestore().collection("retailStock").document(purchaseOrder.realItems[i].name)
            cycle.getDocument { (document, error) in
                if let document = document, document.exists {
                    print("Stock Document exists")
                    currentQuantity = document.data()!["quantity"] as! Float
                    //Decrement Stock Document
                    var newQuantity : Float = 0
                    newQuantity = currentQuantity + purchaseOrder.realItemQuantities[i]
                    self.updateStock(productName: purchaseOrder.realItems[i].name, quantity: newQuantity)
                    
                } else {
                    print("Stock Document does not exist")
                    currentQuantity = 0
                    self.createNewStock(productName: purchaseOrder.realItems[i].name, quantity: purchaseOrder.realItemQuantities[i], unit: purchaseOrder.realItems[i].unit)
                }
            }
            
            //MARK: Create Stock Operation Document
            self.createStockOperation(add: true, productName: purchaseOrder.realItems[i].name, quantity: purchaseOrder.realItemQuantities[i], unit: purchaseOrder.realItems[i].unit, notes: "AUTO (\(purchaseOrder.purchaseOrderNumber) Cancel)")
        }
    }
    
    func updateStock(productName : String, quantity : Float) {
        let doc = Firestore.firestore().collection("retailStock").document(productName)
        doc.updateData([
            "quantity" : quantity,
            "createdBy" : fullName,
            "timestamp" : NSDate().timeIntervalSince1970
        ]) { err in
            if let err = err {
                print("Error updating stock: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error Performing Stock Update", style: .danger)
                banner.show()
            } else {
                print("Stock successfully Updated!")
                let RetailStockChangeNotification = Notification.Name("retailStockChanged")
                NotificationCenter.default.post(name: RetailStockChangeNotification, object: nil)
            }
        }
    }
    
    func createNewStock(productName : String, quantity : Float, unit : String) {
        let doc = Firestore.firestore().collection("retailStock").document(productName)
        doc.setData([
            "quantity" : quantity,
            "unit" : unit,
            "createdBy" : fullName,
            "timestamp" : NSDate().timeIntervalSince1970
        ]) { err in
            if let err = err {
                print("Error writing new stock document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error Performing Stock Creation", style: .danger)
                banner.show()
            } else {
                print("Stock Document successfully Created!")
                let RetailStockChangeNotification = Notification.Name("retailStockChanged")
                NotificationCenter.default.post(name: RetailStockChangeNotification, object: nil)
            }
        }
    }
    
    func createStockOperation(add : Bool, productName : String, quantity : Float, unit : String, notes : String) {
        let doc = Firestore.firestore().collection("retailStockOperations").document()
        doc.setData([
            "add" : add,
            "isCancelled" : false,
            "isAutomaticallyGenerated" : true,
            "productName" : productName,
            "quantity" : quantity,
            "unit" : unit,
            "notes" : notes,
            "createdBy" : fullName,
            "timestamp" : NSDate().timeIntervalSince1970
        ]) { err in
            if let err = err {
                print("Error writing new product document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error Performing Operation", style: .danger)
                banner.show()
            } else {
                print("Stock Operation Document successfully Created!")
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
        
        func createCells(data : RetailPurchaseOrder) -> RetailPurchaseOrdersTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RetailPurchaseOrderCell", for: indexPath) as! RetailPurchaseOrdersTableViewCell
            
            let date = Date(timeIntervalSince1970: data.timestamp )
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: date)
            
            let deliveryByDate = Date(timeIntervalSince1970: data.deliverByDate )
            let dateFormatter2 = DateFormatter()
            dateFormatter2.dateStyle = .medium
            let stringDeliveryByDate = dateFormatter2.string(from: deliveryByDate)
            
            cell.purchaseOrderNumber.text = "\(data.purchaseOrderNumber)"
            cell.nameLabel.text = "\(data.name)"
            cell.deliverByLabel.text = "Deliver By: \(stringDeliveryByDate)"
            cell.deliveryContactLabel.text = "Contact: \(data.deliveryContactName) - \(data.deliveryContactPhone)"
            cell.deliveryAddressLabel.text = data.deliveryAddress
            cell.deliveryZoneLabel.text = "Delivery Zone: \(data.deliveryZone) \(data.deliveryNumber)"
            var subtotals : [Float] = [Float]()
            if data.status == "Delivered" {
                for i in 0..<data.realItems.count {
                    subtotals.append((Float(data.realItems[i].pricePerUnit) * data.realItemQuantities[i]).rounded())
                }
                let total = Int(subtotals.reduce(0,+)) - data.discount + data.deliveryFee
                //Format Total
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .decimal
                let formattedTotal = numberFormatter.string(from: NSNumber(value: total))
                cell.statusLabel.text = "Status: Delivered, Total: Rp.\(formattedTotal!)"
            }
            else {
                cell.statusLabel.text = "Status: \(data.status)"
            }
            cell.createdByLabel.text  = "Created By: \(data.createdBy) on \(stringDate)"
            switch data.status {
            case "Created":
                cell.statusImageView.image = UIImage(named: "PurchaseOrderCreated")
            case "Prepped":
                cell.statusImageView.image = UIImage(named: "Prepped")
            case "Quality Checked":
                cell.statusImageView.image = UIImage(named: "QualityChecked")
            case "Delivery In Progress":
                cell.statusImageView.image = UIImage(named: "DeliveryInProgress")
            case "Delivered":
                cell.statusImageView.image = UIImage(named: "Delivered")
            case "Cancelled":
                cell.statusImageView.image = UIImage(named: "DeliveryCancelled")
            default:
                cell.statusImageView.image = UIImage(named: "currentCycleIcon")
            }
            
            if data.isPaid {
                cell.backgroundColor = .systemGreen
            }
            else {
                cell.backgroundColor = .systemBackground
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
    
    //MARK: Table Cell Button Actions
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let qualityCheck = UIContextualAction(style: .normal, title: "QC") {  (contextualAction, view, boolValue) in
            
            func qualityCheckAlert (data: RetailPurchaseOrder) {
                var message : String = ""
                message.append("--- ORDERED ---\n")
                for i in 0..<data.orderedItems.count {
                    message.append("\(data.orderedItems[i].name) \(String( data.orderedItemQuantities[i])) \(data.orderedItems[i].unit)\n")
                }
                message.append("\n--- REAL ---\n")
                for i in 0..<data.realItems.count {
                    message.append("\(data.realItems[i].name) \(String(format: "%.2f", data.realItemQuantities[i])) \(data.realItems[i].unit)\n")
                }
                //Declare Alert message
                let dialogMessage = UIAlertController(title: "Confirm Quality Check", message: message, preferredStyle: .alert)
                // Create OK button with action handler
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Yes button tapped")
                    self.updateQualityCheckStatusPurchaseOrder(purchaseOrderNumber: data.purchaseOrderNumber)
                })
                // Create Cancel button with action handlder
                let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
                    print("Cancel button tapped")
                }
                //Add OK and Cancel button to dialog message
                dialogMessage.addAction(ok)
                dialogMessage.addAction(cancel)
                // Present dialog message to user
                self.present(dialogMessage, animated: true, completion: nil)
                
            }
            
            if (self.resultSearchController.isActive) {
                qualityCheckAlert(data: self.filteredDataArray[self.filteredDataArray.count - indexPath.row - 1])
            }
            else {
                qualityCheckAlert(data: self.dataArray[self.dataArray.count - indexPath.row - 1])
            }
            
        }
        
        qualityCheck.image = UIImage(systemName: "checkmark.circle.fill")
        qualityCheck.backgroundColor = .systemGreen
        
        let cancel = UIContextualAction(style: .normal, title: "Cancel") {  (contextualAction, view, boolValue) in
            
            func cancelAlert (data: RetailPurchaseOrder) {
                //Declare Alert message
                let dialogMessage = UIAlertController(title: "Confirm Cancel", message: "Are you sure you want to cancel this PO?", preferredStyle: .alert)
                // Create OK button with action handler
                let yes = UIAlertAction(title: "YES", style: .default, handler: { (action) -> Void in
                    print("Yes button tapped")
                    self.updateCancelledStatusPurchaseOrder(purchaseOrder: data)
                })
                // Create Cancel button with action handlder
                let no = UIAlertAction(title: "NO", style: .cancel) { (action) -> Void in
                    print("Cancel button tapped")
                }
                //Add OK and Cancel button to dialog message
                dialogMessage.addAction(yes)
                dialogMessage.addAction(no)
                // Present dialog message to user
                self.present(dialogMessage, animated: true, completion: nil)
                
            }
            
            if (self.resultSearchController.isActive) {
                cancelAlert(data: self.filteredDataArray[self.filteredDataArray.count - indexPath.row - 1])
            }
            else {
                cancelAlert(data: self.dataArray[self.dataArray.count - indexPath.row - 1])
            }
            
        }
        
        cancel.image = UIImage(systemName: "xmark.circle.fill")
        cancel.backgroundColor = .systemRed
        
        let inv = UIContextualAction(style: .normal, title: "Invoice") {  (contextualAction, view, boolValue) in
            
            if (self.resultSearchController.isActive) {
                self.selectedPurchaseOrder = self.filteredDataArray[self.filteredDataArray.count - indexPath.row - 1]
                self.resultSearchController.isActive = false
                self.performSegue(withIdentifier: "goToInvoice", sender: self)
            }
            else {
                self.selectedPurchaseOrder = self.dataArray[self.dataArray.count - indexPath.row - 1]
                self.performSegue(withIdentifier: "goToInvoice", sender: self)
            }
            
        }
        
        inv.image = UIImage(systemName: "doc.plaintext")
        inv.backgroundColor = .systemGray
        
        let edit = UIContextualAction(style: .normal, title: "Edit") {  (contextualAction, view, boolValue) in
            
            if (self.resultSearchController.isActive) {
                self.selectedPurchaseOrder = self.filteredDataArray[self.filteredDataArray.count - indexPath.row - 1]
                self.isNewPurchaseOrder = false
                self.resultSearchController.isActive = false
                self.performSegue(withIdentifier: "goToNewPurchaseOrder", sender: self)
            }
            else {
                self.selectedPurchaseOrder = self.dataArray[self.dataArray.count - indexPath.row - 1]
                self.isNewPurchaseOrder = false
                self.performSegue(withIdentifier: "goToNewPurchaseOrder", sender: self)
            }
            
        }
        
        edit.image = UIImage(systemName: "square.and.pencil")
        edit.backgroundColor = .systemBlue
        
        let archive = UIContextualAction(style: .normal, title: "Archive") {  (contextualAction, view, boolValue) in
            
            let alert = UIAlertController(title: "Confirm Purchase Order Archive", message: "Are you sure you want to archive this Purchase Order?", preferredStyle: .actionSheet)
            
            let ok = UIAlertAction(title: "YES", style: .default, handler: { (action) -> Void in
                print("YES button tapped")
                if (self.resultSearchController.isActive) {
                    self.moveDocumentToArchive(purchaseOrder: self.filteredDataArray[self.filteredDataArray.count - indexPath.row - 1])
                    var dataArrayIndex : Int = 0
                    for i in 0..<self.dataArray.count {
                        if self.dataArray[i].purchaseOrderNumber == self.filteredDataArray[self.filteredDataArray.count - indexPath.row - 1].purchaseOrderNumber {
                            dataArrayIndex = i
                        }
                    }
                    self.dataArray.remove(at: dataArrayIndex)
                    self.filteredDataArray.remove(at: self.filteredDataArray.count - indexPath.row - 1)
                }
                else {
                    self.moveDocumentToArchive(purchaseOrder: self.dataArray[self.dataArray.count - indexPath.row - 1])
                    self.dataArray.remove(at: self.dataArray.count - indexPath.row - 1)
                }
                self.tableView.reloadData()
                self.reloadEmptyState()
            })
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
                print("Cancel button tapped")
            }
            
            alert.addAction(ok)
            alert.addAction(cancel)
            
            self.present(alert, animated: true, completion: nil)
        }
        
        archive.image = UIImage(systemName: "archivebox")
        archive.backgroundColor = .systemYellow
        
        let deliveryImage = UIContextualAction(style: .normal, title: "Delivery") {  (contextualAction, view, boolValue) in
            
            if (self.resultSearchController.isActive) {
                self.isCSVExport = false
                let fileName = self.filteredDataArray[self.filteredDataArray.count - indexPath.row - 1].purchaseOrderNumber  + ".jpeg"
                self.downloadFile(fileName: fileName)
            }
            else {
                self.isCSVExport = false
                let fileName = self.dataArray[self.dataArray.count - indexPath.row - 1].purchaseOrderNumber + ".jpeg"
                self.downloadFile(fileName: fileName)
            }
        }
        deliveryImage.image = UIImage(systemName: "camera")
        deliveryImage.backgroundColor = .gray
        
        func determineSwipeActionConfigurations(data : RetailPurchaseOrder) -> UISwipeActionsConfiguration {
            switch data.status {
            case "Created":
                return UISwipeActionsConfiguration(actions: [edit,cancel])
            case "Prepped":
                return UISwipeActionsConfiguration(actions: [inv,qualityCheck,cancel])
            case "Quality Checked":
                if loginClass == "superadmin" {
                    return UISwipeActionsConfiguration(actions: [inv,cancel])
                }
                else {
                    return UISwipeActionsConfiguration(actions: [inv])
                }
            case "Delivery In Progress":
                if loginClass == "superadmin" {
                    return UISwipeActionsConfiguration(actions: [inv,cancel])
                }
                else {
                    return UISwipeActionsConfiguration(actions: [inv])
                }
            case "Delivered":
                if loginClass == "superadmin" && isArchive {
                    return UISwipeActionsConfiguration(actions: [inv,deliveryImage])
                }
                else if loginClass == "superadmin" && isArchive == false {
                    return UISwipeActionsConfiguration(actions: [archive,inv,deliveryImage,cancel])
                }
                else if loginClass == "administrator" {
                    return UISwipeActionsConfiguration(actions: [inv,deliveryImage])
                }
                else {
                    return UISwipeActionsConfiguration(actions: [inv])
                }
            case "Cancelled":
                if loginClass == "superadmin" && isArchive {
                    return UISwipeActionsConfiguration(actions: [])
                }
                else if loginClass == "superadmin" && isArchive == false {
                    return UISwipeActionsConfiguration(actions: [archive])
                }
                else {
                    return UISwipeActionsConfiguration(actions: [])
                }
            default:
                return UISwipeActionsConfiguration(actions: [])
            }
        }
        
        if (self.resultSearchController.isActive) {
            return determineSwipeActionConfigurations(data: self.filteredDataArray[self.filteredDataArray.count - indexPath.row - 1])
        }
        else {
            return determineSwipeActionConfigurations(data: self.dataArray[self.dataArray.count - indexPath.row - 1])
        }
    }
    
    func downloadFile(fileName : String) {
        if (self.resultSearchController.isActive) {
            self.resultSearchController.isActive = false
        }
        self.hud.detailTextLabel.text = "0% Complete"
        self.hud.textLabel.text = "Loading"
        self.hud.show(in: self.view)
        let storageRef = Storage.storage().reference()
        // Create a reference to the file we want to download
        let deliveryPermitRef = storageRef.child("RetailDeliveryImages/" + fileName)
        
        filePath = "\(documentsPath)/" + fileName
        
        // Start the download (in this case writing to a file)
        let downloadTask = deliveryPermitRef.write(toFile: URL(fileURLWithPath: filePath))

        // Observe changes in status
        downloadTask.observe(.resume) { snapshot in
          // Download resumed, also fires when the download starts
        }

        downloadTask.observe(.pause) { snapshot in
          // Download paused
        }

        downloadTask.observe(.progress) { snapshot in
          // Download reported progress
          let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
            / Double(snapshot.progress!.totalUnitCount)
            print(percentComplete)
            if Float(percentComplete) == 100.0 {
                self.hud.textLabel.text = "Success"
                self.hud.detailTextLabel.text = "\(String(format: "%.1f",Float(percentComplete)))% Complete"
                self.hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                self.hud.dismiss(afterDelay: 1.0)
            }
            else {
                self.hud.detailTextLabel.text = "\(String(format: "%.1f",Float(percentComplete)))% Complete"
            }
        }

        downloadTask.observe(.success) { snapshot in
          // Download completed successfully
            self.hud.dismiss()
            let previewController = QLPreviewController()
            previewController.dataSource = self
            self.present(previewController, animated: true)
        }

        // Errors only occur in the "Failure" case
        downloadTask.observe(.failure) { snapshot in
            guard let errorCode = (snapshot.error as NSError?)?.code else {
            return
          }
          guard let error = StorageErrorCode(rawValue: errorCode) else {
            return
          }
          switch (error) {
          case .objectNotFound:
            // File doesn't exist
            self.hud.dismiss()
            print("File doesn't exist")
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "File doesn't exist", message: "File Could not be found in Server", preferredStyle: .alert)
            
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)
            break
          case .unauthorized:
            self.hud.dismiss()
            // User doesn't have permission to access file
            print("User doesn't have permission to access file")
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Permission Error", message: "User doesn't have permission to access file", preferredStyle: .alert)
            
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)
            break
          case .cancelled:
            self.hud.dismiss()
            // User cancelled the download
            print("User cancelled the download")
            break

          /* ... */

          case .unknown:
            self.hud.dismiss()
            // Unknown error occurred, inspect the server response
            print("Unknown error occurred, inspect the server responsed")
            break
          default:
            self.hud.dismiss()
            // Another error occurred. This is a good place to retry the download.
            break
          }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (resultSearchController.isActive) {
            print(filteredDataArray[self.filteredDataArray.count - indexPath.row - 1].name)
            if previousMenu == "Retail" && filterBy == "Created"{
                self.selectedPurchaseOrder = filteredDataArray[self.filteredDataArray.count - indexPath.row - 1]
                resultSearchController.isActive = false
                self.performSegue(withIdentifier: "goToPreparationTicket", sender: self)
            }
            else if previousMenu == "Retail" && filterBy == "Quality Checked & Delivery In Progress" {
                self.selectedPurchaseOrder = filteredDataArray[self.filteredDataArray.count - indexPath.row - 1]
                resultSearchController.isActive = false
                self.performSegue(withIdentifier: "goToDelivery", sender: self)
            }

        }
        else {
            print(dataArray[self.dataArray.count - indexPath.row - 1].name)
            if previousMenu == "Retail" && filterBy == "Created"{
                self.selectedPurchaseOrder = dataArray[self.dataArray.count - indexPath.row - 1]
                self.performSegue(withIdentifier: "goToPreparationTicket", sender: self)
            }
            else if previousMenu == "Retail" && filterBy == "Quality Checked & Delivery In Progress" {
                self.selectedPurchaseOrder = dataArray[self.dataArray.count - indexPath.row - 1]
                self.performSegue(withIdentifier: "goToDelivery", sender: self)
            }
        }
    }
    
    //QLPreviewController Methods
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        if isCSVExport {
            return csvPath as QLPreviewItem
        }
        else {
            return URL(fileURLWithPath: filePath) as QLPreviewItem
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is RetailNewPurchaseOrderViewController
        {
            let vc = segue.destination as? RetailNewPurchaseOrderViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.isNewPurchaseOrder = isNewPurchaseOrder
            vc?.purchaseOrder = selectedPurchaseOrder
        }
        else if segue.destination is RetailPreparationTicketViewController
        {
            let vc = segue.destination as? RetailPreparationTicketViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.purchaseOrder = selectedPurchaseOrder
        }
        else if segue.destination is RetailDeliveryViewController
        {
            let vc = segue.destination as? RetailDeliveryViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.purchaseOrder = selectedPurchaseOrder
        }
        else if segue.destination is RetailInvoiceViewController
        {
            let vc = segue.destination as? RetailInvoiceViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.purchaseOrder = selectedPurchaseOrder
        }
        else if segue.destination is GoogleMapsViewController
        {
            let vc = segue.destination as? GoogleMapsViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.previousMenu = "Deliveries"
            vc?.dataArray = dataArray
        }
    }
}
