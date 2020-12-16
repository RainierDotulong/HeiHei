//
//  ReferenceDataViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 12/21/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import SVProgressHUD
import NotificationBannerSwift

class ReferenceDataTableViewCell : UITableViewCell {
    @IBOutlet var ageLabel: UILabel!
    @IBOutlet var dataLabel: UILabel!
}


class ReferenceDataViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var fullName : String = ""
    var selectedFarm : String = ""
    var selectedFloor : String = ""
    var selectedItem : String = ""
    
    @IBOutlet var navItem: UINavigationItem!
    @IBOutlet var templatePickerView: UIPickerView!
    @IBOutlet var referenceDataTableView: UITableView!
    @IBOutlet var itemLabel: UILabel!
    @IBOutlet var setButton: UIButton!
    
    var referenceData : [String] = [String]()
    var tableViewData : [String] = [String]()
    var pickerData : [String] = ["Current"]
    
    var templateDataArray : [[String]] = [[String]]()
    var selectedTemplate : String = "Current"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        navItem.title = selectedFarm.uppercased() + " - LT." + selectedFloor
        itemLabel.text = selectedItem.uppercased()
        
        getReferenceData()
        
        getReferenceTemplateData()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    @IBAction func setButtonPressed(_ sender: Any) {
        guard selectedTemplate != "Current" else {
            print ("Selected Template is already set to current Reference")
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Invalid Selection", message: "Selected Template is already set as current Reference", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        uploadReferenceData()
    }
    
    func uploadReferenceData() {
        setButton.isEnabled = false
        //Upload Data to Server
        let doc = Firestore.firestore().collection("reference").document(selectedFarm + "floor" + selectedFloor)
        doc.setData([
            selectedItem : self.tableViewData
        ],merge: true) { err in
            if let err = err {
                print("Error writing Reference Document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error writing Reference Document", style: .danger)
                banner.show()
                self.setButton.isEnabled = true
            } else {
                print("Reference Document successfully written!")
                let banner = StatusBarNotificationBanner(title: "Reference Update Success", style: .success)
                banner.show()
                self.setButton.isEnabled = true
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func getReferenceData() {
        referenceData.removeAll(keepingCapacity: false)
        SVProgressHUD.show()
        let db = Firestore.firestore()
        let docRef = db.collection("reference").document(selectedFarm + "floor" + selectedFloor)
        let zerosArray : [String] = Array(repeating: "0", count: 46)
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                self.referenceData = document.data()?[self.selectedItem] as? [String] ?? zerosArray
                print(self.referenceData)
                print(self.referenceData.count)
                self.tableViewData = self.referenceData
                self.referenceDataTableView.reloadData()
                SVProgressHUD.dismiss()
            } else {
                print("Document does not exist")
                SVProgressHUD.dismiss()
                //Declare Alert message
                let dialogMessage = UIAlertController(title: "Current Reference Document does not exist", message: "Please Set Reference", preferredStyle: .alert)
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
    
    func getReferenceTemplateData() {
        templateDataArray.removeAll(keepingCapacity: false)
        SVProgressHUD.show()
        let db = Firestore.firestore()
        db.collection("referenceTemplate").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                SVProgressHUD.dismiss()
            } else {
                for document in querySnapshot!.documents {
                    //print("\(document.documentID) => \(document.data())")

                    if document.documentID.components(separatedBy: "-")[1] == self.selectedItem.uppercased() {
                        self.pickerData.append(document.documentID.components(separatedBy: "-")[0])
                        self.templateDataArray.append(document.data()["data"] as! [String])
                    }
                }
                print(self.pickerData)
                self.templatePickerView.reloadAllComponents()
                SVProgressHUD.dismiss()
            }
        }
    }
    
    //TableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.rowHeight = UITableView.automaticDimension
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "referenceDataTableViewCell", for: indexPath) as! ReferenceDataTableViewCell
        
        cell.ageLabel.text = String(indexPath.row)
        cell.dataLabel.text = tableViewData[indexPath.row]

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        print(tableViewData[indexPath.row])
        
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    //PickerView Data Source
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedTemplate = pickerData[row]
        print(pickerData[row])
        if row == 0 {
            tableViewData = referenceData
            referenceDataTableView.reloadData()
        }
        else {
            print(templateDataArray[row - 1])
            tableViewData = templateDataArray[row - 1]
            referenceDataTableView.reloadData()
        }
    }
}
