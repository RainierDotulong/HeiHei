//
//  PettyCashViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 11/13/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import SVProgressHUD

class PettyCashViewController: UIViewController {
    
    var farmName : String = ""
    var fullName : String = ""
    var loginClass : String = ""
    var cycleNumber : Int = 0
    
    var action : String  = ""
    
    var pettyCashDataArray : [[String]] = [[String]]()

    @IBOutlet var cashInButton: UIButton!
    @IBOutlet var cashOutButton: UIButton!
    @IBOutlet var barButton: UIBarButtonItem!
    @IBOutlet var balanceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        if loginClass == "superadmin" || loginClass == "administrator" {
            cashInButton.isEnabled = true
        }
        else {
            cashInButton.isEnabled = false
        }
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
    
    @IBAction func cashOutButtonPressed(_ sender: Any) {
        action = "Cash Out"
        performSegue(withIdentifier: "goToPettyCashReport", sender: self)
    }
    @IBAction func cashInButtonPressed(_ sender: Any) {
        action = "Cash In"
        performSegue(withIdentifier: "goToPettyCashReport", sender: self)
    }
    @IBAction func barButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "goToPettyCashHistory", sender: self)
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
                    subArray.append(document.data()["category"] as? String ?? "")
                    subArray.append(document.data()["reporterName"] as! String)
                    subArray.append(document.data()["checked"] as! String)
                    self.pettyCashDataArray.append(subArray)
                }
                self.calculateCurrentBalance()
                SVProgressHUD.dismiss()
            }
        }
    }
    
    func calculateCurrentBalance() {
        var negativeCash : [String] = [String]()
        var positiveCash : [String] = [String]()
        for data in pettyCashDataArray {
            print(data)
            if data[1] == "Cash In" {
                positiveCash.append(data[2])
            }
            else if data[1] == "Cash Out" {
                negativeCash.append(data[2])
            }
        }
        let negativeCashInt = negativeCash.compactMap(Int.init)
        let negativeCashTotal = negativeCashInt.reduce(0, +)
        let positiveCashInt = positiveCash.compactMap(Int.init)
        let positiveCashTotal = positiveCashInt.reduce(0, +)
        
        let currentBalance = positiveCashTotal - negativeCashTotal
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let formattedBalance = numberFormatter.string(from: NSNumber(value:currentBalance))
        
        balanceLabel.text = "Rp." + formattedBalance!
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PettyCashReportViewController
        {
            let vc = segue.destination as? PettyCashReportViewController
            vc?.farmName = farmName
            vc?.cycleNumber = cycleNumber
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.action = action
        }
        else if segue.destination is PettyCashHistoryTableViewController
        {
            let vc = segue.destination as? PettyCashHistoryTableViewController
            vc?.farmName = farmName
            vc?.cycleNumber = cycleNumber
            vc?.fullName = fullName
            vc?.loginClass = loginClass
        }
    }
    
}
