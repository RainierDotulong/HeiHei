//
//  UsersTableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 10/15/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import UIEmptyState
import Firebase
import FirebaseFirestore
import SVProgressHUD
import Reachability
import NotificationBannerSwift

class UsersTableViewCell : UITableViewCell {
    @IBOutlet var emailLabel : UILabel!
    @IBOutlet var classLabel : UILabel!
    @IBOutlet var farmNameLabel : UILabel!
    @IBOutlet var fullNameLabel : UILabel!
}

class UsersTableViewController : UITableViewController, UIEmptyStateDataSource, UIEmptyStateDelegate, UISearchResultsUpdating {
    var fullName : String = ""
    var loginClass : String = ""
    
    var dataArray : [User] = [User]()
    var filteredDataArray : [User] = [User]()
    
    var emails : [String] = [String]()
    
    var resultSearchController = UISearchController()
    
    //UI Empty State Variables
    var emptyStateTitle: NSAttributedString {
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor(red: 0.882, green: 0.890, blue: 0.859, alpha: 1.00),
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22)]
        return NSAttributedString(string: "No Users Found!", attributes: attrs)
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
        
        //SearchBar
        resultSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.obscuresBackgroundDuringPresentation = false
            controller.searchBar.sizeToFit()

            tableView.tableHeaderView = controller.searchBar

            return controller
        })()
        
        getUsersListFromServer(pullDownRefresh: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredDataArray.removeAll(keepingCapacity: false)

        let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchController.searchBar.text!)
        let array = (emails as NSArray).filtered(using: searchPredicate)
        let filteredEmailss = array as! [String]
        //construct Filtered Data Array
        for data in dataArray {
            for email in filteredEmailss {
                if data.email == email {
                    filteredDataArray.append(data)
                }
            }
        }
        self.tableView.reloadData()
        self.reloadEmptyState()
    }
    
    @objc func refresh() {
        getUsersListFromServer(pullDownRefresh: true)
    }
    
    func getUsersListFromServer(pullDownRefresh : Bool) {
        if pullDownRefresh == false {
            SVProgressHUD.show()
        }
        let db = Firestore.firestore()
        db.collection("userProfiles").getDocuments() { (querySnapshot, err) in
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
                self.emails.removeAll(keepingCapacity: false)
                for document in querySnapshot!.documents {
                    let user : User = User(fullName: document.data()["fullName"] as! String, loginClass: document.data()["class"] as! String, farmName: document.data()["farmName"] as! String, email: document.documentID)
                    self.dataArray.append(user)
                    self.emails.append(document.documentID)
                }
                self.tableView.reloadData()
                if pullDownRefresh == true {
                    self.refreshControl?.endRefreshing()
                }
                else {
                    SVProgressHUD.dismiss()
                }
                self.reloadEmptyState()
            }
        }
    }
    
    func updateUserFarmName(email : String ,farmName : String) {
        let usersFarmRef = Firestore.firestore().collection("userProfiles").document(email)
        usersFarmRef.setData(["farmName": farmName], merge: true) { err in
            if let err = err {
                print("Error Updating Farm Name Document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error Updating Farm Name", style: .danger)
                banner.show()
            } else {
                print("Farm Name successfully Updated!")
                let banner = StatusBarNotificationBanner(title: "Farm Name successfully Updated!", style: .success)
                banner.show()
                self.getUsersListFromServer(pullDownRefresh: false)
            }
        }
    }
    
    func updateUserClass(email : String, loginClass : String) {
        let usersClassRef = Firestore.firestore().collection("userProfiles").document(email)
        usersClassRef.setData(["class": loginClass], merge: true) { err in
            if let err = err {
                print("Error Updating User Class Document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error Updating User Class", style: .danger)
                banner.show()
            } else {
                print("User Class successfully updated!")
                let banner = StatusBarNotificationBanner(title: "User Class successfully updated!", style: .success)
                banner.show()
                self.getUsersListFromServer(pullDownRefresh: false)
            }
        }
    }
    
    // Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if  (resultSearchController.isActive) {
            return filteredDataArray.count
        }
        else {
            return dataArray.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.rowHeight = UITableView.automaticDimension
        
        func createCells(data : User) -> UsersTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "usersCell", for: indexPath) as! UsersTableViewCell
            
            cell.emailLabel.text = data.email
            cell.classLabel.text = "Login Class: " + data.loginClass.uppercased()
            cell.farmNameLabel.text = "Farm: " + data.farmName.uppercased()
            cell.fullNameLabel.text = "Name: " + data.fullName
            
            //Incorrect Farm Name Red Color
            if data.farmName == "pinantik" || data.farmName == "kejayan" || data.farmName == "lewih" {
                cell.farmNameLabel.textColor = .black
            }
            else {
                cell.farmNameLabel.textColor = .systemRed
            }
            
            //Incorrect Class Red Color
            if data.loginClass == "farmManager" || data.loginClass == "farmWorker" || data.loginClass == "harvester" || data.loginClass == "retailer" || data.loginClass == "administrator" || data.loginClass == "superadmin" || data.loginClass == "retailAdministrator" {
                cell.classLabel.textColor = .black
            }
            else {
                cell.classLabel.textColor = .systemRed
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
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let loginClass = UIContextualAction(style: .normal, title: "Class") {  (contextualAction, view, boolValue) in
            func displayLoginClassUpdate(user : User) {
                if self.resultSearchController.isActive  {
                    self.resultSearchController.isActive = false
                }
                
                let dialogMessage = UIAlertController(title: "Login Class", message: "Please Choose Login Class for \(user.email)", preferredStyle: .alert)
                
                let farmWorker = UIAlertAction(title: "Farm Worker", style: .default, handler: { (action) -> Void in
                    print("Farm Worker")
                    self.updateUserClass(email: user.email, loginClass: "farmWorker")
                })
                
                let farmManager = UIAlertAction(title: "Farm Manager", style: .default, handler: { (action) -> Void in
                    print("Farm Manager")
                    self.updateUserClass(email: user.email, loginClass: "farmManager")
                })
                
                let harvester = UIAlertAction(title: "Harvest Team", style: .default, handler: { (action) -> Void in
                    print("Harvest Team")
                    self.updateUserClass(email: user.email, loginClass: "harvester")
                })
                
                let retailer = UIAlertAction(title: "Retailer", style: .default, handler: { (action) -> Void in
                    print("Retailer")
                    self.updateUserClass(email: user.email, loginClass: "retailer")
                })
                let retailAdmin = UIAlertAction(title: "Retail Administrator", style: .default, handler: { (action) -> Void in
                    print("Retail Administrator")
                    self.updateUserClass(email: user.email, loginClass: "retailAdministrator")
                })
                
                let disabled = UIAlertAction(title: "Disabled", style: .default, handler: { (action) -> Void in
                    print("Disabled")
                    self.updateUserClass(email: user.email, loginClass: "disabled")
                })
                
                let cancel = UIAlertAction(title: "Cancel", style: .default, handler: { (action) -> Void in
                    print("Cancel")
                })
                
                dialogMessage.addAction(farmWorker)
                dialogMessage.addAction(farmManager)
                dialogMessage.addAction(harvester)
                dialogMessage.addAction(retailer)
                dialogMessage.addAction(retailAdmin)
                dialogMessage.addAction(disabled)
                dialogMessage.addAction(cancel)
                
                self.present(dialogMessage, animated: true, completion: nil)
            }
            
            if (self.resultSearchController.isActive) {
                displayLoginClassUpdate(user: self.filteredDataArray[self.filteredDataArray.count - indexPath.row - 1])
            }
            else {
                displayLoginClassUpdate(user: self.dataArray[self.dataArray.count - indexPath.row - 1])
            }
        }
        
        loginClass.backgroundColor = .systemBlue
        loginClass.image = UIImage(systemName: "rectangle.3.offgrid.fill")
        
        let farm = UIContextualAction(style: .normal, title: "Farm") {  (contextualAction, view, boolValue) in
            func displayUserFarmNameUpdate(user : User) {
                if self.resultSearchController.isActive  {
                    self.resultSearchController.isActive = false
                }
                
                let dialogMessage = UIAlertController(title: "Farm", message: "Please Choose Farm for \(user.email)", preferredStyle: .alert)
                
                let pinantik = UIAlertAction(title: "Pinantik", style: .default, handler: { (action) -> Void in
                    print("Pinantik")
                    self.updateUserFarmName(email: user.email, farmName: "pinantik")
                })
                
                let kejayan = UIAlertAction(title: "Kejayan", style: .default, handler: { (action) -> Void in
                    print("Kejayan")
                    self.updateUserFarmName(email: user.email, farmName: "kejayan")
                })
                
                let lewih = UIAlertAction(title: "Lewih", style: .default, handler: { (action) -> Void in
                    print("Lewih")
                    self.updateUserFarmName(email: user.email, farmName: "lewih")
                })
                
                let cancel = UIAlertAction(title: "Cancel", style: .default, handler: { (action) -> Void in
                    print("Cancel")
                })
                
                dialogMessage.addAction(pinantik)
                dialogMessage.addAction(kejayan)
                dialogMessage.addAction(lewih)
                dialogMessage.addAction(cancel)
                
                self.present(dialogMessage, animated: true, completion: nil)
            }
            
            if (self.resultSearchController.isActive) {
                displayUserFarmNameUpdate(user: self.filteredDataArray[self.filteredDataArray.count - indexPath.row - 1])
            }
            else {
                displayUserFarmNameUpdate(user: self.dataArray[self.dataArray.count - indexPath.row - 1])
            }
        }
        
        farm.backgroundColor = .systemYellow
        farm.image = UIImage(systemName: "house.fill")
        
        let swipeActions = UISwipeActionsConfiguration(actions: [loginClass,farm])

        return swipeActions
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
           return 110
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
}
