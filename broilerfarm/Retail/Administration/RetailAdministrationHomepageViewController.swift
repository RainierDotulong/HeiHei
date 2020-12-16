//
//  RetailAdministrationHomepageViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 4/22/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit

class RetailAdministrationHomepageViewController: UIViewController {
    
    var loginClass : String = ""
    var fullName : String = ""
    
    var isArchive : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        print(fullName)
    }
    @IBAction func purchaseOrdersButtonPressed(_ sender: Any) {
        print("Purchase Orders")
        isArchive = false
        self.performSegue(withIdentifier: "goToPurchaseOrders", sender: self)
    }
    @IBAction func archiveButtonPressed(_ sender: Any) {
        print("Archive")
        isArchive = true
        self.performSegue(withIdentifier: "goToPurchaseOrders", sender: self)
    }
    @IBAction func customersButtonPressed(_ sender: Any) {
        print("Customers")
        self.performSegue(withIdentifier: "goToCustomers", sender: self)
    }
    @IBAction func productsButtonPressed(_ sender: Any) {
        print("Products")
        self.performSegue(withIdentifier: "goToProducts", sender: self)
    }
    @IBAction func stockButtonPressed(_ sender: Any) {
        print("Stock")
        self.performSegue(withIdentifier: "goToStock", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is RetailCustomersTableViewController
        {
            let vc = segue.destination as? RetailCustomersTableViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.previousMenu = "Administration"
        }
        else if segue.destination is RetailProductsTableViewController
        {
            let vc = segue.destination as? RetailProductsTableViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.previousMenu = "Administration"
        }
        else if segue.destination is RetailPurchaseOrdersTableViewController
        {
            let vc = segue.destination as? RetailPurchaseOrdersTableViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.previousMenu = "Administration"
            vc?.isArchive = isArchive
        }
        else if segue.destination is RetailStockTableViewController
        {
            let vc = segue.destination as? RetailStockTableViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
        }
    }
}
