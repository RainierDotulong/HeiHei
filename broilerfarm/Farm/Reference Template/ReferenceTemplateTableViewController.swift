//
//  ReferenceTemplateTableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 12/21/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import SVProgressHUD
import FirebaseStorage

class ReferenceTemplateTableViewCell : UITableViewCell {
    @IBOutlet var templateNameLabel: UILabel!
    @IBOutlet var timestampFullNameLabel: UILabel!
    @IBOutlet var categoryImageView: UIImageView!
}

class ReferenceTemplateTableViewController: UITableViewController {
    
    var fullName : String = ""
    
    @IBOutlet var navItem: UINavigationItem!
    
    var newFlag : Bool = true
    
    var templateArray : [[String]] = [[String]]()
    var templateDataArray : [[String]] = [[String]]()
    
    var selectedTemplateArray : [String] = [String]()
    var selectedTemplateDataArray : [String] = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getReferenceTemplateData()
    }

    @IBAction func addButtonPressed(_ sender: Any) {
        print("New Template")
        newFlag = true
        self.performSegue(withIdentifier: "goToNewReferenceTemplate", sender: self)
    }
    
    func getReferenceTemplateData() {
        templateArray.removeAll(keepingCapacity: false)
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
                    self.templateArray.append([document.documentID,document.data()["fullName"] as! String,document.data()["timestamp"] as! String])
                    self.templateDataArray.append(document.data()["data"] as! [String])

                }
                SVProgressHUD.dismiss()
            }
            self.tableView.reloadData()
        }
    }
    
   // Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return templateArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.rowHeight = UITableView.automaticDimension
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReferenceTemplateTableViewCell", for: indexPath) as! ReferenceTemplateTableViewCell
        
        //Format Date from timestamp
        let date = Date(timeIntervalSince1970: TimeInterval(Double(templateArray[indexPath.row][2])!))
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let stringDate = dateFormatter.string(from: date)
        
        let template = templateArray[indexPath.row][0].components(separatedBy: "-")
        
        cell.templateNameLabel.text = template[0]
        
        switch template[1] {
        case "BW":
            cell.categoryImageView.image = UIImage(named: "bw")
        case "ADG":
            cell.categoryImageView.image = UIImage(named: "adg")
        case "DEPLESI":
            cell.categoryImageView.image = UIImage(named: "deplesi")
        case "PAKAN":
            cell.categoryImageView.image = UIImage(named: "pakan")
        case "FCR":
            cell.categoryImageView.image = UIImage(named: "fcr")
        case "EFFTEMP":
            cell.categoryImageView.image = UIImage(named: "effectiveTemperature")
        case "POPULASI":
            cell.categoryImageView.image = UIImage(named: "populasi")
        case "IP":
            cell.categoryImageView.image = UIImage(named: "ip")
        default:
            print("Unidentified Item!")
        }
        
        cell.timestampFullNameLabel.text = stringDate + ", by " + templateArray[indexPath.row][1]

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(templateArray[indexPath.row])
        newFlag = false
        selectedTemplateArray = templateArray[indexPath.row]
        selectedTemplateDataArray = templateDataArray[indexPath.row]
        self.performSegue(withIdentifier: "goToNewReferenceTemplate", sender: self)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
           return 85
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is NewReferenceTemplateViewController
        {
            let vc = segue.destination as? NewReferenceTemplateViewController
            vc?.fullName = fullName
            vc?.newFlag = newFlag
            vc?.selectedTemplateArray = selectedTemplateArray
            vc?.selectedTemplateDataArray = selectedTemplateDataArray
        }
    }
}
