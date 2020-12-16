//
//  PemborongViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 11/19/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import TextFieldEffects
import Firebase
import FirebaseFirestore
import NotificationBannerSwift

class PemborongInputTableViewCell : UITableViewCell {
    @IBOutlet var firstNameLabel: UILabel!
    @IBOutlet var lastNameLabel: UILabel!
    @IBOutlet var roleImageView: UIImageView!
    
}

class PemborongViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var fullName : String = ""
    var loginClass : String = ""

    @IBOutlet var tableView: UITableView!
    @IBOutlet var navItem: UINavigationItem!
    @IBOutlet var kepalaTimLabel: UILabel!
    
    var dataArray : [[String]] = [[String]]()
    
    var headAssigned : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        if dataArray.isEmpty == false {
            tableView.reloadData()
            for data in dataArray {
                if data[2] == "head" {
                    //Assign Head
                    headAssigned = true
                    kepalaTimLabel.text = data[0] + " " + data[1]
                    navItem.title = "Tim " + data[0]
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    @IBAction func finishButtonPressed(_ sender: Any) {
        if self.dataArray.isEmpty == false && kepalaTimLabel.text != "Kepala Tim" {
            print("Finish")
            var firstNameArray : [String] = [String]()
            var lastNameArray : [String] = [String]()
            var roleArray : [String] = [String]()
            for data in dataArray {
                firstNameArray.append(data[0])
                lastNameArray.append(data[1])
                roleArray.append(data[2])
            }
            uploadDataToServer(firstNameArray: firstNameArray, lastNameArray: lastNameArray, roleArray: roleArray,document: kepalaTimLabel.text!, creationTimestamp: String(NSDate().timeIntervalSince1970), createdBy: fullName)
        }
        else {
            let alert = UIAlertController(title: "Incomplete Data", message: "Please add members and assign head of Team (swipe left on table cell)", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Add Team Member", message: "Specify First and Last Name", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "First"
            textField.keyboardType = .default
            textField.autocapitalizationType = .words
        }
        alert.addTextField { (textField2) in
            textField2.placeholder = "Last"
            textField2.keyboardType = .default
            textField2.autocapitalizationType = .words
        }
        
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            let textField = alert.textFields![0]
            let textField2 = alert.textFields![1]
            print(textField.text ?? "")
            print(textField2.text ?? "")
            self.dataArray.append([textField.text ?? "",textField2.text ?? "","worker"])
            self.tableView.reloadData()
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            print("Cancel button tapped")
        }
        
        alert.addAction(ok)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func uploadDataToServer(firstNameArray : [String],lastNameArray : [String],roleArray : [String],document : String, creationTimestamp : String, createdBy : String) {
        let doc = Firestore.firestore().collection("pemborongPanen").document(document)
        doc.setData([
            "firstNameArray" : firstNameArray,
            "lastNameArray" : lastNameArray,
            "roleArray" : roleArray,
            "creationTimestamp" : creationTimestamp,
            "createdBy" : createdBy
            
        ]) { err in
            if let err = err {
                print("Error writing Pemborong Document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error writing Pemborong Document", style: .danger)
                banner.show()
            } else {
                print("Pemborong Document successfully written!")
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    // Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return dataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.rowHeight = UITableView.automaticDimension
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "pemborongInputCell", for: indexPath) as! PemborongInputTableViewCell
        cell.firstNameLabel.text = dataArray[dataArray.count - indexPath.row - 1][0]
        cell.lastNameLabel.text = dataArray[dataArray.count - indexPath.row - 1][1]
        if dataArray[dataArray.count - indexPath.row - 1][2] == "head" {
            cell.roleImageView.image = UIImage(named: "head")
        }
        else {
            cell.roleImageView.image = UIImage(named: "worker")
        }

        return cell
    }
    
    //Add Table Cell Button Actions
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        let delete = UIContextualAction(style: .normal, title: "Delete") {  (contextualAction, view, boolValue) in
            print("Delete " + self.dataArray[self.dataArray.count - indexPath.row - 1][0])
            if self.dataArray[self.dataArray.count - indexPath.row - 1][2] == "head" {
                self.headAssigned = false
                self.kepalaTimLabel.text = "Kepala Tim"
                self.navItem.title = "Tim Pemborong"
            }
            self.dataArray.remove(at: self.dataArray.count - indexPath.row - 1)
            self.tableView.reloadData()
        }
        delete.backgroundColor = .systemRed
        
        let head = UIContextualAction(style: .normal, title: "Head") {  (contextualAction, view, boolValue) in
            print("Head " + self.dataArray[self.dataArray.count - indexPath.row - 1][0])
            self.dataArray[self.dataArray.count - indexPath.row - 1][2] = "head"
            
            //Assign Head
            self.headAssigned = true
            self.kepalaTimLabel.text = self.dataArray[self.dataArray.count - indexPath.row - 1][0] + " " + self.dataArray[self.dataArray.count - indexPath.row - 1][1]
            self.navItem.title = "Tim " + self.dataArray[self.dataArray.count - indexPath.row - 1][0]
            self.tableView.reloadData()
        }
        head.backgroundColor = .systemGray
        
        if headAssigned == false {
            let swipeActions = UISwipeActionsConfiguration(actions: [head,delete])
            return swipeActions

        }
        else {
            let swipeActions = UISwipeActionsConfiguration(actions: [delete])
            return swipeActions

        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(self.dataArray[dataArray.count - indexPath.row - 1][0])
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
