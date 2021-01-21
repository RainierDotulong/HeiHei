//
//  PanenTableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/19/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage
import NotificationBannerSwift
import JGProgressHUD
import SVProgressHUD
import EmptyStateKit
import QuickLook

class PanenTableViewCell : UITableViewCell {
    //panenCell
    @IBOutlet var statusImageView: UIImageView!
    @IBOutlet var namaPerusahaanLabel: UILabel!
    @IBOutlet var jumlahKGLabel: UILabel!
    @IBOutlet var rangeBBLabel: UILabel!
    @IBOutlet var sopirKendaraanLabel: UILabel!
    @IBOutlet var nomorPanenLabel: UILabel!
    @IBOutlet var sumLabel: UILabel!
}

class PanenTableViewController: UITableViewController, EmptyStateDelegate, UISearchResultsUpdating, QLPreviewControllerDataSource {
    
    //Initalize Variables passed from previous VC
    var farmName : String = ""
    var fullName : String = ""
    var email : String = ""
    var loginClass : String = ""
    var cycleNumber : Int  = 0
    var numberOfFloors : Int  = 0
    
    var isEdit : Bool = false
    
    var filterBy : String = "All"
    var fullDataArray : [Panen] = [Panen]()
    var dataArray : [Panen] = [Panen]()
    var filteredDataArray : [Panen] = [Panen]()
    var selectedData = Panen(id: "", creationTimestamp: 0, isChecked: false, hargaPerKG: 0, mulaiMuatTimestamp: 0, selesaiMuatTimestamp: 0, jumlahKGDO: 0, namaPerusahaan: "", alamatPerusahaan: "", metodePembayaran: "", namaSopir: "", noKendaraaan: "", noSopir: "", pembuatDO: "", rangeBB: "", rangeBawah: 0, rangeAtas: 0, status: "", pengambilanTimestamp: 0, timestamps: [Double](), lantai: [Int](), jumlah: [Int](), isSubtract: [Bool](), isVoided: [Bool](), sekat: [String](), tara: [Float](), berat: [Float](), pemborongPanen: "", penimbang: "", accBy: "")
    
    var namaPerusahaan : [String] = [String]()

    
    var resultSearchController = UISearchController()
    
    var hud = JGProgressHUD(style: .dark)
    
    //File paths
    let fileManager = FileManager.default
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    var filePath = ""
    var exportFlag : Bool  = false
    var csvPath : URL = URL(string: "https://www.globalxtreme.net")!
    var floorDetails : [FarmFloorDetail] = [FarmFloorDetail]()

    @IBOutlet var settingsButton: UIBarButtonItem!
    @IBOutlet var shareButton: UIBarButtonItem!
    @IBOutlet var filterButton: UIBarButtonItem!
    @IBOutlet var barButton: UIBarButtonItem!
    
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
        
        let PanenChangeNotification = Notification.Name("panenChanged")
        NotificationCenter.default.addObserver(self, selector: #selector(panenChanged(_:)), name: PanenChangeNotification, object: nil)
        
        let longpress = UILongPressGestureRecognizer(target: self, action: #selector(PanenTableViewController.longPressGestureRecognized(_:)))
        tableView.addGestureRecognizer(longpress)

        
        if loginClass == "administrator" || loginClass == "superadmin" {
            barButton.isEnabled = true
            settingsButton.isEnabled = true
        }
        else {
            barButton.isEnabled = false
            settingsButton.isEnabled = false
        }
        getDataFromServer(pullDownRefresh: false)
    }
    
    func emptyState(emptyState: EmptyState, didPressButton button: UIButton) {
        if resultSearchController.isActive {
            resultSearchController.isActive = false
        }
        getDataFromServer(pullDownRefresh: false)
        view.emptyState.hide()
    }
    
    @IBAction func refreshButtonPressed(_ sender: Any) {
        getDataFromServer(pullDownRefresh: false)
    }
    
    func getFloorCycleData() {
    
        SVProgressHUD.show()
        floorDetails.removeAll(keepingCapacity: false)
        for floor in 1...numberOfFloors {
            let cycle = Firestore.firestore().collection(self.farmName + "Details").document("floor\(floor)Cycle\(cycleNumber)Details")
            
            cycle.getDocument { (document, error) in
                if let document = document, document.exists {
                    var floorDetail : FarmFloorDetail = FarmFloorDetail(farmName: self.farmName, cycleNumber: self.cycleNumber, floorNumber: floor, startingBodyWeight: 0, startingPopulation: 0, startTimestamp: 0, claimAge: 0, claimQuantity: 0, harvestedWeight: 0, harvestedQuantity: 0, pakanAwal : 0)
                    floorDetail.startingBodyWeight = Float(truncating: document.data()!["startingBodyWeight"] as! NSNumber)
                    floorDetail.startingPopulation = document.data()!["startingPopulation"] as! Int
                    floorDetail.startTimestamp = document.data()!["startTimestamp"] as! Double
                    floorDetail.claimAge = document.data()!["claimAge"] as! Int
                    floorDetail.claimQuantity = document.data()!["claimQuantity"] as! Int
                    floorDetail.harvestedWeight = Float(truncating: document.data()!["harvestedWeight"] as! NSNumber)
                    floorDetail.harvestedQuantity = document.data()!["harvestedQuantity"] as! Int
                    floorDetail.pakanAwal = document.data()!["pakanAwal"] as! Int
                    self.floorDetails.append(floorDetail)
                    
                    if self.floorDetails.count == self.numberOfFloors {
                        self.constructAdminDetailedPanenCsv(dataArray: self.dataArray)
                    }
                    SVProgressHUD.dismiss()
                }
                else {
                    print("Floor Cycle Document does not exist")
                    SVProgressHUD.dismiss()
                    let dialogMessage = UIAlertController(title: "Floor \(floor) Cycle Document does not exist", message: "Please Contact Administrator", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                        print("Ok button tapped")
                    })
                    dialogMessage.addAction(ok)
                    self.present(dialogMessage, animated: true, completion: nil)
                }
            }
        }
    }
    
    @objc func longPressGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        guard loginClass == "superadmin" else {
            print("Long Press")
            return
        }
        let longPress = gestureRecognizer as! UILongPressGestureRecognizer
        let locationInView = longPress.location(in: tableView)
        let indexPath = tableView.indexPathForRow(at: locationInView)
        
        print("Delete Harvest")
        let dialogMessage = UIAlertController(title: "Confirm Destructive Action", message: "Delete Panen Record?", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: { (action) -> Void in
            print("Cancel button tapped")
        })
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            if  (self.resultSearchController.isActive) {
                print("Delete Harvest \(self.filteredDataArray[indexPath!.row].namaSopir)")
                self.deletePanenRecord(data: self.filteredDataArray[indexPath!.row])
            }
            else {
                print("Delete Harvest \(self.dataArray[indexPath!.row].namaSopir)")
                self.deletePanenRecord(data: self.dataArray[indexPath!.row])
            }
        })
        dialogMessage.addAction(cancel)
        dialogMessage.addAction(ok)
        self.present(dialogMessage, animated: true, completion: nil)
        return
        
    }
    
    @IBAction func settingsButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "goToSettings", sender: self)
    }
    
    @IBAction func shareButtonPressed(_ sender: Any) {
        print("Share")
        exportFlag = true
        
        let dialogMessage = UIAlertController(title: "Export Data Panen", message: "Select Export Type", preferredStyle: .alert)
        
        let summary = UIAlertAction(title: "Summary", style: .default, handler: { (action) -> Void in
            print("Summary button tapped")
            if self.loginClass == "administrator" ||  self.loginClass == "superadmin" {
                self.constructAdminSummaryPanenCsv(dataArray: self.dataArray)
            }
            else {
                self.constructSummaryPanenCsv(dataArray: self.dataArray)
            }
        })
        let detailed = UIAlertAction(title: "Detailed", style: .default, handler: { (action) -> Void in
            print("Detailed button tapped")
            if self.loginClass == "administrator" ||  self.loginClass == "superadmin" {
                self.getFloorCycleData()
            }
            else {
                self.constructDetailedPanenCsv(dataArray: self.dataArray)
            }
        })
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: { (action) -> Void in
            print("Cancel button tapped")
        })
        
        dialogMessage.addAction(summary)
        dialogMessage.addAction(detailed)
        dialogMessage.addAction(cancel)
        
        self.present(dialogMessage, animated: true, completion: nil)
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func filterButtonPressed(_ sender: Any) {
        print("Filter")
        let dialogMessage = UIAlertController(title: "Filter By", message: "Select Filter Type", preferredStyle: .alert)
        
        let none = UIAlertAction(title: "None", style: .default, handler: { (action) -> Void in
            print("None Stock button tapped")
            self.filterBy = "All"
            self.filterData()
        })
        let created = UIAlertAction(title: "Created", style: .default, handler: { (action) -> Void in
            print("Created Stock button tapped")
            self.filterBy = "Created"
            self.filterData()
        })
        let acc = UIAlertAction(title: "ACC", style: .default, handler: { (action) -> Void in
            print("Prepped button tapped")
            self.filterBy = "ACC"
            self.filterData()
        })
        let started = UIAlertAction(title: "Started", style: .default, handler: { (action) -> Void in
            self.filterBy = "Started"
            self.filterData()
        })
        let finished = UIAlertAction(title: "Finished", style: .default, handler: { (action) -> Void in
            self.filterBy = "Finished"
            self.filterData()
        })
        
        dialogMessage.addAction(none)
        dialogMessage.addAction(created)
        dialogMessage.addAction(acc)
        dialogMessage.addAction(started)
        dialogMessage.addAction(finished)
        
        self.present(dialogMessage, animated: true, completion: nil)
    }
    
    @IBAction func barButtonPressed(_ sender: Any) {
        print("Add")
        isEdit = false
        self.performSegue(withIdentifier: "goToPanenEdit", sender: self)
    }
    
    @objc func refresh() {
        print("Refresh")
        getDataFromServer(pullDownRefresh : true)
    }
       
    @objc func panenChanged(_ notification:Notification) {
        print("Panen Changed")
        getDataFromServer(pullDownRefresh : false)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredDataArray.removeAll(keepingCapacity: false)

        let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchController.searchBar.text!)
        let array = (namaPerusahaan as NSArray).filtered(using: searchPredicate)
        let filteredPerusahaan = array as! [String]
        //construct Filtered Data Array
        for data in dataArray {
            for perusahaan in filteredPerusahaan {
                if data.namaPerusahaan == perusahaan {
                    filteredDataArray.append(data)
                }
            }
        }
        self.tableView.reloadData()
        self.reloadEmptyStateKit(state: "noSearch")
    }
    
    func deletePanenRecord(data : Panen) {
        let db = Firestore.firestore()
        db.collection("\(farmName)\(cycleNumber)Panen").document(data.id!).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error Removing Panen Record", style: .danger)
                banner.show()
            } else {
                print("Document successfully removed!")
                let banner = StatusBarNotificationBanner(title: "Panen Record Successfully Removed", style: .success)
                banner.show()
            }
        }
    }
    
    func getDataFromServer(pullDownRefresh : Bool) {
        print("Get Panen Data \(farmName) \(cycleNumber)")
        if pullDownRefresh == false {
            SVProgressHUD.show()
        }
        Firestore.firestore().collection("\(farmName)\(cycleNumber)Panen").order(by: "creationTimestamp").addSnapshotListener { (querySnapshot, error) in
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
            
            self.fullDataArray = documents.compactMap { queryDocumentSnapshot -> Panen? in
              return try? queryDocumentSnapshot.data(as: Panen.self)
            }
            
            self.namaPerusahaan.removeAll(keepingCapacity: false)
            for data in self.fullDataArray {
                if self.namaPerusahaan.contains(data.namaPerusahaan) ==  false {
                    self.namaPerusahaan.append(data.namaPerusahaan)
                }
            }
            
            if pullDownRefresh == true {
                self.refreshControl?.endRefreshing()
            }
            else {
                SVProgressHUD.dismiss()
            }
            self.filterData()
        }
    }
    
    func filterData() {
        if filterBy == "All" {
            dataArray = fullDataArray
        }
        else {
            dataArray.removeAll()
            for data in fullDataArray {
                if data.status == filterBy {
                    dataArray.append(data)
                }
            }
        }
        self.tableView.reloadData()
        self.reloadEmptyStateKit(state: "noData")
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
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
        
        func createCell(data : Panen) -> PanenTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "panenCell", for: indexPath) as! PanenTableViewCell
            
            var validJumlah : [Int] = [Int]()
            var validBerat : [Float] = [Float]()
            var validTara : [Float] = [Float]()
            for i in 0..<data.isVoided.count {
                if data.isVoided[i] == false && data.isSubtract[i] == false {
                    validJumlah.append(data.jumlah[i])
                    validBerat.append(data.berat[i])
                    validTara.append(data.tara[i])
                }
            }
            cell.namaPerusahaanLabel.text = data.namaPerusahaan
            cell.jumlahKGLabel.text = "Jumlah KG DO: \(String(format: "%.2f", data.jumlahKGDO)) KG"
            cell.rangeBBLabel.text = "Range BB: \(data.rangeBB)"
            let totalEkor = validJumlah.reduce(0,+)
            let netto = validBerat.reduce(0,+) - validTara.reduce(0,+)
            let total = (netto * Float(data.hargaPerKG))
            print("Name: \(data.namaPerusahaan) kgdo: \(data.berat)")
            cell.sumLabel.text = "Sum: \(total.avoidNotation) / HargaPerKG: \(data.hargaPerKG)"
            cell.sopirKendaraanLabel.text = "Sopir: \(data.namaSopir) (\(data.noKendaraaan))"
            cell.nomorPanenLabel.text = "NO: \(farmName.prefix(1).uppercased())\(cycleNumber)-\(Int(data.creationTimestamp))"
            
            switch data.status {
            case "Created":
                cell.statusImageView.image = UIImage(named: "created")
            case "ACC":
                cell.statusImageView.image = UIImage(named: "acc")
            case "Started":
                cell.statusImageView.image = UIImage(named: "started")
            case "Finished":
                cell.statusImageView.image = UIImage(named: "finished")
            default:
                print("Unknown Panen Status")
            }
            
            if data.isChecked {
                cell.backgroundColor = UIColor(red: 0, green: 1, blue: 0, alpha: 0.1)
            }
            else {
                cell.backgroundColor = .none
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
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let acc = UIContextualAction(style: .normal, title: "ACC") {  (contextualAction, view, boolValue) in
            func updateStatus(status: String, data : Panen) {
                let doc = Firestore.firestore().collection("\(self.farmName)\(self.cycleNumber)Panen").document(data.id!)
                doc.updateData([
                "status" : status,
                "accBy" : self.fullName
                ]) { err in
                if let err = err {
                    print("Error writing Panen Document: \(err)")
                    let banner = StatusBarNotificationBanner(title: "Error ACC Document", style: .danger)
                    banner.show()
                    
                } else {
                    print("Panen Document successfully written!")
                    var telegramText = ""
                    if status == "ACC" {
                        telegramText = "*PANEN ACC (\(self.farmName.prefix(1).uppercased())\(self.cycleNumber)-\(Int(data.creationTimestamp)))*\n-------------------------------------\nPerusahaan: \(data.namaPerusahaan)\nNo Kendaraan: \(data.noKendaraaan)\nRange BB: \(data.rangeBB)\nSopir:\(data.namaSopir) (\(data.noSopir))\nMetode Pembayaran: \(data.metodePembayaran)\nACC Oleh: \(self.fullName)"
                    }
                    else {
                        telegramText = "*PANEN ACC CANCEL (\(self.farmName.prefix(1).uppercased())\(self.cycleNumber)-\(Int(data.creationTimestamp)))*\n-------------------------------------\nPerusahaan: \(data.namaPerusahaan)\nNo Kendaraan: \(data.noKendaraaan)\nRange BB: \(data.rangeBB)\nSopir:\(data.namaSopir) (\(data.noSopir))\nMetode Pembayaran: \(data.metodePembayaran)\nDibatalkan Oleh: \(self.fullName)"
                    }
                    Telegram().postTelegramMessage(botToken: Telegram().ChickenAppBotToken, chatID: Telegram().TeamPanenChatID, text: telegramText, parse_mode: "Markdown")
                }
            }
        }
        
        if (self.resultSearchController.isActive) {
            if self.filteredDataArray[indexPath.row].status == "ACC" {
                //Set DataArray component to ACC
                for i in 0..<self.dataArray.count {
                    if self.dataArray[i].id == self.filteredDataArray[indexPath.row].id {
                        self.dataArray[i].status = "Created"
                    }
                }
                //Set Filtered DataArray component to ACC
                self.filteredDataArray[indexPath.row].status = "Created"
                self.tableView.reloadData()
                updateStatus(status: "Created", data: self.filteredDataArray[indexPath.row])
            }
            else {
                //Set DataArray component to ACC
                for i in 0..<self.dataArray.count {
                    if self.dataArray[i].id == self.filteredDataArray[indexPath.row].id {
                        self.dataArray[i].status = "ACC"
                    }
                }
                //Set Filtered DataArray component to ACC
                self.filteredDataArray[indexPath.row].status = "ACC"
                self.tableView.reloadData()
                updateStatus(status: "ACC", data: self.filteredDataArray[indexPath.row])
            }
        }
        else {
            if self.dataArray[indexPath.row].status == "ACC" {
                //Set DataArray component to ACC
                self.dataArray[indexPath.row].status = "Created"
                self.tableView.reloadData()
                updateStatus(status: "Created", data: self.dataArray[indexPath.row])
            }
            else {
                //Set DataArray component to ACC
                self.dataArray[indexPath.row].status = "ACC"
                self.tableView.reloadData()
                updateStatus(status: "ACC", data: self.dataArray[indexPath.row])
            }
        }
        }
        
        if (self.resultSearchController.isActive) {
            if filteredDataArray[indexPath.row].status == "ACC" {
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
            if dataArray[indexPath.row].status == "ACC" {
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
        
        let deliveryOrder = UIContextualAction(style: .normal, title: "DO") {  (contextualAction, view, boolValue) in
            
            if (self.resultSearchController.isActive) {
                self.selectedData = self.filteredDataArray[indexPath.row]
                self.resultSearchController.isActive = false
                self.performSegue(withIdentifier: "goToDeliveryOrder", sender: self)
            }
            else {
                self.selectedData = self.dataArray[indexPath.row]
                self.performSegue(withIdentifier: "goToDeliveryOrder", sender: self)
            }
        }
        
        deliveryOrder.image = UIImage(systemName: "doc.text.fill")
        deliveryOrder.backgroundColor = .systemYellow
        
        let invoice = UIContextualAction(style: .normal, title: "INV") {  (contextualAction, view, boolValue) in
            
            if (self.resultSearchController.isActive) {
                self.selectedData = self.filteredDataArray[indexPath.row]
                self.resultSearchController.isActive = false
                self.performSegue(withIdentifier: "goToInvoice", sender: self)
            }
            else {
                self.selectedData = self.dataArray[indexPath.row]
                self.performSegue(withIdentifier: "goToInvoice", sender: self)
            }
        }
        
        if (self.resultSearchController.isActive) {
            if filteredDataArray[indexPath.row].jumlah.isEmpty {
                invoice.title = "P-INV"
            }
            else {
                invoice.title = "INV"
            }
        }
        else {
            if dataArray[indexPath.row].jumlah.isEmpty {
                invoice.title = "P-INV"
            }
            else {
                invoice.title = "INV"
            }
        }
        
        invoice.image = UIImage(systemName: "doc.text.fill")
        invoice.backgroundColor = .systemGray
        
        let edit = UIContextualAction(style: .normal, title: "Edit") {  (contextualAction, view, boolValue) in
            
            if (self.resultSearchController.isActive) {
                self.selectedData = self.filteredDataArray[indexPath.row]
            }
            else {
                self.selectedData = self.dataArray[indexPath.row]
            }
            
            guard self.selectedData.status != "Started" else {
                print("Started Panen Cannot be edited")
                let dialogMessage = UIAlertController(title: "Invalid Panen Status", message: "Started Panen Cannot be Edited.", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            self.isEdit = true
            self.performSegue(withIdentifier: "goToPanenEdit", sender: self)
        }
        
        edit.image = UIImage(systemName: "square.and.pencil")
        edit.backgroundColor = .systemBlue
        
        let sj = UIContextualAction(style: .normal, title: "SJ") {  (contextualAction, view, boolValue) in
            
            if (self.resultSearchController.isActive) {
                self.selectedData = self.filteredDataArray[indexPath.row]
                self.exportFlag = false
            }
            else {
                self.selectedData = self.dataArray[indexPath.row]
                self.exportFlag = false
            }
            self.checkForFileExistance(data : self.selectedData)
        }
        
        sj.image = UIImage(systemName: "doc.richtext")
        sj.backgroundColor = .gray
        
        switch loginClass {
        case "superadmin":
            if (self.resultSearchController.isActive) {
                switch filteredDataArray[indexPath.row].status {
                case "Created":
                    return UISwipeActionsConfiguration(actions: [acc,invoice,deliveryOrder,edit])
                case "ACC":
                    return UISwipeActionsConfiguration(actions: [acc,invoice,deliveryOrder,edit])
                case "Started":
                    return UISwipeActionsConfiguration(actions: [invoice,deliveryOrder])
                case "Finished":
                    return UISwipeActionsConfiguration(actions: [sj,invoice,deliveryOrder])
                default:
                    print("Unknown Status")
                    return UISwipeActionsConfiguration(actions: [])
                }
            }
            else {
                switch dataArray[indexPath.row].status {
                case "Created":
                    return UISwipeActionsConfiguration(actions: [acc,invoice,deliveryOrder,edit])
                case "ACC":
                    return UISwipeActionsConfiguration(actions: [acc,invoice,deliveryOrder,edit])
                case "Started":
                    return UISwipeActionsConfiguration(actions: [invoice,deliveryOrder])
                case "Finished":
                    return UISwipeActionsConfiguration(actions: [sj,invoice,deliveryOrder])
                default:
                    print("Unknown Status")
                    return UISwipeActionsConfiguration(actions: [])
                }
            }
        case "administrator":
            if (self.resultSearchController.isActive) {
                switch filteredDataArray[indexPath.row].status {
                case "Created":
                    return UISwipeActionsConfiguration(actions: [acc,invoice,deliveryOrder,edit])
                case "ACC":
                    return UISwipeActionsConfiguration(actions: [acc,invoice,deliveryOrder,edit])
                case "Started":
                    return UISwipeActionsConfiguration(actions: [invoice,deliveryOrder])
                case "Finished":
                    return UISwipeActionsConfiguration(actions: [sj,invoice,deliveryOrder])
                default:
                    print("Unknown Status")
                    return UISwipeActionsConfiguration(actions: [])
                }
            }
            else {
                switch dataArray[indexPath.row].status {
                case "Created":
                    return UISwipeActionsConfiguration(actions: [acc,invoice,deliveryOrder,edit])
                case "ACC":
                    return UISwipeActionsConfiguration(actions: [acc,invoice,deliveryOrder,edit])
                case "Started":
                    return UISwipeActionsConfiguration(actions: [invoice,deliveryOrder])
                case "Finished":
                    return UISwipeActionsConfiguration(actions: [sj,invoice,deliveryOrder])
                default:
                    print("Unknown Status")
                    return UISwipeActionsConfiguration(actions: [])
                }
            }
        case "harvester":
            if (self.resultSearchController.isActive) {
                switch filteredDataArray[indexPath.row].status {
                case "Created":
                    return UISwipeActionsConfiguration(actions: [deliveryOrder])
                case "ACC":
                    return UISwipeActionsConfiguration(actions: [deliveryOrder])
                case "Started":
                    return UISwipeActionsConfiguration(actions: [deliveryOrder])
                case "Finished":
                    return UISwipeActionsConfiguration(actions: [sj,deliveryOrder])
                default:
                    print("Unknown Status")
                    return UISwipeActionsConfiguration(actions: [])
                }
            }
            else {
                switch dataArray[indexPath.row].status {
                case "Created":
                    return UISwipeActionsConfiguration(actions: [deliveryOrder])
                case "ACC":
                    return UISwipeActionsConfiguration(actions: [deliveryOrder])
                case "Started":
                    return UISwipeActionsConfiguration(actions: [deliveryOrder])
                case "Finished":
                    return UISwipeActionsConfiguration(actions: [sj,deliveryOrder])
                default:
                    print("Unknown Status")
                    return UISwipeActionsConfiguration(actions: [])
                }
            }
        default:
            return UISwipeActionsConfiguration(actions: [])
        }
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let check = UIContextualAction(style: .normal, title: "Check") {  (contextualAction, view, boolValue) in
            func CheckDO(isChecked : Bool, data : Panen) {
                let doc = Firestore.firestore().collection("\(self.farmName)\(self.cycleNumber)Panen").document(data.id!)
                doc.updateData([
                    "isChecked" : isChecked
                ]) { err in
                    if let err = err {
                        print("Error writing Panen Document: \(err)")
                        let banner = StatusBarNotificationBanner(title: "Error Checking Document", style: .danger)
                        banner.show()
                        self.getDataFromServer(pullDownRefresh: false)
                    } else {
                        print("Panen Document successfully written!")
                    }
                }
            }
            
            if (self.resultSearchController.isActive) {
                //Set DataArray component to true
                if self.filteredDataArray[indexPath.row].isChecked {
                    for i in 0..<self.dataArray.count {
                        if self.dataArray[i].id == self.filteredDataArray[indexPath.row].id {
                            self.dataArray[i].isChecked = false
                        }
                    }
                    //Set Filtered DataArray component to true
                    self.filteredDataArray[indexPath.row].isChecked = false
                    tableView.reloadData()
                    CheckDO(isChecked: false, data: self.filteredDataArray[indexPath.row])
                }
                else {
                    for i in 0..<self.dataArray.count {
                        if self.dataArray[i].id == self.filteredDataArray[indexPath.row].id {
                            self.dataArray[i].isChecked = true
                        }
                    }
                    //Set Filtered DataArray component to true
                    self.filteredDataArray[indexPath.row].isChecked = true
                    tableView.reloadData()
                    CheckDO(isChecked: true, data: self.filteredDataArray[indexPath.row])
                }
            }
            else {
                //Set DataArray component to true
                if self.dataArray[indexPath.row].isChecked {
                    self.dataArray[indexPath.row].isChecked = false
                    tableView.reloadData()
                    CheckDO(isChecked: false, data: self.dataArray[indexPath.row])
                }
                else {
                    self.dataArray[indexPath.row].isChecked = true
                    tableView.reloadData()
                    CheckDO(isChecked: true, data: self.dataArray[indexPath.row])
                }
            }
        }
        if (self.resultSearchController.isActive) {
            if filteredDataArray[indexPath.row].isChecked {
                check.image = UIImage(systemName: "xmark.seal.fill")
                check.title = "Uncheck"
                check.backgroundColor = .systemRed
            }
            else {
                check.image = UIImage(systemName: "checkmark.seal.fill")
                check.title = "Check"
                check.backgroundColor = .systemGreen
            }
        }
        else {
            if dataArray[indexPath.row].isChecked {
                check.image = UIImage(systemName: "xmark.seal.fill")
                check.title = "Uncheck"
                check.backgroundColor = .systemRed
            }
            else {
                check.image = UIImage(systemName: "checkmark.seal.fill")
                check.title = "Check"
                check.backgroundColor = .systemGreen
            }
        }
        
        let recording = UIContextualAction(style: .normal, title: "RP") {  (contextualAction, view, boolValue) in
                        
            if (self.resultSearchController.isActive) {
                self.selectedData = self.filteredDataArray[indexPath.row]
                self.exportFlag = true
            }
            else {
                self.selectedData = self.dataArray[indexPath.row]
                self.exportFlag = true
            }
            guard self.selectedData.status == "Finished" else {
                let dialogMessage = UIAlertController(title: "Invalid Panen Status", message: "Panen Belum Selesai.", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            self.createRecordingCsv(data: self.selectedData)
        }
        
        recording.image = UIImage(systemName: "doc.on.doc.fill")
        recording.backgroundColor = .gray
        
        switch loginClass {
        case "superadmin":
            return UISwipeActionsConfiguration(actions: [check,recording])
        default:
            return UISwipeActionsConfiguration(actions: [recording])
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if (resultSearchController.isActive) {
            selectedData = filteredDataArray[indexPath.row]
            print(selectedData.id)
        }
        else {
            selectedData = dataArray[indexPath.row]
            print(selectedData.id)
        }
        
        switch selectedData.status {
        case "ACC":
            self.performSegue(withIdentifier: "goToPanen", sender: self)
        case "Started":
            guard selectedData.penimbang == fullName else {
                let dialogMessage = UIAlertController(title: "Invalid User", message: "Panen Sudah Dimulai Oleh Orang Lain (\(selectedData.penimbang))", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            self.performSegue(withIdentifier: "goToPanen", sender: self)
        default:
            let dialogMessage = UIAlertController(title: "Invalid Panen Status", message: "Panen belum ACC / Sudah selesai.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
        }
    }
    
    func createRecordingCsv(data: Panen) {
        guard data.berat.count > 0 else {
            print("Empty Recording")
            return
        }
        
        let fileName = "\(farmName.prefix(1).uppercased())\(cycleNumber)-\(Int(data.creationTimestamp))RP.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        let csvText = PanenFunctions().constructRecordingCsv(data: data)
        
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
    }
    
    func constructAdminSummaryPanenCsv(dataArray: [Panen]) {
        let fileName = "\(farmName.prefix(1).uppercased())\(cycleNumber)-Panen.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        
        var csvText = ""
        csvText.append("Nama Perusahaan,Alamat Perusahaan,Tanggal Pembuatan,Mulai Muat,Selesai Muat,Status,KG DO,Range BB,Ekor Panen,KG Panen,Average BB,Harga/KG,Total(RP)\n")
        for data in dataArray {
            
            //Create String Dates
            let creationDate = Date(timeIntervalSince1970: data.creationTimestamp)
            let mulaiMuatDate = Date(timeIntervalSince1970: data.mulaiMuatTimestamp)
            let selesaiMuatDate = Date(timeIntervalSince1970: data.selesaiMuatTimestamp)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let creationStringDate = dateFormatter.string(from: creationDate).replacingOccurrences(of: ",", with: " ")
            let mulaiMuatStringDate = dateFormatter.string(from: mulaiMuatDate).replacingOccurrences(of: ",", with: " ")
            let selesaiMuatStringDate = dateFormatter.string(from: selesaiMuatDate).replacingOccurrences(of: ",", with: " ")
            
            //Calculate Totals
            let panenTotals = PanenFunctions().calculateTotals(data: data)
            let averageBBString = "\(String(format: "%.2f", panenTotals.averageBB).replacingOccurrences(of: ",", with: " ")) KG"
            let nettoString = "\(String(format: "%.2f", panenTotals.netto).replacingOccurrences(of: ",", with: " "))"
            let totalRp = String(format: "%.0f", Float(data.hargaPerKG) * panenTotals.netto)
            
            csvText.append("\(data.namaPerusahaan),\(data.alamatPerusahaan),\(creationStringDate),\(mulaiMuatStringDate),\(selesaiMuatStringDate),\(data.status),\(data.jumlahKGDO),\(data.rangeBB),\(panenTotals.totalEkor),\(nettoString),\(averageBBString),\(data.hargaPerKG),\(totalRp)\n")
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
    }
    
    func constructSummaryPanenCsv(dataArray: [Panen]) {
        let fileName = "\(farmName.prefix(1).uppercased())\(cycleNumber)-Panen.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        
        var csvText = ""
        csvText.append("Nama Perusahaan,Alamat Perusahaan,Tanggal Pembuatan,Mulai Muat,Selesai Muat,Status,KG DO,Range BB,Ekor Panen,KG Panen,Average BB\n")
        for data in dataArray {
            
            //Create String Dates
            let creationDate = Date(timeIntervalSince1970: data.creationTimestamp)
            let mulaiMuatDate = Date(timeIntervalSince1970: data.mulaiMuatTimestamp)
            let selesaiMuatDate = Date(timeIntervalSince1970: data.selesaiMuatTimestamp)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let creationStringDate = dateFormatter.string(from: creationDate).replacingOccurrences(of: ",", with: " ")
            let mulaiMuatStringDate = dateFormatter.string(from: mulaiMuatDate).replacingOccurrences(of: ",", with: " ")
            let selesaiMuatStringDate = dateFormatter.string(from: selesaiMuatDate).replacingOccurrences(of: ",", with: " ")
            
            //Calculate Totals
            let panenTotals = PanenFunctions().calculateTotals(data: data)
            let averageBBString = "\(String(format: "%.2f", panenTotals.averageBB).replacingOccurrences(of: ",", with: " ")) KG"
            let nettoString = "\(String(format: "%.2f", panenTotals.netto).replacingOccurrences(of: ",", with: " "))"
            
            csvText.append("\(data.namaPerusahaan),\(data.alamatPerusahaan),\(creationStringDate),\(mulaiMuatStringDate),\(selesaiMuatStringDate),\(data.status),\(data.jumlahKGDO),\(data.rangeBB),\(panenTotals.totalEkor),\(nettoString),\(averageBBString)\n")
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
    }
    func constructAdminLantaiDetailedCsv(dataArray: [Panen]) {
        let fileName = "\(farmName.prefix(1).uppercased())\(cycleNumber)-Panen-Lantai-Detailed.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
    }
    
    func constructAdminDetailedPanenCsv(dataArray: [Panen]) {
        let fileName = "\(farmName.prefix(1).uppercased())\(cycleNumber)-Panen-Detailed.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        
        var csvText = ""
        for data in dataArray {
            csvText.append("Nama Perusahaan,Alamat Perusahaan,Tanggal Pembuatan,Mulai Muat,Selesai Muat,Status,KG DO,Range BB,Harga/KG,Total (Rp)\n")
            //Create String Dates
            let creationDate = Date(timeIntervalSince1970: data.creationTimestamp)
            let mulaiMuatDate = Date(timeIntervalSince1970: data.mulaiMuatTimestamp)
            let selesaiMuatDate = Date(timeIntervalSince1970: data.selesaiMuatTimestamp)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let creationStringDate = dateFormatter.string(from: creationDate).replacingOccurrences(of: ",", with: " ")
            let mulaiMuatStringDate = dateFormatter.string(from: mulaiMuatDate).replacingOccurrences(of: ",", with: " ")
            let selesaiMuatStringDate = dateFormatter.string(from: selesaiMuatDate).replacingOccurrences(of: ",", with: " ")
            
            //Calculate Totals
            let panenTotals = PanenFunctions().calculateTotals(data: data)
            let averageBBString = "\(String(format: "%.2f", panenTotals.averageBB).replacingOccurrences(of: ",", with: " ")) KG"
            let nettoString = "\(String(format: "%.2f", panenTotals.netto).replacingOccurrences(of: ",", with: " "))"
            
            let totalRp = String(format: "%.0f", Float(data.hargaPerKG) * panenTotals.netto)
            
            csvText.append("\(data.namaPerusahaan),\(data.alamatPerusahaan),\(creationStringDate),\(mulaiMuatStringDate),\(selesaiMuatStringDate),\(data.status),\(data.jumlahKGDO),\(data.rangeBB),\(data.hargaPerKG),\(totalRp)\n")
            
            csvText.append(",,Waktu,Jumlah,Berat,Tara,Netto,Sekat,Lantai,Umur,isVoid,isSubtract\n")
            for i in 0..<data.berat.count {
                
                let addedDate = Date(timeIntervalSince1970: data.timestamps[i])
                let addedStringDate = dateFormatter.string(from: addedDate).replacingOccurrences(of: ",", with: " ")
                let beratString = String(format : "%.2f", data.berat[i]).replacingOccurrences(of: ",", with: " ")
                let taraString = String(format : "%.2f", data.tara[i]).replacingOccurrences(of: ",", with: " ")
                let netto = data.berat[i] - data.tara[i]
                let nettoString = String(format : "%.2f", netto).replacingOccurrences(of: ",", with: " ")
                
                //Calculate Age
                var currentFloorDetail : FarmFloorDetail!
                for floorDetail in floorDetails {
                    if floorDetail.floorNumber == data.lantai[i] {
                        currentFloorDetail = floorDetail
                    }
                }
                let startDate = Date(timeIntervalSince1970: currentFloorDetail.startTimestamp)
                let age : Int = Calendar.current.dateComponents([.day], from: startDate, to: addedDate).day!
                
                csvText.append(",,\(addedStringDate),\(data.jumlah[i]),\(beratString),\(taraString),\(nettoString),\(data.sekat[i]),\(data.lantai[i]),\(age),\(data.isVoided[i]),\(data.isSubtract[i])\n")
            }
            
            csvText.append(",,,,,,,,,,Total Ekor,\(panenTotals.totalEkor)\n")
            csvText.append(",,,,,,,,,,Total Netto,\(nettoString)\n")
            csvText.append(",,,,,,,,,,Average BB,\(averageBBString)\n")
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
    }
    
    func constructDetailedPanenCsv(dataArray: [Panen]) {
        print("constructDetailedPanenCsv")
        let fileName = "\(farmName.prefix(1).uppercased())\(cycleNumber)-Panen-Detailed.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        
        var csvText = ""
        for data in dataArray {
            csvText.append("Nama Perusahaan,Alamat Perusahaan,Tanggal Pembuatan,Mulai Muat,Selesai Muat,Status,KG DO,Range BB\n")
            //Create String Dates
            let creationDate = Date(timeIntervalSince1970: data.creationTimestamp)
            let mulaiMuatDate = Date(timeIntervalSince1970: data.mulaiMuatTimestamp)
            let selesaiMuatDate = Date(timeIntervalSince1970: data.selesaiMuatTimestamp)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let creationStringDate = dateFormatter.string(from: creationDate).replacingOccurrences(of: ",", with: " ")
            let mulaiMuatStringDate = dateFormatter.string(from: mulaiMuatDate).replacingOccurrences(of: ",", with: " ")
            let selesaiMuatStringDate = dateFormatter.string(from: selesaiMuatDate).replacingOccurrences(of: ",", with: " ")
            
            csvText.append("\(data.namaPerusahaan),\(data.alamatPerusahaan),\(creationStringDate),\(mulaiMuatStringDate),\(selesaiMuatStringDate),\(data.status),\(data.jumlahKGDO),\(data.rangeBB)\n")
            
            csvText.append("Waktu,Jumlah,Berat,Tara,Netto,Sekat,Lantai,isVoid,isSubtract\n")
            for i in 0..<data.berat.count {
                let addedDate = Date(timeIntervalSince1970: data.timestamps[i])
                let addedStringDate = dateFormatter.string(from: addedDate).replacingOccurrences(of: ",", with: " ")
                let beratString = String(format : "%.2f", data.berat[i]).replacingOccurrences(of: ",", with: " ")
                let taraString = String(format : "%.2f", data.tara[i]).replacingOccurrences(of: ",", with: " ")
                let netto = data.berat[i] - data.tara[i]
                let nettoString = String(format : "%.2f", netto).replacingOccurrences(of: ",", with: " ")
                csvText.append("\(addedStringDate),\(data.jumlah[i]),\(beratString),\(taraString),\(nettoString),\(data.sekat[i]),\(data.lantai[i]),\(data.isVoided[i]),\(data.isSubtract[i])\n")
            }
            
            //Calculate Totals
            let panenTotals = PanenFunctions().calculateTotals(data: data)
            let averageBBString = "\(String(format: "%.2f", panenTotals.averageBB).replacingOccurrences(of: ",", with: " ")) KG"
            let nettoString = "\(String(format: "%.2f", panenTotals.netto).replacingOccurrences(of: ",", with: " "))"
            csvText.append(",,,,,,,Total Ekor,\(panenTotals.totalEkor)\n")
            csvText.append(",,,,,,,Total Netto,\(nettoString)\n")
            csvText.append(",,,,,,,Average BB,\(averageBBString)\n")
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
    }
    
    func checkForFileExistance(data : Panen) {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent("\(farmName.prefix(1).uppercased())\(cycleNumber)-\(Int(data.creationTimestamp))SJ.pdf") {
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath) {
                print("SJ FILE AVAILABLE")
                resultSearchController.isActive = false
                self.filePath = filePath
                let previewController = QLPreviewController()
                previewController.dataSource = self
                present(previewController, animated: true)
            } else {
                print("SJ FILE NOT AVAILABLE")
                resultSearchController.isActive = false
                self.downloadFile(data: data)
            }
        } else {
            print("FILE PATH NOT AVAILABLE")
        }
    }
    
    func downloadFile(data : Panen) {
        if (self.resultSearchController.isActive) {
            self.resultSearchController.isActive = false
        }
        self.hud.detailTextLabel.text = "0% Complete"
        self.hud.textLabel.text = "Loading"
        self.hud.show(in: self.view)
        let storageRef = Storage.storage().reference()
        // Create a reference to the file we want to download
        let deliveryPermitRef = storageRef.child("\(farmName)\(cycleNumber)PanenSJ/\(data.id!).pdf")
        
        filePath = "\(documentsPath)/\(farmName.prefix(1).uppercased())\(cycleNumber)-\(Int(data.creationTimestamp))SJ.pdf"
        
        // Start the download (in this case writing to a file)
        let downloadTask = deliveryPermitRef.write(toFile: URL(fileURLWithPath: filePath))

        // Observe changes in status
        downloadTask.observe(.resume) { snapshot in
          // Download resumed, also fires when the download starts
        }

        downloadTask.observe(.pause) { snapshot in
          // Download paused
        }

        downloadTask.observe(.progress) { snapshot in
          // Download reported progress
          let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
            / Double(snapshot.progress!.totalUnitCount)
            print(percentComplete)
            if Float(percentComplete) == 100.0 {
                self.hud.textLabel.text = "Success"
                self.hud.detailTextLabel.text = "\(String(format: "%.1f",Float(percentComplete)))% Complete"
                self.hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                self.hud.dismiss(afterDelay: 1.0)
            }
            else {
                self.hud.detailTextLabel.text = "\(String(format: "%.1f",Float(percentComplete)))% Complete"
            }
        }

        downloadTask.observe(.success) { snapshot in
          // Download completed successfully
            self.hud.dismiss()
            let previewController = QLPreviewController()
            previewController.dataSource = self
            self.present(previewController, animated: true)
        }

        // Errors only occur in the "Failure" case
        downloadTask.observe(.failure) { snapshot in
            guard let errorCode = (snapshot.error as NSError?)?.code else {
            return
          }
          guard let error = StorageErrorCode(rawValue: errorCode) else {
            return
          }
          switch (error) {
          case .objectNotFound:
            // File doesn't exist
            self.hud.dismiss()
            print("File doesn't exist")
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "File doesn't exist", message: "File Could not be found in Server", preferredStyle: .alert)
            
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)
            break
          case .unauthorized:
            self.hud.dismiss()
            // User doesn't have permission to access file
            print("User doesn't have permission to access file")
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Permission Error", message: "User doesn't have permission to access file", preferredStyle: .alert)
            
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)
            break
          case .cancelled:
            self.hud.dismiss()
            // User cancelled the download
            print("User cancelled the download")
            break

          /* ... */

          case .unknown:
            self.hud.dismiss()
            // Unknown error occurred, inspect the server response
            print("Unknown error occurred, inspect the server responsed")
            break
          default:
            self.hud.dismiss()
            // Another error occurred. This is a good place to retry the download.
            break
          }
        }
    }
    
    //QLPreviewController Methods
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        if exportFlag ==  true {
            return csvPath as QLPreviewItem
        }
        else {
            return URL(fileURLWithPath: filePath) as QLPreviewItem
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PanenEditViewController {
            let vc = segue.destination as? PanenEditViewController
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.cycleNumber = cycleNumber
            vc?.numberOfFloors = numberOfFloors
            vc?.isEdit = isEdit
            vc?.panen = selectedData
        }
        else if segue.destination is PanenDeliveryOrderViewController {
            let vc = segue.destination as? PanenDeliveryOrderViewController
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.cycleNumber = cycleNumber
            vc?.panen = selectedData
        }
        else if segue.destination is PanenViewController {
            let vc = segue.destination as? PanenViewController
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.cycleNumber = cycleNumber
            vc?.numberOfFloors = numberOfFloors
            vc?.panen = selectedData
        }
        else if segue.destination is PanenInvoiceViewController {
            let vc = segue.destination as? PanenInvoiceViewController
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.cycleNumber = cycleNumber
            vc?.numberOfFloors = numberOfFloors
            vc?.panen = selectedData
        }
    }
}
extension Formatter {
    static let avoidNotation: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 8
        numberFormatter.numberStyle = .decimal
        return numberFormatter
    }()
}
extension FloatingPoint {
    var avoidNotation: String {
        return Formatter.avoidNotation.string(for: self) ?? ""
    }
}
