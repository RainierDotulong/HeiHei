//
//  RPATableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 6/23/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import UIEmptyState
import SVProgressHUD
import Firebase
import FirebaseFirestore
import NotificationBannerSwift

protocol sendRpaData {
    func rpaDataReceived(rpa: RPA)
}

class RPATableViewCell : UITableViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var nomorNkvLabel: UILabel!
    @IBOutlet var createdByLabel: UILabel!
}

class RPATableViewController: UITableViewController, UIEmptyStateDataSource, UIEmptyStateDelegate, UISearchResultsUpdating {
    
    var fullName : String = ""
    var loginClass : String = ""
    var pick : Bool = false
    
    var dataArray : [RPA] = [RPA]()
    var filteredDataArray : [RPA] = [RPA]()
    var rpaNames : [String] = [String]()
    var edit = false
    var selectedRpa : RPA?
    
    var delegate : sendRpaData?
    
    var resultSearchController = UISearchController()
    
    @IBOutlet var barButtonItem: UIBarButtonItem!
    
    //UI Empty State Variables
    var emptyStateTitle: NSAttributedString {
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor(red: 0.882, green: 0.890, blue: 0.859, alpha: 1.00),
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22)]
        return NSAttributedString(string: "No RPA Data Found", attributes: attrs)
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
        
        barButtonItem.isEnabled = false
        
        let RPACreationNotification = Notification.Name("rpaCreated")
        NotificationCenter.default.addObserver(self, selector: #selector(rpaCreated(_:)), name: RPACreationNotification, object: nil)
        
        getDataFromServer(pullDownRefresh : false)
    }
    
    @objc func rpaCreated(_ notification:Notification) {
        print("RPA Successfully Created.")
        getDataFromServer(pullDownRefresh : false)
    }
    
    @objc func refresh() {
        print("Refresh")
        getDataFromServer(pullDownRefresh : true)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredDataArray.removeAll(keepingCapacity: false)

        let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchController.searchBar.text!)
        let array = (rpaNames as NSArray).filtered(using: searchPredicate)
        let filteredRPAArray = array as! [String]
        //construct Filtered Data Array
        for data in dataArray {
            for rpa in filteredRPAArray {
                if data.name == rpa {
                    filteredDataArray.append(data)
                }
            }
        }
        self.tableView.reloadData()
        self.reloadEmptyState()
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        print("Add")
        edit = false
        self.performSegue(withIdentifier: "goToRPAInput", sender: self)
    }
    
    func getDataFromServer(pullDownRefresh : Bool) {
        if pullDownRefresh == false {
            SVProgressHUD.show()
        }
        let db = Firestore.firestore()
        db.collection("rpa").getDocuments() { (querySnapshot, err) in
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
                self.rpaNames.removeAll(keepingCapacity: false)
                for document in querySnapshot!.documents {
                    
                    var rpa : RPA = RPA(name: "", address: "", latitude: 0, longitude: 0, noNkv: "", perhitunganBiaya: "", referencePrice: 0, paymentTerm: "", sideProduct: false, contactPerson: "", contactPhone: "", bank: "", bankName: "", bankNumber: "", createdBy: "", timestamp: 0)
                    
                    rpa.name = document.documentID
                    rpa.address = document.data()["address"] as! String
                    rpa.latitude = document.data()["latitude"] as! Double
                    rpa.longitude = document.data()["longitude"] as! Double
                    rpa.noNkv = document.data()["noNkv"] as! String
                    rpa.perhitunganBiaya = document.data()["perhitunganBiaya"] as! String
                    rpa.referencePrice = document.data()["referencePrice"] as! Int
                    rpa.paymentTerm = document.data()["paymentTerm"] as! String
                    rpa.sideProduct = document.data()["sideProduct"] as! Bool
                    rpa.contactPerson = document.data()["contactPerson"] as! String
                    rpa.contactPhone = document.data()["contactPhone"] as! String
                    rpa.bank = document.data()["bank"] as! String
                    rpa.bankName = document.data()["bankName"] as! String
                    rpa.bankNumber = document.data()["bankNumber"] as! String
                    rpa.createdBy = document.data()["createdBy"] as! String
                    rpa.timestamp = document.data()["timestamp"] as! Double
                    
                    self.dataArray.append(rpa)
                    self.rpaNames.append(rpa.name)
                }
                if pullDownRefresh == true {
                    self.refreshControl?.endRefreshing()
                }
                else {
                    SVProgressHUD.dismiss()
                }
                self.tableView.reloadData()
                self.reloadEmptyState()
                self.barButtonItem.isEnabled = true
            }
        }
    }
    
    func deleteRPA(data : RPA) {
        if resultSearchController.isActive {
            resultSearchController.isActive = false
        }
        SVProgressHUD.show()
        let doc = Firestore.firestore().collection("rpa").document(data.name)
        doc.delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
                SVProgressHUD.dismiss()
                let banner = StatusBarNotificationBanner(title: "Error removing document", style: .danger)
                banner.show()
            } else {
                print("Document successfully removed!")
                SVProgressHUD.dismiss()
                let banner = StatusBarNotificationBanner(title: "Document successfully removed!", style: .success)
                banner.show()
                self.getDataFromServer(pullDownRefresh: false)
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
        
        func createCells(data : RPA) -> RPATableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "rpaCell", for: indexPath) as! RPATableViewCell
            
            let date = Date(timeIntervalSince1970: data.timestamp )
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: date)
            
            cell.nameLabel.text = data.name
            cell.addressLabel.text = data.address
            cell.nomorNkvLabel.text = "No NKV: \(data.noNkv)"
            cell.createdByLabel.text = "Created By: \(data.createdBy) on \(stringDate)"
            
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
        tableView.deselectRow(at: indexPath, animated: true)
        if  (resultSearchController.isActive) {
            if pick {
                self.delegate?.rpaDataReceived(rpa: filteredDataArray[self.filteredDataArray.count - indexPath.row - 1])
                resultSearchController.isActive = false
                self.navigationController?.popViewController(animated: true)
            }
        }
        else {
            if pick {
                self.delegate?.rpaDataReceived(rpa: dataArray[self.dataArray.count - indexPath.row - 1])
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    //MARK: Table Cell Button Actions
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let delete = UIContextualAction(style: .normal, title: "Delete") {  (contextualAction, view, boolValue) in
            
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Confirm", message: "Are you sure you want to Delete this RPA?", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
                if (self.resultSearchController.isActive) {
                    self.deleteRPA(data: self.filteredDataArray[self.filteredDataArray.count - indexPath.row - 1])
                }
                else {
                    //Remove Data Array Item
                    self.deleteRPA(data: self.dataArray[self.dataArray.count - indexPath.row - 1])
                }
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
        
        delete.image = UIImage(systemName: "trash")
        delete.backgroundColor = .systemRed
        
        let edit = UIContextualAction(style: .normal, title: "Edit") {  (contextualAction, view, boolValue) in
            
            if (self.resultSearchController.isActive) {
                self.selectedRpa = self.filteredDataArray[indexPath.row]
                self.edit = true
                self.performSegue(withIdentifier: "goToRPAInput", sender: self)
            }
            else {
                self.selectedRpa = self.dataArray[indexPath.row]
                self.edit = true
                self.performSegue(withIdentifier: "goToRPAInput", sender: self)
            }
            
        }
        
        edit.image = UIImage(systemName: "square.and.pencil")
        edit.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [delete, edit])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is RPAInputViewController
        {
            let vc = segue.destination as? RPAInputViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.rpaNames = rpaNames
            vc?.selectedRpa = selectedRpa ?? RPA(name: "", address: "", latitude: 0, longitude: 0, noNkv: "", perhitunganBiaya: "",referencePrice: 0, paymentTerm: "", sideProduct: false, contactPerson: "", contactPhone: "", bank: "", bankName: "", bankNumber: "", createdBy: "", timestamp: 0)
            vc?.edit = edit
        }
    }
}
