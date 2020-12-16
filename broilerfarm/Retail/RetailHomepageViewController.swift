//
//  RetailHomepageViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 4/23/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit

class RetailHomepageViewController: UIViewController {
    
    //Initalize Variables passed from previous VC
    var fullName : String = ""
    var email : String = ""
    var loginClass : String = ""
    
    var pressedButton : String = ""

    @IBOutlet var administrationButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        if loginClass == "administrator" || loginClass == "superadmin" || loginClass == "retailAdministrator" {
            administrationButton.isEnabled = true
        }
        else {
            administrationButton.isEnabled = false
        }
    }
    
    @IBAction func preparationTicketsButtonPressed(_ sender: Any) {
        print("Preparation Tickets")
        pressedButton = "Preparation Tickets"
        self.performSegue(withIdentifier: "goToPurchaseOrders", sender: self)
    }
    @IBAction func deliveriesButtonPressed(_ sender: Any) {
        print("Deliveries")
        pressedButton = "Deliveries"
        self.performSegue(withIdentifier: "goToPurchaseOrders", sender: self)
    }
    @IBAction func stockButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "goToStock", sender: self)
    }
    @IBAction func administrationButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "goToAdministration", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is RetailPurchaseOrdersTableViewController
        {
            let vc = segue.destination as? RetailPurchaseOrdersTableViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.previousMenu = "Retail"
            if pressedButton == "Preparation Tickets" {
                vc?.filterBy = "Created"
            }
            else if pressedButton == "Deliveries" {
                vc?.filterBy = "Quality Checked & Delivery In Progress"
            }
            vc?.isArchive = false
        }
        else if segue.destination is RetailStockTableViewController
        {
            let vc = segue.destination as? RetailStockTableViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
        }
        else if segue.destination is RetailAdministrationHomepageViewController
        {
            let vc = segue.destination as? RetailAdministrationHomepageViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
        }
    }
}
