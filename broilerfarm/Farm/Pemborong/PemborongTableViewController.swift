//
//  PemborongTableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 11/19/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import SVProgressHUD
import NotificationBannerSwift

class PemborongTableViewCell : UITableViewCell {
    @IBOutlet var namaTimLabel: UILabel!
    @IBOutlet var creationDetailsLabel: UILabel!
}

protocol sendPemborongPanen {
    func pemborongPanenReceived(pemborongPanen : String)
}

class PemborongTableViewController: UITableViewController {
    
    var fullName : String = ""
    var loginClass : String = ""
    var delegate : sendPemborongPanen?
    
    var isSelect : Bool = false
    
    var firstNameArray : [String] = [String]()
    var lastNameArray : [String] = [String]()
    var roleArray : [String] = [String]()
    
    var pemborongDataArray : [[String]] = [[String]]()
    
    var dataArray : [[String]] = [[String]]()

    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getPemborongListFromServer()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    func getPemborongListFromServer() {
        print("getPemborongListFromServer")
        pemborongDataArray.removeAll(keepingCapacity: false)
        SVProgressHUD.show()
        let db = Firestore.firestore()
        db.collection("pemborongPanen").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error getting documents", style: .danger)
                banner.show()
                SVProgressHUD.dismiss()
            } else {
                for document in querySnapshot!.documents {
                    //print("\(document.documentID) => \(document.data())")
                    self.pemborongDataArray.append([document.documentID,document.data()["createdBy"] as! String,document.data()["creationTimestamp"] as! String] )
                }
                //print(self.dataArray)
                self.tableView.reloadData()
                SVProgressHUD.dismiss()
                self.reloadEmptyState()
            }
        }
    }
    
    func getPemborongData(documentName : String) {
        SVProgressHUD.show()
        //Get Cycle Number from Firebase
        let cycle = Firestore.firestore().collection("pemborongPanen").document(documentName)
        
        cycle.getDocument { (document, error) in
            if let document = document, document.exists {
                let dataDescription = document.data()
                self.firstNameArray = dataDescription!["firstNameArray"] as! [String]
                self.lastNameArray = dataDescription!["lastNameArray"] as! [String]
                self.roleArray = dataDescription!["roleArray"] as! [String]
                
                //Reconstruct array [[firstName, lastName, role], [firstName, lastName, role]]
                self.dataArray.removeAll(keepingCapacity: false)
                for i in 0...self.firstNameArray.count - 1 {
                    self.dataArray.append([self.firstNameArray[i],self.lastNameArray[i],self.roleArray[i]])
                }
                SVProgressHUD.dismiss()
                self.performSegue(withIdentifier: "goToPemborong", sender: self)
                
            } else {
                print("Selected Pemborong Document does not exist")
                SVProgressHUD.dismiss()
                //Declare Alert message
                let dialogMessage = UIAlertController(title: "Selected Pemborong Document does not exist", message: "Please Contact Administrator", preferredStyle: .alert)
                // Create OK button with action handler
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                //Add OK and Cancel button to dialog message
                dialogMessage.addAction(ok)
                // Present dialog message to user
                self.present(dialogMessage, animated: true, completion: nil)
            }
        }
    }

    
    @IBAction func barButtonPressed(_ sender: Any) {
        dataArray.removeAll(keepingCapacity: false)
        self.performSegue(withIdentifier: "goToPemborong", sender: self)
    }
    
    // Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return pemborongDataArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.rowHeight = UITableView.automaticDimension
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "PemborongTableViewCell", for: indexPath) as! PemborongTableViewCell
        
        //Format Date from timestamp
        let date = Date(timeIntervalSince1970: TimeInterval(Double(pemborongDataArray[indexPath.row][2])!))
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        let stringDate = dateFormatter.string(from: date)
        
        cell.namaTimLabel.text = pemborongDataArray[indexPath.row][0]
        cell.creationDetailsLabel.text = "Created By: " + pemborongDataArray[indexPath.row][1] + " - " + stringDate
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if isSelect {
            self.delegate?.pemborongPanenReceived(pemborongPanen: self.pemborongDataArray[indexPath.row][0])
            self.navigationController?.popViewController(animated: true)
        }
        else {
            getPemborongData(documentName: self.pemborongDataArray[indexPath.row][0])
        }
    }
    
    //Add Table Cell Button Actions
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .normal, title: "Delete") {  (contextualAction, view, boolValue) in
            print("DELETE" + self.pemborongDataArray[indexPath.row][0])
            SVProgressHUD.show()
            //Delete Document from server
            let db = Firestore.firestore()
            db.collection("pemborongPanen").document(self.pemborongDataArray[indexPath.row][0]).delete()
            //Refresh Data Array and Table View
            self.pemborongDataArray.removeAll(keepingCapacity: false)
            self.getPemborongListFromServer()
        }
        delete.backgroundColor = .systemRed
        
        let swipeActions = UISwipeActionsConfiguration(actions: [delete])
        
        return swipeActions
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PemborongViewController
        {
            let vc = segue.destination as? PemborongViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.dataArray = dataArray
        }
    }
    
}
