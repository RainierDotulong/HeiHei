//
//  StorageHistoryTableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 11/1/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import UIEmptyState
import Firebase
import FirebaseFirestore
import SVProgressHUD
import NotificationBannerSwift
import QuickLook

class StorageHistoryTableViewCell : UITableViewCell {
    @IBOutlet var namaBarangLabel: UILabel!
    @IBOutlet var jumlahSatuanLabel: UILabel!
    @IBOutlet var dateNameLabel: UILabel!
    @IBOutlet var floorLabel: UILabel!
    @IBOutlet var categoryImage: UIImageView!
    @IBOutlet var actionImage: UIImageView!
}

class StorageHistoryTableViewController: UITableViewController, UIEmptyStateDataSource, UIEmptyStateDelegate,QLPreviewControllerDataSource, UISearchResultsUpdating {
    
    var farmName : String = ""
    var fullName : String = ""
    var cycleNumber : Int  = 0
    var loginClass : String = ""
    //[timestamp, category, jumlah, namaBarang, reporterName, satuan, action]
    var storageDataArray : [[String]] = [[String]]()
    var filteredStorageDataArray : [[String]] = [[String]]()
    var titleDataArray : [String] = [String]()
    
    var selectedDocumentId : String = ""
    var selectedCategory : String = ""
    var selectedJumlah : String = ""
    var selectedNamaBarang : String = ""
    var selectedReporterName : String = ""
    var selectedSatuan : String = ""
    var selectedAction : String = ""
    var selectedNomorSuratJalan : String = ""
        
    var resultSearchController = UISearchController()
    
    var csvPath : URL = URL(string: "https://www.globalxtreme.net")!
    
    @IBOutlet var exportButton: UIBarButtonItem!
    //UI Empty State Variables
    var emptyStateTitle: NSAttributedString {
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor(red: 0.882, green: 0.890, blue: 0.859, alpha: 1.00),
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22)]
        return NSAttributedString(string: "No Storage History Found!", attributes: attrs)
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
        
        //SearchBar
        resultSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.obscuresBackgroundDuringPresentation = false
            controller.searchBar.sizeToFit()

            tableView.tableHeaderView = controller.searchBar

            return controller
        })()
        
        // Reload the table
        tableView.reloadData()
        self.reloadEmptyState()
        
        if loginClass == "superadmin" || loginClass == "administrator" {
            exportButton.isEnabled = true
        }
        else {
            exportButton.isEnabled = false
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getStorageDataFromServer(collection: "\(farmName)\(cycleNumber)Storage")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    @IBAction func exportButtonPressed(_ sender: Any) {
        guard loginClass == "superadmin" || loginClass == "administrator" else {
            print("Export")
            return
        }
        let fileName = "\(farmName.uppercased()) \(cycleNumber)-Storage.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        var csvText = "Tanggal,Nama Barang,Category,Jumlah,Satuan,Action,Lantai/SJ,Harga Per Satuan,Total,Pelapor\n"
        
        let count = storageDataArray.count
        
        if count > 0 {
            var storageExports : [Int] = [Int]()
            for i in 1...storageDataArray.count {
                let documentId = storageDataArray[i-1][0].components(separatedBy: "-")
                let date = Date(timeIntervalSince1970: TimeInterval(Double(documentId[1])!))
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short
                let stringDate = dateFormatter.string(from: date)
                //print(storageDataArray[i-1][0])
                let total = Int(storageDataArray[i-1][8])! * Int(storageDataArray[i-1][2])!
                let newLine = "\(stringDate.replacingOccurrences(of: ",", with: "")),\(documentId[0]),\(storageDataArray[i-1][1]),\(storageDataArray[i-1][2]),\(storageDataArray[i-1][5]),\(storageDataArray[i-1][6]),\(storageDataArray[i-1][7]),\(storageDataArray[i-1][8]),\(total),\(storageDataArray[i-1][4])\n"

                csvText.append(newLine)
                if storageDataArray[i-1][6] == "Storage Export" {
                    storageExports.append(total)
                }
            }
            let totalStorageExports = storageExports.reduce(0, +)
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            let formattedTotal = numberFormatter.string(from: NSNumber(value:totalStorageExports))
            csvText.append(",,,,,,,,Total Pengeluaran,Rp.\(formattedTotal!.replacingOccurrences(of: ",", with: "."))")
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
            
        } else {
            print("There is no data to export")
        }
    }
    
    func getStorageDataFromServer(collection : String) {
        exportButton.isEnabled = false
        SVProgressHUD.show()
        let db = Firestore.firestore()
        db.collection("\(farmName)\(cycleNumber)Storage").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                self.exportButton.isEnabled = true
                SVProgressHUD.dismiss()
            } else {
                self.storageDataArray.removeAll(keepingCapacity: false)
                self.titleDataArray.removeAll(keepingCapacity: false)
                for document in querySnapshot!.documents {
                    var subArray = [String]()
                    //Create unique title Array
                    if self.titleDataArray.contains(document.data()["namaBarang"] as! String) == false {
                        self.titleDataArray.append(document.data()["namaBarang"] as! String)
                    }
                    subArray.append(document.documentID)
                    subArray.append(document.data()["category"] as! String)
                    subArray.append(document.data()["jumlah"] as! String)
                    subArray.append(document.data()["namaBarang"] as! String)
                    subArray.append(document.data()["reporterName"] as! String)
                    subArray.append(document.data()["satuan"] as! String)
                    subArray.append(document.data()["action"] as! String)
                    subArray.append(document.data()["nomorSuratJalan"] as! String)
                    subArray.append(document.data()["pricePerUnit"] as? String ?? "0")
                    self.storageDataArray.append(subArray)
                }
                self.exportButton.isEnabled = true
                SVProgressHUD.dismiss()
                self.tableView.reloadData()
                self.reloadEmptyState()
            }
        }
    }
    
    func deleteEntry(collection: String, dataArray : [String], indexPath : Int) {
        let db = Firestore.firestore()
        db.collection(collection).document(dataArray[0]).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error removing document", style: .danger)
                banner.show()
            } else {
                print("Document successfully removed!")
                self.getStorageDataFromServer(collection : collection)
                let banner = StatusBarNotificationBanner(title: "Document successfully removed!", style: .success)
                banner.show()
            }
            if self.resultSearchController.isActive {
                self.resultSearchController.isActive = false
            }
        }
        tableView.reloadData()
        self.reloadEmptyState()
    }
    
    // Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if  (resultSearchController.isActive) {
            return filteredStorageDataArray.count
        }
        else {
            return storageDataArray.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.rowHeight = UITableView.automaticDimension
        
        func createCells(dataArray : [String]) -> StorageHistoryTableViewCell {
            //Format Date from timestamp
            let documentIdArray = dataArray[0].components(separatedBy: "-")
            let date = Date(timeIntervalSince1970: TimeInterval(Double(documentIdArray[1])!))
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: date)
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "StorageHistoryCell", for: indexPath) as! StorageHistoryTableViewCell
            
            cell.namaBarangLabel.text = dataArray[3]
            cell.jumlahSatuanLabel.text = dataArray[2] + " " + dataArray[5]
            cell.dateNameLabel.text = stringDate + " by " + dataArray[4]
            cell.floorLabel.text = dataArray[7]
            
            if dataArray[6] == "Storage Import" {
                cell.actionImage.image = UIImage(named: "import")
            }
            else {
                cell.actionImage.image = UIImage(named: "export")
            }
            
            cell.categoryImage.image = UIImage(named: CategoryToImage(category: dataArray[1]))
            
            return cell
        }
        
        if (resultSearchController.isActive) {
            return createCells(dataArray: filteredStorageDataArray[self.filteredStorageDataArray.count - indexPath.row - 1])
        }
        else {
            return createCells(dataArray: storageDataArray[self.storageDataArray.count - indexPath.row - 1])
        }
    }
    
    //Add Table Cell Button Actions
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let delete = UIContextualAction(style: .normal, title: "Delete") {  (contextualAction, view, boolValue) in
            if  (self.resultSearchController.isActive) {
                print("Delete " + self.filteredStorageDataArray[self.filteredStorageDataArray.count - indexPath.row - 1][0])
                self.deleteEntry(collection: "\(self.farmName)\(self.cycleNumber)Storage", dataArray: self.filteredStorageDataArray[self.filteredStorageDataArray.count - indexPath.row - 1], indexPath : indexPath.row)
            }
            else {
                print("Delete " + self.storageDataArray[self.storageDataArray.count - indexPath.row - 1][0])
                self.deleteEntry(collection: "\(self.farmName)\(self.cycleNumber)Storage", dataArray: self.storageDataArray[self.storageDataArray.count - indexPath.row - 1], indexPath : indexPath.row)
            }
        }
        delete.image = UIImage(systemName: "trash")
        delete.backgroundColor = .systemRed
        
        let edit = UIContextualAction(style: .normal, title: "Edit") {  (contextualAction, view, boolValue) in
            
            func assignSelectedEdit(dataArray : [String]) {
                print("Edit " + dataArray[0])
                self.selectedDocumentId = dataArray[0]
                self.selectedCategory = dataArray[1]
                self.selectedJumlah = dataArray[2]
                self.selectedNamaBarang  = dataArray[3]
                self.selectedReporterName = dataArray[4]
                self.selectedSatuan = dataArray[5]
                self.selectedAction = dataArray[6]
                self.selectedNomorSuratJalan = dataArray[7]
                if self.resultSearchController.isActive {
                    self.resultSearchController.isActive = false
                }
                self.performSegue(withIdentifier: "goToStorageHistoryEdit", sender: self)
            }
            
            if (self.resultSearchController.isActive) {
                assignSelectedEdit(dataArray: self.filteredStorageDataArray[self.filteredStorageDataArray.count - indexPath.row - 1])
            }
            else {
                assignSelectedEdit(dataArray: self.storageDataArray[self.storageDataArray.count - indexPath.row - 1])
            }
        }
        edit.image = UIImage(systemName: "square.and.pencil")
        edit.backgroundColor = .systemBlue
        
        if loginClass == "administrator" || loginClass == "superadmin" {
            let swipeActions = UISwipeActionsConfiguration(actions: [edit, delete])
            return swipeActions
        }
        else {
            return nil
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredStorageDataArray.removeAll(keepingCapacity: false)

        let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchController.searchBar.text!)
        let array = (titleDataArray as NSArray).filtered(using: searchPredicate)
        let filteredTitleDataArray = array as! [String]
        //construct Filtered Data Array
        print(filteredTitleDataArray)
        for data in storageDataArray {
            for name in filteredTitleDataArray {
                if data[3] == name {
                    filteredStorageDataArray.append(data)
                }
            }
        }
        self.tableView.reloadData()
        self.reloadEmptyState()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        func assignSelected(dataArray : [String]) {
            selectedDocumentId = dataArray[0]
            selectedCategory = dataArray[1]
            selectedJumlah = dataArray[2]
            selectedNamaBarang  = dataArray[3]
            selectedReporterName = dataArray[4]
            selectedSatuan = dataArray[5]
            selectedAction = dataArray[6]
            selectedNomorSuratJalan = dataArray[7]
            if resultSearchController.isActive {
                resultSearchController.isActive = false
            }
            if selectedAction == "Storage Import" {
                self.performSegue(withIdentifier: "goToHistoryDetails", sender: self)
            }
            else {
                let documentIdArray = selectedDocumentId.components(separatedBy: "-")
                let date = Date(timeIntervalSince1970: TimeInterval(Double(documentIdArray[1])!))
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short
                let stringDate = dateFormatter.string(from: date)
                
                let message = selectedNamaBarang + "\n" + "Tanggal: " +  stringDate + "\n" + "Category: " + selectedCategory + "\n" + "Jumlah: " + selectedJumlah + " " + selectedSatuan + "\n" + "Nomor Surat: " + selectedNomorSuratJalan
                //Declare Alert message
                let dialogMessage = UIAlertController(title: "Storage Export", message: message, preferredStyle: .alert)
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
        
        if (resultSearchController.isActive) {
            assignSelected(dataArray: self.filteredStorageDataArray[self.filteredStorageDataArray.count - indexPath.row - 1])
        }
        else {
            assignSelected(dataArray: self.storageDataArray[self.storageDataArray.count - indexPath.row - 1])
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    //QLPreviewController Methods
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return csvPath as QLPreviewItem
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is StorageHistoryDetailsViewController
        {
            let vc = segue.destination as? StorageHistoryDetailsViewController
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.cycleNumber = cycleNumber
            vc?.selectedDocumentId = selectedDocumentId
            vc?.selectedCategory = selectedCategory
            vc?.selectedJumlah = selectedJumlah
            vc?.selectedNamaBarang = selectedNamaBarang
            vc?.selectedReporterName = selectedReporterName
            vc?.selectedSatuan = selectedSatuan
            vc?.selectedAction = selectedAction
            vc?.selectedNomorSuratJalan = selectedNomorSuratJalan
        }
        else if segue.destination is StorageHistoryEditViewController
        {
            let vc = segue.destination as? StorageHistoryEditViewController
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.cycleNumber = cycleNumber
            vc?.selectedDocumentId = selectedDocumentId
            vc?.selectedCategory = selectedCategory
            vc?.selectedJumlah = selectedJumlah
            vc?.selectedNamaBarang = selectedNamaBarang
            vc?.selectedReporterName = selectedReporterName
            vc?.selectedSatuan = selectedSatuan
            vc?.selectedAction = selectedAction
            vc?.selectedNomorSuratJalan = selectedNomorSuratJalan
        }
    }
}
