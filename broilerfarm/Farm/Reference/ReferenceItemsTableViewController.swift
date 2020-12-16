//
//  ReferenceItemsTableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 12/21/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit

class ReferenceItemsTableViewCell : UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var itemImageView: UIImageView!
    
}

class ReferenceItemsTableViewController: UITableViewController {
    
    var fullName : String = ""
    var selectedFarm : String = ""
    var selectedFloor : String = ""
    
     var selectedItem : String = ""
    
    var itemsArray : [String] = [String]()

    @IBOutlet var navItem: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        navItem.title = selectedFarm.uppercased() + " - LT." + selectedFloor
        itemsArray = ["bw", "adg", "deplesi", "pakan", "fcr", "effTemp","populasi","ip"]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }

    // Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemsArray.count
    }
    
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
           tableView.rowHeight = UITableView.automaticDimension
           
           let cell = tableView.dequeueReusableCell(withIdentifier: "referenceItemsTableViewCell", for: indexPath) as! ReferenceItemsTableViewCell
        switch itemsArray[indexPath.row] {
        case "bw":
            cell.titleLabel.text = "Body Weight"
            cell.itemImageView.image = UIImage(named: "bw")
        case "adg":
            cell.titleLabel.text = "Average Daily Growth"
            cell.itemImageView.image = UIImage(named: "adg")
        case "deplesi":
            cell.titleLabel.text = "Deplesi"
            cell.itemImageView.image = UIImage(named: "deplesi")
        case "pakan":
            cell.titleLabel.text = "Pakan"
            cell.itemImageView.image = UIImage(named: "pakan")
        case "fcr":
            cell.titleLabel.text = "Feed Conversion Ratio"
            cell.itemImageView.image = UIImage(named: "fcr")
        case "effTemp":
            cell.titleLabel.text = "Effective Temperature"
            cell.itemImageView.image = UIImage(named: "effectiveTemperature")
        case "populasi":
            cell.titleLabel.text = "Populasi"
            cell.itemImageView.image = UIImage(named: "populasi")
        case "ip":
            cell.titleLabel.text = "IP"
            cell.itemImageView.image = UIImage(named: "ip")
        default:
            print("Unidentified Item!")
        }
           
           return cell
       }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(itemsArray[indexPath.row])
        selectedItem = itemsArray[indexPath.row]
        self.performSegue(withIdentifier: "goToReferenceData", sender: self)
       }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
           return 90
       }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is ReferenceDataViewController
        {
            let vc = segue.destination as? ReferenceDataViewController
            vc?.fullName = fullName
            vc?.selectedFarm = selectedFarm
            vc?.selectedFloor = selectedFloor
            vc?.selectedItem = selectedItem
        }
    }
}
