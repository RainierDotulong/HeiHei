//
//  PembayaranTableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/28/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage
import NotificationBannerSwift
import SVProgressHUD
import EmptyStateKit

class PembayaranTableViewCell : UITableViewCell {
    //pembayaranCell
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var nominalLabel: UILabel!
    @IBOutlet var actionLabel: UILabel!
    @IBOutlet var createdAccByLabel: UILabel!
    @IBOutlet var statusImageView: UIImageView!
}

class PembayaranTableViewController: UITableViewController, EmptyStateDelegate, UISearchResultsUpdating {
    
    //Initalize Variables passed from previous VC
    var farmName : String = ""
    var fullName : String = ""
    var loginClass : String = ""
    var cycleNumber : Int  = 0
    var numberOfFloors : Int  = 0
    
    var dataArray : [Pembayaran] = [Pembayaran]()
    var filteredDataArray : [Pembayaran] = [Pembayaran]()
    var namaPerusahaan : [String] = [String]()
    
    var isEdit : Bool = false
    var selectedPembayaran : Pembayaran = Pembayaran(creationTimestamp: 0, accTimestamp: 0, isAcc: false, isRefunded: false, nominal: 0, accBy: "", perusahaanId: "", perusahaanName: "", perusahaanType: "", rekeningName: "", bank: "", bankNumber: "", createdBy: "")
    
    var resultSearchController = UISearchController()

    @IBOutlet var addButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        view.emptyState.delegate = self
        
        // Remove seperator lines from empty cells
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        //SearchBar
        resultSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.obscuresBackgroundDuringPresentation = false
            controller.searchBar.sizeToFit()

            tableView.tableHeaderView = controller.searchBar

            return controller
        })()
        
        //Pull to Refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:  #selector(refresh), for: .valueChanged)
        self.refreshControl = refreshControl
        
        getDataFromServer(pullDownRefresh: false)
    }
    
    @objc func refresh() {
        print("Refresh")
        getDataFromServer(pullDownRefresh : true)
    }
    
    func emptyState(emptyState: EmptyState, didPressButton button: UIButton) {
        if resultSearchController.isActive {
            resultSearchController.isActive = false
        }
        getDataFromServer(pullDownRefresh: false)
        view.emptyState.hide()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredDataArray.removeAll(keepingCapacity: false)

        let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchController.searchBar.text!)
        let array = (namaPerusahaan as NSArray).filtered(using: searchPredicate)
        let filteredPerusahaan = array as! [String]
        //construct Filtered Data Array
        for data in dataArray {
            for perusahaan in filteredPerusahaan {
                if data.perusahaanName == perusahaan {
                    filteredDataArray.append(data)
                }
            }
        }
        self.tableView.reloadData()
        reloadEmptyStateKit(state: "noSearch")
    }
    
    func getDataFromServer(pullDownRefresh : Bool) {
        print("Get Panen Data \(farmName) \(cycleNumber)")
        if pullDownRefresh == false {
            SVProgressHUD.show()
        }
        Firestore.firestore().collection("\(farmName)\(cycleNumber)Pembayaran").order(by: "creationTimestamp", descending: true).addSnapshotListener { (querySnapshot, error) in
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
            
            self.dataArray = documents.compactMap { queryDocumentSnapshot -> Pembayaran? in
              return try? queryDocumentSnapshot.data(as: Pembayaran.self)
            }
            
            self.namaPerusahaan.removeAll(keepingCapacity: false)
            for data in self.dataArray {
                if self.namaPerusahaan.contains(data.perusahaanName) ==  false {
                    self.namaPerusahaan.append(data.perusahaanName)
                }
            }
            
            if pullDownRefresh == true {
                self.refreshControl?.endRefreshing()
            }
            else {
                SVProgressHUD.dismiss()
            }
            self.tableView.reloadData()
            self.reloadEmptyStateKit(state: "noData")
        }
    }
    
    func acc(data: Pembayaran) {
        var pembayaran = data
        var accString = ""
        if pembayaran.isAcc {
            pembayaran.isAcc = false
            accString = "ACC Cancelled"
        }
        else {
            pembayaran.isAcc = true
            accString = "ACC"
        }
        pembayaran.accBy = fullName
        let isUpdateSuccess = Pembayaran.update(farmName: farmName, cycleNumber: cycleNumber, pembayaran: pembayaran)
                
        if isUpdateSuccess {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            let formattedNominal = numberFormatter.string(from: NSNumber(value:data.nominal))
            
            let telegramText = "*Payment \(accString) (\(farmName.capitalized) - \(cycleNumber))*\n-------------------------------------\nPerusahaan: \(data.perusahaanName)\nNominal: Rp.\(formattedNominal!)\nACC by: \(self.fullName)"

            Telegram().postTelegramMessage(botToken: Telegram().ChickenAppBotToken, chatID: Telegram().PembayaranPanenCFChatID, text: telegramText, parse_mode: "Markdown")
        }
        else {
            let banner = StatusBarNotificationBanner(title: "Error Updating Pembayaran Record! (ACC", style: .danger)
            banner.show()
        }
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        print("Add")
        self.isEdit = false
        self.performSegue(withIdentifier: "goToPembayaran", sender: self)
    }
    
    func reloadEmptyStateKit(state: String) {
        if (self.resultSearchController.isActive) {
            if self.filteredDataArray.isEmpty {
                switch state{
                case "noData":
                    self.view.emptyState.show(State.noData)
                case "noSearch":
                    self.view.emptyState.show(State.noSearch)
                default:
                    self.view.emptyState.show(State.noInternet)
                }
            }
            else {
                self.view.emptyState.hide()
            }
        }
        else {
            if self.dataArray.isEmpty {
                switch state{
                case "noData":
                    self.view.emptyState.show(State.noData)
                case "noSearch":
                    self.view.emptyState.show(State.noSearch)
                default:
                    self.view.emptyState.show(State.noInternet)
                }
            }
            else {
                self.view.emptyState.hide()
            }
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
        
        func createCell(data : Pembayaran) -> PembayaranTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "pembayaranCell", for: indexPath) as! PembayaranTableViewCell
            
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            let formattedNominal = numberFormatter.string(from: NSNumber(value:data.nominal))
            
            cell.titleLabel.text = data.perusahaanName
            cell.nominalLabel.text = "Rp. \(formattedNominal!)"
            if data.isRefunded == true {
                cell.actionLabel.text = "Refund - \(data.rekeningName)"
                cell.backgroundColor = .lightGray
            }
            else {
                cell.actionLabel.text = "Payment - \(data.rekeningName)"
                cell.backgroundColor = .none
            }
            if data.isAcc {
                cell.statusImageView.image = UIImage(named: "acc")
                cell.createdAccByLabel.text = "ACC By: \(data.accBy)"
            }
            else {
                cell.statusImageView.image = UIImage(named: "posted")
                cell.createdAccByLabel.text = "Posted By: \(data.createdBy)"
            }
            
            return cell
        }
        if (resultSearchController.isActive) {
            return createCell(data: filteredDataArray[indexPath.row])
        }
        else {
            return createCell(data: dataArray[indexPath.row])
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if (resultSearchController.isActive) {
            if filteredDataArray[indexPath.row].isAcc == false {
                self.isEdit = true
                self.selectedPembayaran = filteredDataArray[indexPath.row]
                self.performSegue(withIdentifier: "goToPembayaran", sender: self)
            }
        }
        else {
            if dataArray[indexPath.row].isAcc == false {
                self.isEdit = true
                self.selectedPembayaran = dataArray[indexPath.row]
                self.performSegue(withIdentifier: "goToPembayaran", sender: self)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let acc = UIContextualAction(style: .normal, title: "ACC") {  (contextualAction, view, boolValue) in
                        
            if (self.resultSearchController.isActive) {
                if self.filteredDataArray[indexPath.row].isAcc {
                    print("Cancel ACC \(self.filteredDataArray[indexPath.row].perusahaanName)")
                }
                else {
                    print("ACC \(self.filteredDataArray[indexPath.row].perusahaanName)")
                }
                self.acc(data: self.filteredDataArray[indexPath.row])
            }
            else {
                if self.dataArray[indexPath.row].isAcc {
                    print("Cancel ACC \(self.dataArray[indexPath.row].perusahaanName)")
                }
                else {
                    print("ACC \(self.dataArray[indexPath.row].perusahaanName)")
                }
                self.acc(data: self.dataArray[indexPath.row])
            }
        }
        
        if (self.resultSearchController.isActive) {
            if filteredDataArray[indexPath.row].isAcc {
                acc.image = UIImage(systemName: "xmark.circle.fill")
                acc.title = "Cancel\nACC"
                acc.backgroundColor = .systemRed
            }
            else {
                acc.image = UIImage(systemName: "checkmark.circle.fill")
                acc.title = "ACC"
                acc.backgroundColor = .systemGreen
            }
        }
        else {
            if dataArray[indexPath.row].isAcc {
                acc.image = UIImage(systemName: "xmark.circle.fill")
                acc.title = "Cancel\nACC"
                acc.backgroundColor = .systemRed
            }
            else {
                acc.image = UIImage(systemName: "checkmark.circle.fill")
                acc.title = "ACC"
                acc.backgroundColor = .systemGreen
            }
        }
        
        switch loginClass {
        case "superadmin":
            return UISwipeActionsConfiguration(actions: [acc])
        default:
            return UISwipeActionsConfiguration(actions: [])
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PembayaranViewController
        {
            let vc = segue.destination as? PembayaranViewController
            
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.cycleNumber = cycleNumber
            vc?.numberOfFloors = numberOfFloors
            vc?.isEdit = isEdit
            vc?.selectedPembayaran = selectedPembayaran
        }
    }
}
