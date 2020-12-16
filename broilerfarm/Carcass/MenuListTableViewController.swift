//
//  MenuListTableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 6/22/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit

class MenuListTableViewController : UITableViewController {
    
    var loginClass : String = ""
    var fullName : String = ""
    
    var items = ["Transport Providers","RPA","Products","Storages"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //tableView.backgroundColor = UIColor(red: 204/255.0, green: 0/255.0, blue: 34/255.0, alpha: 1)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "menuCell")
        
        // Remove seperator lines from empty cells
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("\(items[indexPath.row]) Selected")
        tableView.deselectRow(at: indexPath, animated: true)
        //Action
        switch items[indexPath.row] {
        case "Transport Providers":
            self.performSegue(withIdentifier: "goToTransportProviders", sender: self)
        case "RPA":
            self.performSegue(withIdentifier: "goToRPA", sender: self)
        case "Products":
            self.performSegue(withIdentifier: "goToProducts", sender: self)
        case "Storages":
            self.performSegue(withIdentifier: "goToStorages", sender: self)
        default:
            print("Unspecified Menu Selected")
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "menuCell", for : indexPath)
        cell.textLabel?.text = items[indexPath.row]
        cell.textLabel?.textColor = .black
        //cell.backgroundColor = UIColor(red: 204/255.0, green: 0/255.0, blue: 34/255.0, alpha: 1)
        switch items[indexPath.row] {
        case "Transport Providers":
            cell.imageView?.image = UIImage(systemName: "car.fill")
        case "RPA":
            cell.imageView?.image = UIImage(systemName: "house.fill")
        case "Products":
            cell.imageView?.image = UIImage(systemName: "cube.box.fill")
        case "Storages":
            cell.imageView?.image = UIImage(systemName: "tray.2.fill")
        default:
            print("Unspecified Menu")
            cell.imageView?.image = UIImage(systemName: "checkmark.circle.fill")
        }
        cell.imageView?.tintColor = .black
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is TransportProvidersTableViewController
        {
            let vc = segue.destination as? TransportProvidersTableViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
        }
        else if segue.destination is  RPATableViewController
        {
            let vc = segue.destination as? RPATableViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
        }
        else if segue.destination is  RPAProductsTableViewController
        {
            let vc = segue.destination as? RPAProductsTableViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
        }
        else if segue.destination is  StorageProvidersTableViewController
        {
            let vc = segue.destination as? StorageProvidersTableViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
        }
    }
}
