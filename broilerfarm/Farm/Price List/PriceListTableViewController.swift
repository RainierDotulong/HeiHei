//
//  PriceListTableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 10/30/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import UIEmptyState
import Firebase
import FirebaseFirestore
import SVProgressHUD
import Reachability
import NotificationBannerSwift

class PriceListTableViewCell : UITableViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var pricePerUnitLabel: UILabel!
    @IBOutlet var unitLabel: UILabel!
    @IBOutlet var categoryLabel: UILabel!
    @IBOutlet var categoryImageView: UIImageView!
}

class PriceListTableViewController : UITableViewController, UIEmptyStateDataSource, UIEmptyStateDelegate, UISearchResultsUpdating {
    
    var fullName : String = ""
    var loginClass : String = ""
    
    var filteredDataArray : [[String]] = [[String]]()
    var nameArray : [String] = [String]()
    var dataArray : [[String]] = [[String]]()
    var refreshedDataArray : [[String]] = [[String]]()
    
    var newFlag : Bool = false
    var selectedName : String = ""
    var selectedPricePerUnit : String = ""
    var selectedUnit : String = ""
    var selectedCategory : String = ""
    var selectedFullName : String = ""
    var selectedTimestamp : String = ""
    
    var resultSearchController = UISearchController()
    
    //UI Empty State Variables
    var emptyStateTitle: NSAttributedString {
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor(red: 0.882, green: 0.890, blue: 0.859, alpha: 1.00),
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22)]
        return NSAttributedString(string: "No Items Found!", attributes: attrs)
    }
    
    var emptyStateImage: UIImage? {
        return UIImage(named: "redLogo")
    }
    
    override func viewDidLoad() {
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

        // Reload the table
        tableView.reloadData()
        
        // Add reachability observer
        if let reachability = AppDelegate.sharedAppDelegate()?.reachability
        {
            NotificationCenter.default.addObserver( self, selector: #selector( self.reachabilityChanged ),name: Notification.Name.reachabilityChanged, object: reachability )
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        getUsersListFromServer()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    @IBAction func newButtonPressed(_ sender: Any) {
        newFlag = true
        self.performSegue(withIdentifier: "goToItemDetail", sender: self)
    }
    
    func getUsersListFromServer() {
        dataArray.removeAll(keepingCapacity: false)
        nameArray.removeAll(keepingCapacity: false)
        SVProgressHUD.show()
        let db = Firestore.firestore()
        db.collection("priceList").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                SVProgressHUD.dismiss()
                let banner = StatusBarNotificationBanner(title: "Error getting documents", style: .danger)
                banner.show()
            } else {
                for document in querySnapshot!.documents {
                    //print("\(document.documentID) => \(document.data())")
                    self.nameArray.append(document.documentID)
                    self.dataArray.append([document.documentID,document.data()["pricePerUnit"] as! String,document.data()["category"] as! String,document.data()["unit"] as! String,document.data()["fullName"] as! String,document.data()["timestamp"] as! String] )
                }
                print(self.dataArray)
                self.tableView.reloadData()
                SVProgressHUD.dismiss()
                self.reloadEmptyState()
            }
        }
    }
    
    // Table view data source
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
        
        func createCells(dataArray : [String]) -> PriceListTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "priceListCell", for: indexPath) as! PriceListTableViewCell
            //Format Price
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            let formattedPrice = numberFormatter.string(from: NSNumber(value:Int(dataArray[1])!))
            
            cell.nameLabel.text = dataArray[0]
            cell.pricePerUnitLabel.text = "Rp. " + formattedPrice!
            cell.unitLabel.text = "Unit: " + dataArray[3]
            cell.categoryLabel.text = "Category: " + dataArray[2]
            cell.categoryImageView.image = UIImage(named: CategoryToImage(category: dataArray[2]))
            
            return cell
        }
        
        if (resultSearchController.isActive) {
            return createCells(dataArray: filteredDataArray[self.filteredDataArray.count - indexPath.row - 1])
        }
        else {
            return createCells(dataArray: dataArray[self.dataArray.count - indexPath.row - 1])
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        newFlag = false
        if (resultSearchController.isActive) {
            selectedName = filteredDataArray[self.filteredDataArray.count - indexPath.row - 1][0]
            selectedPricePerUnit = filteredDataArray[self.filteredDataArray.count - indexPath.row - 1][1]
            selectedUnit = filteredDataArray[self.filteredDataArray.count - indexPath.row - 1][3]
            selectedCategory = filteredDataArray[self.filteredDataArray.count - indexPath.row - 1][2]
            selectedFullName = filteredDataArray[self.filteredDataArray.count - indexPath.row - 1][4]
            selectedTimestamp = filteredDataArray[self.filteredDataArray.count - indexPath.row - 1][5]
            resultSearchController.isActive = false
            self.performSegue(withIdentifier: "goToItemDetail", sender: self)
        }
        else {
            selectedName = dataArray[self.dataArray.count - indexPath.row - 1][0]
            selectedPricePerUnit = dataArray[self.dataArray.count - indexPath.row - 1][1]
            selectedUnit = dataArray[self.dataArray.count - indexPath.row - 1][3]
            selectedCategory = dataArray[self.dataArray.count - indexPath.row - 1][2]
            selectedFullName = dataArray[self.dataArray.count - indexPath.row - 1][4]
            selectedTimestamp = dataArray[self.dataArray.count - indexPath.row - 1][5]
            self.performSegue(withIdentifier: "goToItemDetail", sender: self)
        }
    }
    
    //Add Table Cell Button Actions
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let delete = UIContextualAction(style: .normal, title: "Delete") {  (contextualAction, view, boolValue) in
            if (self.resultSearchController.isActive) {
                print("Delete" + self.filteredDataArray[self.filteredDataArray.count - indexPath.row - 1][0])
                let db = Firestore.firestore()
                db.collection("priceList").document(self.filteredDataArray[self.filteredDataArray.count - indexPath.row - 1][0]).delete() { err in
                    if let err = err {
                        print("Error removing document: \(err)")
                        let banner = StatusBarNotificationBanner(title: "Error removing document", style: .danger)
                        banner.show()
                    } else {
                        print("Document successfully removed!")
                        self.getUsersListFromServer()
                        self.resultSearchController.isActive = false
                        let banner = StatusBarNotificationBanner(title: "Document successfully removed!", style: .success)
                        banner.show()
                    }
                }
                tableView.reloadData()
                self.reloadEmptyState()
            }
            else {
                print("Delete" + self.dataArray[self.dataArray.count - indexPath.row - 1][0])
                let db = Firestore.firestore()
                db.collection("priceList").document(self.dataArray[self.dataArray.count - indexPath.row - 1][0]).delete() { err in
                    if let err = err {
                        print("Error removing document: \(err)")
                        let banner = StatusBarNotificationBanner(title: "Error removing document", style: .danger)
                        banner.show()
                    } else {
                        print("Document successfully removed!")
                        self.getUsersListFromServer()
                        let banner = StatusBarNotificationBanner(title: "Document successfully removed!", style: .success)
                        banner.show()
                    }
                }
                tableView.reloadData()
                self.reloadEmptyState()
            }
        }
        delete.backgroundColor = .red
        
        let swipeActions = UISwipeActionsConfiguration(actions: [delete])
        
        return swipeActions
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
           return 110
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredDataArray.removeAll(keepingCapacity: false)

        let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchController.searchBar.text!)
        let array = (nameArray as NSArray).filtered(using: searchPredicate)
        let filteredNameArray = array as! [String]
        //construct Filtered Data Array
        for data in dataArray {
            for name in filteredNameArray {
                if data[0] == name {
                    filteredDataArray.append(data)
                }
            }
        }
        self.tableView.reloadData()
        self.reloadEmptyState()
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
        if segue.destination is PriceListViewController
        {
            let vc = segue.destination as? PriceListViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.selectedName = selectedName
            vc?.selectedPricePerUnit = selectedPricePerUnit
            vc?.selectedUnit = selectedUnit
            vc?.selectedCategory = selectedCategory
            vc?.selectedFullName = selectedFullName
            vc?.selectedTimestamp = selectedTimestamp
            vc?.newFlag = newFlag
        }
    }
}
