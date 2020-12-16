//
//  PerusahaanTableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/15/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import NotificationBannerSwift
import SVProgressHUD
import EmptyStateKit
import QuickLook

class PerusahaanTableViewCell : UITableViewCell {
    //perusahaanCell
    @IBOutlet var categoryImageView: UIImageView!
    @IBOutlet var perusahaanLabel: UILabel!
    @IBOutlet var alamatLabel: UILabel!
    @IBOutlet var contactLabel: UILabel!
}

protocol sendPerusahaanData {
    func perusahaanDataReceived(selectedPerusahaan : Perusahaan)
}

class PerusahaanTableViewController: UITableViewController, UISearchResultsUpdating, EmptyStateDelegate, QLPreviewControllerDataSource {
    
    var delegate : sendPerusahaanData?
    
    var fullName : String = ""
    var loginClass : String = ""
    var farmName : String = ""
    var cycleNumber : Int = 0
    
    var dataArray : [Perusahaan] = [Perusahaan]()
    var filteredDataArray : [Perusahaan] = [Perusahaan]()
    
    var selectedData : Perusahaan = Perusahaan(id: "", timestamp: 99999, companyName: "", companyAddress: "", companyType: "", contactName: "", contactPhone: "", createdBy: "  ")
    
    var nameArray : [String] = [String]()
    
    var resultSearchController = UISearchController()
    
    @IBOutlet var addBarButton: UIBarButtonItem!
    
    var isPick : Bool = false
    var isEdit : Bool = false
    
    //Migration
    struct oldData {
        var companyName : String
        var companyAddress : String
        var companyType : String
        var contact : String
        var phoneNumber : String
    }
    
    var oldDataArray : [oldData] = [oldData]()
    
    //Balance Sheet
    var pembayaranData : [Pembayaran] = [Pembayaran]()
    var panenData : [Panen] = [Panen]()
    
    var csvPath : URL = URL(string: "https://www.globalxtreme.net")!

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
        
        let PerusahaanChangeNotification = Notification.Name("perusahaanChanged")
        NotificationCenter.default.addObserver(self, selector: #selector(perusahaanChanged(_:)), name: PerusahaanChangeNotification, object: nil)
        
        getDataFromServer(pullDownRefresh: false)
        
        //Old companyList Collection Data Migration
        //migrate()
        
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    @objc func refresh() {
        print("Refresh")
        getDataFromServer(pullDownRefresh : true)
    }
       
    @objc func perusahaanChanged(_ notification:Notification) {
        print("Perusahaan Changed")
        getDataFromServer(pullDownRefresh : false)
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
        let array = (nameArray as NSArray).filtered(using: searchPredicate)
        let filteredNameArray = array as! [String]
        //construct Filtered Data Array
        for perusahaan in dataArray {
            for name in filteredNameArray {
                
                if perusahaan.companyName == name {
                    filteredDataArray.append(perusahaan)
                }
            }
        }
        self.tableView.reloadData()
        self.reloadEmptyStateKit(state: "noSearch")
    }
    
    @IBAction func addBarButtonPressed(_ sender: Any) {
        print("Add")
        isEdit = false
        self.performSegue(withIdentifier: "goToPerusahaan", sender: self)
    }
    
    func getDataFromServer(pullDownRefresh : Bool) {
        if pullDownRefresh == false {
            SVProgressHUD.show()
        }
        Firestore.firestore().collection("dataPerusahaan").order(by: "companyName").addSnapshotListener { (querySnapshot, error) in
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
            
            self.dataArray = documents.compactMap { queryDocumentSnapshot -> Perusahaan? in
              return try? queryDocumentSnapshot.data(as: Perusahaan.self)
            }
            
            self.nameArray.removeAll(keepingCapacity: false)
            for data in self.dataArray {
                let name = data.companyName
                self.nameArray.append(name)
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
    
    // MARK: Migration
    func migrate() {
        print("Migrate")
        SVProgressHUD.show()
        let db = Firestore.firestore()
        db.collection("companyList").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error getting documents", style: .danger)
                banner.show()
                SVProgressHUD.dismiss()
            } else {
                for document in querySnapshot!.documents {
                    let data : oldData = oldData(companyName: document.documentID,
                                                 companyAddress: document.data()["companyAddress"] as? String ?? "",
                                                 companyType: document.data()["companyType"] as? String ?? "",
                                                 contact: document.data()["contact"] as? String ?? "",
                                                 phoneNumber: document.data()["phoneNumber"] as? String ?? "")
                    
                    self.oldDataArray.append(data)
                }
                for data in self.oldDataArray {
                    let isCreateSuccess = Perusahaan.create(timestamp: Date().timeIntervalSince1970, companyName: data.companyName, companyAddress: data.companyAddress, companyType: data.companyType, contactName: data.contact, contactPhone: data.phoneNumber, createdBy: self.fullName)
                    
                    if isCreateSuccess {
                        print("Successfully Migrated")
                    }
                    else {
                        print("Error Migrating \(data.companyName)")
                    }
                }
            }
        }
        SVProgressHUD.dismiss()
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
    
    func createBalanceSheet(perusahaan: Perusahaan) {
        //Get Pembayaran Data
        Firestore.firestore().collection("\(farmName)\(cycleNumber)Pembayaran").order(by: "creationTimestamp").addSnapshotListener { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
              print("No pembayaran documents")
              return
            }
            
            self.pembayaranData = documents.compactMap { queryDocumentSnapshot -> Pembayaran? in
              return try? queryDocumentSnapshot.data(as: Pembayaran.self)
            }
        }
        //Get Panen Data
        Firestore.firestore().collection("\(farmName)\(cycleNumber)Panen").order(by: "creationTimestamp").addSnapshotListener { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
              print("No panen documents")
              return
            }
            
            self.panenData = documents.compactMap { queryDocumentSnapshot -> Panen? in
              return try? queryDocumentSnapshot.data(as: Panen.self)
            }
        }
        var selectedPembayaranData : [Pembayaran] = [Pembayaran]()
        var selectedPanenData : [Panen] = [Panen]()
        for pembayaran in pembayaranData {
            if perusahaan.companyName == pembayaran.perusahaanName {
                selectedPembayaranData.append(pembayaran)
            }
        }
        for panen in panenData {
            if perusahaan.companyName == panen.namaPerusahaan {
                selectedPanenData.append(panen)
            }
        }
        guard selectedPembayaranData.count > 0 || selectedPanenData.count > 0 else {
            print("No Data")
            return
        }
        createBalanceCsv(perusahaan: perusahaan, dataPembayaran: selectedPembayaranData, dataPanen: selectedPanenData)
    }
    
    func createBalanceCsv(perusahaan: Perusahaan, dataPembayaran: [Pembayaran], dataPanen: [Panen]) {
        let fileName = "\(perusahaan.companyName)-\(farmName.prefix(1).uppercased())\(cycleNumber)Balance.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        var csvText = "Perusahaan,\(perusahaan.companyName)\n"
        csvText.append("Alamat,\(perusahaan.companyAddress)\n")
        csvText.append("Kontak,\(perusahaan.contactName),\(perusahaan.contactPhone)\n")
        csvText.append(",\n")
        csvText.append("Pembayaran\n")
        csvText.append("Tanggal,Nominal,Rekening Tujuan\n")
        var paymentTotals : [Int] = [Int]()
        var refundTotals : [Int] = [Int]()
        for pembayaran in dataPembayaran {
            if pembayaran.isAcc {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short
                let pembayaranDate = Date(timeIntervalSince1970: pembayaran.creationTimestamp)
                let pembayaranDateString = dateFormatter.string(from: pembayaranDate).replacingOccurrences(of: ",", with: " ")
                if pembayaran.isRefunded == false {
                    paymentTotals.append(pembayaran.nominal)
                    csvText.append("\(pembayaranDateString),\(pembayaran.nominal),\(pembayaran.rekeningName)\n")
                }
                else {
                    refundTotals.append(pembayaran.nominal)
                    csvText.append("\(pembayaranDateString),(\(pembayaran.nominal)),\(pembayaran.rekeningName)\n")
                }
            }
        }
        csvText.append(",\n")
        csvText.append("Panen\n")
        csvText.append("Nomor,Mulai Muat,Selesai Muat,KG DO,Total Ekor,Total KG,Harga Per KG,Subtotal\n")
        var subtotals : [Float] = [Float]()
        for panen in dataPanen {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let mulaiMuatDate = Date(timeIntervalSince1970: panen.mulaiMuatTimestamp)
            let mulaiMuatDateString = dateFormatter.string(from: mulaiMuatDate).replacingOccurrences(of: ",", with: " ")
            let selesaiMuatDate = Date(timeIntervalSince1970: panen.selesaiMuatTimestamp)
            let selesaiMuatDateString = dateFormatter.string(from: selesaiMuatDate).replacingOccurrences(of: ",", with: " ")
            let nomorDo = "\(farmName.prefix(1).uppercased())\(cycleNumber)-\(Int(panen.creationTimestamp))"
            let panenTotals = PanenFunctions().calculateTotals(data: panen)
            let subtotal = String(format:"%.0f", Float(panen.hargaPerKG) * panenTotals.netto)
            csvText.append("\(nomorDo),\(mulaiMuatDateString),\(selesaiMuatDateString),\(panen.jumlahKGDO),\(panenTotals.totalEkor),\(panenTotals.netto),\(panen.hargaPerKG),\(subtotal)\n")
            subtotals.append(Float(panen.hargaPerKG) * panenTotals.netto)
        }
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let totalPembayaran = paymentTotals.reduce(0,+) - refundTotals.reduce(0,+)
        let formattedTotalPembayaran = numberFormatter.string(from: NSNumber(value:totalPembayaran))!.replacingOccurrences(of: ",", with: ".")
        csvText.append(",,,,,,Total Pembayaran,Rp. \(formattedTotalPembayaran)\n")
        let totalPanen = subtotals.reduce(0,+)
        let formattedTotalPanen = numberFormatter.string(from: NSNumber(value:Int(totalPanen)))!.replacingOccurrences(of: ",", with: ".")
        csvText.append(",,,,,,Total Panen,Rp. \(formattedTotalPanen)\n")
        let balance = totalPembayaran - Int(totalPanen)
        let formattedBalance = numberFormatter.string(from: NSNumber(value:Int(balance)))!.replacingOccurrences(of: ",", with: ".")
        csvText.append(",,,,,,Balance,Rp. \(formattedBalance)\n")
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
        
        func createCell(data : Perusahaan) -> PerusahaanTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "perusahaanCell", for: indexPath) as! PerusahaanTableViewCell
            
            cell.perusahaanLabel.text = data.companyName
            cell.alamatLabel.text = data.companyAddress
            cell.contactLabel.text = "\(data.contactName) (\(data.contactPhone))"
            cell.categoryImageView.image = UIImage(named: data.companyType.lowercased())
        
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
        isEdit = true
        if (resultSearchController.isActive) {
            selectedData = filteredDataArray[indexPath.row]
            resultSearchController.isActive = false
        }
        else {
            selectedData = dataArray[indexPath.row]
        }
        
        if isPick {
            if (resultSearchController.isActive) {
                resultSearchController.isActive = false
            }
            print("Company Picked")
            delegate?.perusahaanDataReceived(selectedPerusahaan : selectedData)
            navigationController?.popViewController(animated: true)
        }
        else {
            self.performSegue(withIdentifier: "goToPerusahaan", sender: self)
        }
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let balance = UIContextualAction(style: .normal, title: "Balance") { [self]  (contextualAction, view, boolValue) in
            
            if (self.resultSearchController.isActive) {
                print("Balance \(filteredDataArray[indexPath.row].companyName)")
                self.createBalanceSheet(perusahaan: filteredDataArray[indexPath.row])
                //self.resultSearchController.isActive = false
            }
            else {
                print("Balance \(self.dataArray[indexPath.row].companyName)")
                self.createBalanceSheet(perusahaan: self.dataArray[indexPath.row])
            }
        }
        
        balance.backgroundColor = .systemGreen
        balance.image = UIImage(systemName: "doc.fill")
        
        let swipeActions = UISwipeActionsConfiguration(actions: [balance])

        return swipeActions
    }
    
    //QLPreviewController Methods
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return csvPath as QLPreviewItem
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PerusahaanEditViewController {
            let vc = segue.destination as? PerusahaanEditViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.selectedData = selectedData
            vc?.isEdit = isEdit
        }
    }
}
