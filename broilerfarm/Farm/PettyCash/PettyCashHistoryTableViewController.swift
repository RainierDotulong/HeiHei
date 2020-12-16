//
//  PettyCashHistoryTableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 11/13/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import SVProgressHUD
import UIEmptyState
import QuickLook
import NotificationBannerSwift

class PettyCashHistoryTableViewCell : UITableViewCell {
    @IBOutlet var nominalLabel: UILabel!
    @IBOutlet var categoryLabel: UILabel!
    @IBOutlet var reporterNameLabel: UILabel!
    @IBOutlet var timestampLabel: UILabel!
    @IBOutlet var inOutImageView: UIImageView!
    @IBOutlet var checkImageView: UIImageView!
}

class PettyCashHistoryTableViewController: UITableViewController, UIEmptyStateDataSource, UIEmptyStateDelegate, QLPreviewControllerDataSource {
    
    //UI Empty State Variables
    var emptyStateTitle: NSAttributedString {
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor(red: 0.882, green: 0.890, blue: 0.859, alpha: 1.00),
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22)]
        return NSAttributedString(string: "Petty Cash History Empty", attributes: attrs)
    }
    
    var farmName : String = ""
    var fullName : String = ""
    var loginClass : String = ""
    var cycleNumber : Int = 0
    
    var selectedTimestamp : String = ""
    var selectedAction : String = ""
    var selectedChecked : String = ""
    var selectedNominal : String = ""
    var selectedCategory : String = ""
    var selectedReporterName : String = ""
    
    var pettyCashDataArray : [[String]] = [[String]]()
    
    var csvPath : URL = URL(string: "https://www.globalxtreme.net")!
    
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
        
        print(farmName)
        print(fullName)
        print(loginClass)
        print(cycleNumber)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getPettyCashDataFromServer()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    @IBAction func exportButtonPressed(_ sender: Any) {
        let fileName = "\(farmName.uppercased() + "-PettyCash").csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        var csvText = "Tanggal,Action,Nominal,Category,Reporter,Checked\n"
        
        let count = pettyCashDataArray.count
        
        if count > 0 {
            for i in 1...pettyCashDataArray.count {
                //Format Date
                let date = Date(timeIntervalSince1970: Double(pettyCashDataArray[i-1][0])! )
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short
                let stringDate = dateFormatter.string(from: date).replacingOccurrences(of: ",", with: "")
                
                let newLine = "\(stringDate),\(pettyCashDataArray[i-1][1]),\(pettyCashDataArray[i-1][2]),\(pettyCashDataArray[i-1][3]),\(pettyCashDataArray[i-1][4]),\(pettyCashDataArray[i-1][5])\n"

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
            
        } else {
            print("There is no data to export")
        }
    }
    
    func getPettyCashDataFromServer() {
        SVProgressHUD.show()
        let db = Firestore.firestore()
        db.collection("\(farmName)\(cycleNumber)PettyCash").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                SVProgressHUD.dismiss()
            } else {
                self.pettyCashDataArray.removeAll(keepingCapacity: false)
                for document in querySnapshot!.documents {
                    var subArray = [String]()
                    //Setting up data
                    subArray.append(document.documentID)
                    subArray.append(document.data()["action"] as! String)
                    subArray.append(document.data()["nominal"] as! String)
                    subArray.append(document.data()["category"] as! String)
                    subArray.append(document.data()["reporterName"] as! String)
                    subArray.append(document.data()["checked"] as! String)
                    self.pettyCashDataArray.append(subArray)
                }
                self.tableView.reloadData()
                self.reloadEmptyState()
                SVProgressHUD.dismiss()
            }
        }
    }
    
    //    let usersRef = Firestore.firestore().collection("userProfiles").document(userID)
    //    usersRef.setData(["fcmToken": token], merge: true)
    
    
    func deleteEntry(doc : String) {
        let db = Firestore.firestore()
        db.collection("\(farmName)\(cycleNumber)PettyCash").document(doc).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error removing document", style: .danger)
                banner.show()
            } else {
                print("Document successfully removed!")
                self.getPettyCashDataFromServer()
                let banner = StatusBarNotificationBanner(title: "Document successfully removed!", style: .success)
                banner.show()
            }
        }
        tableView.reloadData()
        self.reloadEmptyState()
    }
    
    func checkEntry(doc : String) {
        SVProgressHUD.show()
        let docRef = Firestore.firestore().collection("\(farmName)\(cycleNumber)PettyCash").document(doc)
        docRef.updateData(["checked": "true"])
        getPettyCashDataFromServer()
    }
    // Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pettyCashDataArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.rowHeight = UITableView.automaticDimension
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let fomattedNominal = numberFormatter.string(from: NSNumber(value:Int(pettyCashDataArray[pettyCashDataArray.count - indexPath.row - 1][2])!))
        //Get Date
        let date = Date(timeIntervalSince1970: Double(pettyCashDataArray[pettyCashDataArray.count - indexPath.row - 1][0])!)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        let stringDate = dateFormatter.string(from: date)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "pettyCashCell", for: indexPath) as! PettyCashHistoryTableViewCell
        cell.nominalLabel.text = "Nominal: Rp." + fomattedNominal!
        cell.categoryLabel.text = pettyCashDataArray[pettyCashDataArray.count - indexPath.row - 1][3]
        cell.reporterNameLabel.text = "Reported By: " + pettyCashDataArray[pettyCashDataArray.count - indexPath.row - 1][4]
        cell.timestampLabel.text = stringDate
        if pettyCashDataArray[pettyCashDataArray.count - indexPath.row - 1][1] == "Cash In" {
            cell.inOutImageView.image = UIImage(named: "moneyIn")
        }
        else if pettyCashDataArray[pettyCashDataArray.count - indexPath.row - 1][1] == "Cash Out" {
            cell.inOutImageView.image = UIImage(named: "moneyOut")
        }
        
        if pettyCashDataArray[pettyCashDataArray.count - indexPath.row - 1][5] == "true" {
            cell.checkImageView.image = UIImage(named : "success")
        }
        else if pettyCashDataArray[pettyCashDataArray.count - indexPath.row - 1][5] == "false" {
            cell.checkImageView.image = UIImage(named : "error")
        }

        return cell
    }
    
    //Add Table Cell Button Actions
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let delete = UIContextualAction(style: .normal, title: "Delete") {  (contextualAction, view, boolValue) in
            self.deleteEntry(doc: self.pettyCashDataArray[self.pettyCashDataArray.count - indexPath.row - 1][0])
        }
        delete.image = UIImage(systemName: "trash")
        delete.backgroundColor = .systemRed

        let checked = UIContextualAction(style: .normal, title: "Checked") {  (contextualAction, view, boolValue) in
            self.checkEntry(doc: self.pettyCashDataArray[self.pettyCashDataArray.count - indexPath.row - 1][0])
        }
        checked.image = UIImage(systemName: "checkmark.circle")
        checked.backgroundColor = .systemGreen
        
        if loginClass == "superadmin" && self.pettyCashDataArray[self.pettyCashDataArray.count - indexPath.row - 1][5] == "false" || loginClass == "administrator" && self.pettyCashDataArray[self.pettyCashDataArray.count - indexPath.row - 1][5] == "false" {
            let swipeActions = UISwipeActionsConfiguration(actions: [checked, delete])
            return swipeActions
        }
        else if loginClass == "superadmin" || loginClass == "administrator" {
            let swipeActions = UISwipeActionsConfiguration(actions: [delete])
            return swipeActions
        }
        else {
            let swipeActions = UISwipeActionsConfiguration(actions: [])
            return swipeActions
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(self.pettyCashDataArray[pettyCashDataArray.count - indexPath.row - 1][2])
        selectedTimestamp = self.pettyCashDataArray[pettyCashDataArray.count - indexPath.row - 1][0]
        selectedAction = self.pettyCashDataArray[pettyCashDataArray.count - indexPath.row - 1][1]
        selectedChecked = self.pettyCashDataArray[pettyCashDataArray.count - indexPath.row - 1][5]
        selectedNominal = self.pettyCashDataArray[pettyCashDataArray.count - indexPath.row - 1][2]
        selectedCategory = self.pettyCashDataArray[pettyCashDataArray.count - indexPath.row - 1][3]
        selectedReporterName = self.pettyCashDataArray[pettyCashDataArray.count - indexPath.row - 1][4]
        
        self.performSegue(withIdentifier: "goToHistoryDetails", sender: self)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    //QLPreviewController Methods
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return csvPath as QLPreviewItem
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PettyCashHistoryDetailsViewController
        {
            let vc = segue.destination as? PettyCashHistoryDetailsViewController
            vc?.farmName = farmName
            vc?.cycleNumber = cycleNumber
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.selectedTimestamp = selectedTimestamp
            vc?.selectedAction = selectedAction
            vc?.selectedChecked = selectedChecked
            vc?.selectedNominal = selectedNominal
            vc?.selectedCategory = selectedCategory
            vc?.selectedReporterName = selectedReporterName
        }
    }
}
