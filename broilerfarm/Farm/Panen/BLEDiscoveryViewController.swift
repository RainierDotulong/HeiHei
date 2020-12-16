//
//  BLEDiscoveryViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/26/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import MobileCoreServices
import CoreData
import CoreBluetooth
import Firebase
import FirebaseFirestore
import SVProgressHUD
import NotificationBannerSwift
import UIEmptyState

class BLETableViewCell : UITableViewCell {
    @IBOutlet var bleNameLabel: UILabel!
}

protocol sendBleData {
    func bleDataReceived(ble : CBPeripheral)
}

class BLEDiscoveryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIEmptyStateDataSource, UIEmptyStateDelegate {
    
    var centralManager: CBCentralManager!
    var discoveredPeripherals : [CBPeripheral] = [CBPeripheral]()
    
    var delegate : sendBleData?

    @IBOutlet var bleStatusLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    
    var knownBleDataArray : [String] = [String]()
    
    //UI Empty State Variables
    var emptyStateTitle: NSAttributedString {
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor(red: 0.882, green: 0.890, blue: 0.859, alpha: 1.00),
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22)]
        return NSAttributedString(string: "No BLE Devices Found", attributes: attrs)
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
        
        getBleDataFromServer()
        
        self.tableView.reloadData()
        self.reloadEmptyStateForTableView(tableView)
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        print("Back")
        centralManager.stopScan()
        self.navigationController?.popViewController(animated: true)
    }
    
    func getBleDataFromServer() {
        SVProgressHUD.show()
        Firestore.firestore().collection("scaleBle").addSnapshotListener { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
              print("No documents")
              SVProgressHUD.dismiss()
              return
            }
            self.knownBleDataArray.removeAll(keepingCapacity: false)
            let bleDataArray = documents.compactMap { queryDocumentSnapshot -> scaleBle? in
              return try? queryDocumentSnapshot.data(as: scaleBle.self)
            }
            for bleData in bleDataArray {
                self.knownBleDataArray.append(bleData.name)
            }
            self.centralManager = CBCentralManager(delegate: self, queue: nil)
            SVProgressHUD.dismiss()
            self.tableView.reloadData()
        }
    }
    
    //MARK: Table View Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredPeripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        func createCell(data : CBPeripheral) -> BLETableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "bleCell", for: indexPath) as! BLETableViewCell
            
            cell.bleNameLabel.text = data.name
        
            return cell
        }
        return createCell(data: discoveredPeripherals[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        centralManager.stopScan()
        bleStatusLabel.text = "Peripheral Selected."
        self.delegate?.bleDataReceived(ble: discoveredPeripherals[indexPath.row])
        self.navigationController?.popViewController(animated: true)
    }
}

extension BLEDiscoveryViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
        case .poweredOn:
            print("central.state is .poweredOn")
            centralManager.scanForPeripherals(withServices: nil)
            bleStatusLabel.text = "Scanning for peripherals..."
        default :
            print("central.state is .uncategorized")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                      advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral)
        guard knownBleDataArray.contains(peripheral.name?.replacingOccurrences(of: "\r\n", with: "") ?? "NULL") else {
            print("Peripheral not registered")
            return
        }
        if discoveredPeripherals.contains(peripheral) == false && peripheral.name?.isEmpty == false {
            discoveredPeripherals.append(peripheral)
            self.tableView.reloadData()
            self.reloadEmptyStateForTableView(tableView)
        }
    }
}
