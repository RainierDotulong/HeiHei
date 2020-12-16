//
//  DataRekeningTableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 9/30/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import UIEmptyState
import Firebase
import FirebaseFirestore
import SVProgressHUD
import FirebaseStorage
import Reachability
import NotificationBannerSwift

class DataRekeningTableViewCell : UITableViewCell {
    @IBOutlet var companyLabel: UILabel!
    @IBOutlet var bankLabel: UILabel!
    @IBOutlet var bankNumberLabel: UILabel!
}

protocol sendRekeningData {
    func rekeningDataReceived(rekening : [String])
}

class DataRekeningTableViewController : UITableViewController, UIEmptyStateDataSource, UIEmptyStateDelegate {
    
    var fullName : String = ""
    
    var dataArray : [[String]] = [[String]]()
    var refreshedDataArray : [[String]] = [[String]]()
    
    var companyName : String = ""
    var bank : String = ""
    var bankNumber : String = ""
    
    var editFlag : Bool = false
    
    var isPick : Bool = false
    
    var delegate : sendRekeningData?
    
    //UI Empty State Variables
    var emptyStateTitle: NSAttributedString {
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor(red: 0.882, green: 0.890, blue: 0.859, alpha: 1.00),
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22)]
        return NSAttributedString(string: "No Bank Accounts Found!", attributes: attrs)
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
                
        // Add reachability observer
        if let reachability = AppDelegate.sharedAppDelegate()?.reachability
        {
            NotificationCenter.default.addObserver( self, selector: #selector( self.reachabilityChanged ),name: Notification.Name.reachabilityChanged, object: reachability )
        }
        
        //Pull to Refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:  #selector(refresh), for: .valueChanged)
        self.refreshControl = refreshControl
    }
    
    override func viewWillAppear(_ animated: Bool) {
        dataArray = [[String]]()
        getCompanyListFromServer()
    }
    
    @objc func refresh() {
        refreshedDataArray = [[String]]()
        getRefreshedCompanyListFromServer()
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        editFlag = false
        self.performSegue(withIdentifier: "goToRekening", sender: self)
    }
    
    func getCompanyListFromServer() {
        SVProgressHUD.show()
        let db = Firestore.firestore()
        db.collection("bankNumberList").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                SVProgressHUD.dismiss()
                let banner = StatusBarNotificationBanner(title: "Error getting documents", style: .danger)
                banner.show()
            } else {
                for document in querySnapshot!.documents {
                    self.dataArray.append([document.documentID,document.data()["bank"] as! String,document.data()["bankNumber"] as! String] )
                }
                self.tableView.reloadData()
                SVProgressHUD.dismiss()
                self.reloadEmptyState()
            }
        }
    }
    
    func getRefreshedCompanyListFromServer() {
        let db = Firestore.firestore()
        db.collection("bankNumberList").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                self.refreshControl?.endRefreshing()
                let banner = StatusBarNotificationBanner(title: "Error getting documents", style: .danger)
                banner.show()
            } else {
                for document in querySnapshot!.documents {
                    //print("\(document.documentID) => \(document.data())")
                    self.refreshedDataArray.append([document.documentID,document.data()["bank"] as! String,document.data()["bankNumber"] as! String] )
                }
                self.dataArray = self.refreshedDataArray
                self.tableView.reloadData()
                self.reloadEmptyState()
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    // Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return dataArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.rowHeight = UITableView.automaticDimension
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "dataRekeningCell", for: indexPath) as! DataRekeningTableViewCell
        
        cell.companyLabel.text = dataArray[indexPath.row][0]
        cell.bankLabel.text = "Bank: " + dataArray[indexPath.row][1]
        cell.bankNumberLabel.text = dataArray[indexPath.row][2]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if isPick {
            self.delegate?.rekeningDataReceived(rekening: self.dataArray[indexPath.row])
            self.navigationController?.popViewController(animated: true)
        }
        else {
            companyName = self.dataArray[indexPath.row][0]
            bank = self.dataArray[indexPath.row][1]
            bankNumber = self.dataArray[indexPath.row][2]
            
            editFlag = true
            
            self.performSegue(withIdentifier: "goToRekening", sender: self)
        }
    }
    
    //Add Table Cell Button Actions
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .normal, title: "Delete") {  (contextualAction, view, boolValue) in
            print("DELETE" + self.dataArray[indexPath.row][0])
            SVProgressHUD.show()
            //Delete Document from server
            let db = Firestore.firestore()
            db.collection("bankNumberList").document(self.dataArray[indexPath.row][0]).delete()
            //Refresh Data Array and Table View
            self.dataArray = [[String]]()
            self.getCompanyListFromServer()
        }
        delete.backgroundColor = .systemRed
        
        let swipeActions = UISwipeActionsConfiguration(actions: [delete])
        
        return swipeActions
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
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
        if segue.destination is RekeningViewController
        {
            let vc = segue.destination as? RekeningViewController
            if editFlag == true {
                vc?.company = companyName
                vc?.bank = bank
                vc?.bankNumber = bankNumber
            }
        }
    }
}
