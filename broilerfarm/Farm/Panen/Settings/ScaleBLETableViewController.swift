//
//  ScaleBLETableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/25/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import SVProgressHUD
import NotificationBannerSwift

class ScaleBleTableViewCell : UITableViewCell {
    @IBOutlet var nameLabel: UILabel!
}

class ScaleBLETableViewController: UITableViewController {
    
    var dataArray : [scaleBle] = [scaleBle]()

    @IBOutlet var barButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        // Remove seperator lines from empty cells
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        getDataFromServer(pullDownRefresh : false)
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    func getDataFromServer(pullDownRefresh : Bool) {
        if pullDownRefresh == false {
            SVProgressHUD.show()
        }
        Firestore.firestore().collection("scaleBle").addSnapshotListener { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
              print("No documents")
              if pullDownRefresh == true {
                  self.refreshControl?.endRefreshing()
              }
              else {
                  SVProgressHUD.dismiss()
              }
              return
            }
            
            self.dataArray = documents.compactMap { queryDocumentSnapshot -> scaleBle? in
              return try? queryDocumentSnapshot.data(as: scaleBle.self)
            }
            
            if pullDownRefresh == true {
                self.refreshControl?.endRefreshing()
            }
            else {
                SVProgressHUD.dismiss()
            }
            self.tableView.reloadData()
        }
    }

    @IBAction func barButtonPressed(_ sender: Any) {
        print("Bar Button Pressed")
        let alert = UIAlertController(title: "Add New Scale BLE", message:" Please Specify Data", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Name"
            textField.keyboardType = .default
            textField.autocapitalizationType = .allCharacters
        }
        
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            let textField = alert.textFields![0]
            
            guard textField.text ?? "" != "" else {
                print("Incomplete Data")
                let dialogMessage = UIAlertController(title: "Incomplete Data", message: "Text Field Empty", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            
            let ble = scaleBle(name: textField.text!)
            
            let isCreateSuccess = scaleBle.create(ble: ble)
            
            if isCreateSuccess {
                let banner = StatusBarNotificationBanner(title: "Scale BLE Record Uploaded!", style: .success)
                banner.show()
                self.tableView.reloadData()
            }
            else {
                let banner = StatusBarNotificationBanner(title: "Error Creating Scale BLE Record!", style: .danger)
                banner.show()
            }
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            print("Cancel button tapped")
        }
        
        alert.addAction(ok)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return dataArray.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        func createCell(data : scaleBle) -> ScaleBleTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "scaleBleCell", for: indexPath) as! ScaleBleTableViewCell
            
            cell.nameLabel.text = data.name
            
            return cell
        }
        
        return createCell(data: dataArray[indexPath.row])
    }
}
