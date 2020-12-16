//
//  CarcassHomepageTableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 6/25/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import UIEmptyState
import SVProgressHUD
import Firebase
import FirebaseFirestore
import NotificationBannerSwift

class CarcassHomepageTableViewCell : UITableViewCell {
    //carcassProductionCell
    @IBOutlet var batchIdLabel: UILabel!
    @IBOutlet var transportButton: UIButton!
    @IBOutlet var inputRpaButton: UIButton!
    @IBOutlet var outputRpaButton: UIButton!
}

class CarcassHomepageTableViewController: UITableViewController, UIEmptyStateDataSource, UIEmptyStateDelegate, UISearchResultsUpdating {
    
    //Initalize Variables passed from previous VC
    var fullName : String = ""
    var email : String = ""
    var loginClass : String = ""
    
    var dataArray : [CarcassProduction] = [CarcassProduction]()
    var filteredDataArray : [CarcassProduction] = [CarcassProduction]()
    var batchIDs : [String] = [String]()
    var selectedData : CarcassProduction = CarcassProduction(hargaBeliAyam: 0, transportName: "", transportBank: "", transportBankNumber: "", transportBankName: "", transportPaymentTerm: "", amountDueForTransport: 0, licensePlateNumber: "", sourceFarm: "", escort: "", transportedWeight: 0, transportedQuantity: 0, transportCreatedBy: "", transportCreatedTimestamp: 0, rpaName: "", rpaAddress: "", rpaLatitude: 0, rpaLongitude: 0, rpaNoNkv: "", rpaPerhitunganBiaya: "", rpaPaymentTerm: "", rpaSideProduct: false, rpaContactPerson: "", rpaContactPhone: "", rpaBank: "", rpaBankName: "", rpaBankNumber: "", slaughterTimestamp: 0, typeOfWork: "", receivedWeight: 0, receivedQuantity: 0, receivedDeadWeight: 0, receivedDeadQuantity: 0, rpaInputCreatedBy: "", rpaInputCreatedTimestamp: 0, yieldedWeight: 0, yieldedProductNames: [String](), yieldedProductUnits: [String](), yieldedProductQuantities: [Float](), initialStorageProvider: "", rpaOutputCreatedBy: "", rpaOutputCreatedTimestamp: 0, rpaHargaPerKG: 0)
    var edit : Bool = false
    
    @IBOutlet var navItem: UINavigationItem!
    @IBOutlet var leftBarButton: UIBarButtonItem!
    @IBOutlet var rightBarButton: UIBarButtonItem!
    
    var resultSearchController = UISearchController()
    
    //UI Empty State Variables
    var emptyStateTitle: NSAttributedString {
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor(red: 0.882, green: 0.890, blue: 0.859, alpha: 1.00),
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22)]
        return NSAttributedString(string: "No Carcass Production Data Found", attributes: attrs)
    }
    
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
        
        //Pull to Refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:  #selector(refresh), for: .valueChanged)
        self.refreshControl = refreshControl
        
        //SearchBar
        resultSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.obscuresBackgroundDuringPresentation = false
            controller.searchBar.sizeToFit()

            tableView.tableHeaderView = controller.searchBar

            return controller
        })()
        
        let CarcassProductionUpdatedNotification = Notification.Name("carcassProductionUpdated")
        NotificationCenter.default.addObserver(self, selector: #selector(carcassProductionUpdated(_:)), name: CarcassProductionUpdatedNotification, object: nil)
        
        getDataFromServer(pullDownRefresh : false)
        
    }
    
    @objc func carcassProductionUpdated(_ notification:Notification) {
        print("Carcass Production Successfully Created.")
        getDataFromServer(pullDownRefresh : false)
    }
    
    @objc func refresh() {
        print("Refresh")
        getDataFromServer(pullDownRefresh : true)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredDataArray.removeAll(keepingCapacity: false)

        let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchController.searchBar.text!)
        let array = (batchIDs as NSArray).filtered(using: searchPredicate)
        let filteredBatchIDArray = array as! [String]
        //construct Filtered Data Array
        for data in dataArray {
            for batchID in filteredBatchIDArray {
                if data.id == batchID {
                    filteredDataArray.append(data)
                }
            }
        }
        self.tableView.reloadData()
        self.reloadEmptyState()
    }
    
    @IBAction func leftBarButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "goToMenu", sender: self)
    }
    
    @IBAction func refreshButtonPressed(_ sender: Any) {
        print("Refresh")
        getDataFromServer(pullDownRefresh : false)
    }
    
    @IBAction func rightBarButtonPressed(_ sender: Any) {
        print("Add")
        edit = false
        selectedData = CarcassProduction(hargaBeliAyam: 0, transportName: "", transportBank: "", transportBankNumber: "", transportBankName: "", transportPaymentTerm: "", amountDueForTransport: 0, licensePlateNumber: "", sourceFarm: "", escort: "", transportedWeight: 0, transportedQuantity: 0, transportCreatedBy: "", transportCreatedTimestamp: 0, rpaName: "", rpaAddress: "", rpaLatitude: 0, rpaLongitude: 0, rpaNoNkv: "", rpaPerhitunganBiaya: "", rpaPaymentTerm: "", rpaSideProduct: false, rpaContactPerson: "", rpaContactPhone: "", rpaBank: "", rpaBankName: "", rpaBankNumber: "", slaughterTimestamp: 0, typeOfWork: "", receivedWeight: 0, receivedQuantity: 0, receivedDeadWeight: 0, receivedDeadQuantity: 0, rpaInputCreatedBy: "", rpaInputCreatedTimestamp: 0, yieldedWeight: 0, yieldedProductNames: [String](), yieldedProductUnits: [String](), yieldedProductQuantities: [Float](), initialStorageProvider: "", rpaOutputCreatedBy: "", rpaOutputCreatedTimestamp: 0, rpaHargaPerKG: 0)
        self.performSegue(withIdentifier: "goToTransportInput", sender: self)
    }
    
    @IBAction func transportButtonPressed(_ sender: UIButton) {
        print("Transport")
        if (resultSearchController.isActive) {
            selectedData = filteredDataArray[sender.tag]
            resultSearchController.isActive = false
            edit = true
            self.performSegue(withIdentifier: "goToTransportInput", sender: self)
        }
        else {
            edit = true
            selectedData = dataArray[sender.tag]
            self.performSegue(withIdentifier: "goToTransportInput", sender: self)
        }
    }
    
    @IBAction func inputRpaButtonPressed(_ sender: UIButton) {
        print("Input RPA")
        if (resultSearchController.isActive) {
            if filteredDataArray[sender.tag].receivedWeight != 0 {
                edit = true
            }
            else {
                edit = false
            }
            selectedData = filteredDataArray[sender.tag]
            resultSearchController.isActive = false
            self.performSegue(withIdentifier: "goToInputRPA", sender: self)
        }
        else {
            if dataArray[sender.tag].receivedWeight != 0 {
                edit = true
            }
            else {
                edit = false
            }
            selectedData = dataArray[sender.tag]
            self.performSegue(withIdentifier: "goToInputRPA", sender: self)
        }
    }
    
    @IBAction func outputRpaButtonPressed(_ sender: UIButton) {
        print("Output RPA")
        if (resultSearchController.isActive) {
            selectedData = filteredDataArray[sender.tag]
            resultSearchController.isActive = false
            edit = true
            self.performSegue(withIdentifier: "goToOutputRPA", sender: self)
        }
        else {
            edit = true
            selectedData = dataArray[sender.tag]
            self.performSegue(withIdentifier: "goToOutputRPA", sender: self)
        }
    }
    
    func getDataFromServer(pullDownRefresh : Bool) {
        if pullDownRefresh == false {
            SVProgressHUD.show()
        }
        Firestore.firestore().collection("carcassProduction").order(by: "transportCreatedTimestamp").addSnapshotListener { (querySnapshot, error) in
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
            
            self.dataArray = documents.compactMap { queryDocumentSnapshot -> CarcassProduction? in
              return try? queryDocumentSnapshot.data(as: CarcassProduction.self)
            }
            print(self.dataArray.count)
            
            self.batchIDs.removeAll(keepingCapacity: false)
            for data in self.dataArray {
                self.batchIDs.append(data.id!)
            }
            
            if pullDownRefresh == true {
                self.refreshControl?.endRefreshing()
            }
            else {
                SVProgressHUD.dismiss()
            }
            self.tableView.reloadData()
            self.reloadEmptyState()
        }
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if  (resultSearchController.isActive) {
            return filteredDataArray.count
        }
        else {
            return dataArray.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.rowHeight = UITableView.automaticDimension
        
        func createCells(data : CarcassProduction) -> CarcassHomepageTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "carcassProductionCell", for: indexPath) as! CarcassHomepageTableViewCell
            
            cell.batchIdLabel.text = "Batch ID: \(data.id!)"
            
            if data.transportName != "" {
                cell.transportButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
                cell.transportButton.tintColor = .link
                cell.transportButton.layer.cornerRadius = 5
                cell.transportButton.layer.borderWidth = 1
                cell.transportButton.layer.borderColor = UIColor.link.cgColor
                cell.transportButton.setTitleColor(.link, for: .normal)
            }
            else {
                cell.transportButton.setImage(UIImage(systemName: "circle"), for: .normal)
                cell.transportButton.tintColor = .gray
                cell.transportButton.layer.cornerRadius = 5
                cell.transportButton.layer.borderWidth = 1
                cell.transportButton.layer.borderColor = UIColor.gray.cgColor
                cell.transportButton.setTitleColor(.gray, for: .normal)
            }
            
            if data.receivedWeight != 0 {
                cell.inputRpaButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
                cell.inputRpaButton.tintColor = .link
                cell.inputRpaButton.layer.cornerRadius = 5
                cell.inputRpaButton.layer.borderWidth = 1
                cell.inputRpaButton.layer.borderColor = UIColor.link.cgColor
                cell.inputRpaButton.setTitleColor(.link, for: .normal)
            }
            else {
                cell.inputRpaButton.setImage(UIImage(systemName: "circle"), for: .normal)
                cell.inputRpaButton.tintColor = .gray
                cell.inputRpaButton.layer.cornerRadius = 5
                cell.inputRpaButton.layer.borderWidth = 1
                cell.inputRpaButton.layer.borderColor = UIColor.gray.cgColor
                cell.inputRpaButton.setTitleColor(.gray, for: .normal)
            }
            
            if data.yieldedWeight != 0 {
                cell.outputRpaButton.isEnabled = false
                cell.outputRpaButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
                cell.outputRpaButton.tintColor = .link
                cell.outputRpaButton.layer.cornerRadius = 5
                cell.outputRpaButton.layer.borderWidth = 1
                cell.outputRpaButton.layer.borderColor = UIColor.link.cgColor
                cell.outputRpaButton.setTitleColor(.link, for: .normal)
            }
            else {
                cell.outputRpaButton.isEnabled = true
                cell.outputRpaButton.setImage(UIImage(systemName: "circle"), for: .normal)
                cell.outputRpaButton.tintColor = .gray
                cell.outputRpaButton.layer.cornerRadius = 5
                cell.outputRpaButton.layer.borderWidth = 1
                cell.outputRpaButton.layer.borderColor = UIColor.gray.cgColor
                cell.outputRpaButton.setTitleColor(.gray, for: .normal)
            }
            
            cell.transportButton.tag = indexPath.row
            cell.inputRpaButton.tag = indexPath.row
            cell.outputRpaButton.tag = indexPath.row
            
            return cell
        }
        
        if (resultSearchController.isActive) {
            return createCells(data: filteredDataArray[indexPath.row])
        }
        else {
            return createCells(data: dataArray[indexPath.row])
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToMenu" {
            let nvc = segue.destination as? UINavigationController
            let vc = nvc?.topViewController as? MenuListTableViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
        }
        else if segue.identifier == "goToTransportInput" {
            let vc = segue.destination as? TransportInputViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.selectedData = selectedData
            vc?.edit = edit
        }
        else if segue.identifier == "goToInputRPA" {
            let vc = segue.destination as? InputRPAViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.selectedData = selectedData
            vc?.edit = edit
        }
        else if segue.identifier == "goToOutputRPA" {
            let vc = segue.destination as? OutputRPAViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.selectedData = selectedData
            vc?.edit = edit
        }
    }
}
