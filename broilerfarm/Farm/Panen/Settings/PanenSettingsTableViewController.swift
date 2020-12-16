//
//  PanenSettingsTableViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/21/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import NotificationBannerSwift

class PanenSettingsTableViewCell : UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var titleImageView: UIImageView!
}

class PanenSettingsTableViewController: UITableViewController, sendRekeningData {
    
    struct Setting {
        let title : String
        let image : UIImage
    }
    
    var settings : [Setting] = [Setting]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let rangeBB = Setting(title: "Range BB", image: UIImage(systemName: "chart.bar")!)
        let scaleBle = Setting(title: "Scale BLE", image: UIImage(systemName: "dot.radiowaves.left.and.right")!)
        let bank = Setting(title: "Bank", image: UIImage(systemName: "dollarsign.circle")!)
        settings = [rangeBB,scaleBle,bank]
        
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        // Remove seperator lines from empty cells
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    func rekeningDataReceived(rekening: [String]) {
        updateRekeningDocument(nama: rekening[0], bank: rekening[1], nomor: rekening[2])
    }
    
    func updateRekeningDocument(nama: String, bank: String, nomor: String) {
        let doc = Firestore.firestore().collection("panenSettings").document("rekening")
        doc.setData([
            "nama" : nama,
            "bank" : bank,
            "nomor" : nomor
        ]) { err in
            if let err = err {
                print("Error writing Range BB Document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error Writing Rekening Panen Document", style: .danger)
                banner.show()
            } else {
                print("Range BB Document successfully written!")
                let banner = StatusBarNotificationBanner(title: "Rekening Panen Successfully Updated!", style: .success)
                banner.show()
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        func createCell(data : Setting) -> PanenSettingsTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath) as! PanenSettingsTableViewCell
            
            cell.titleLabel.text = data.title
            cell.titleImageView.image = data.image
        
            return cell
        }
        return createCell(data: settings[indexPath.row])
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch settings[indexPath.row].title {
        case "Range BB":
            print("Range BB")
            self.performSegue(withIdentifier: "goToRangeBB", sender: self)
        case "Scale BLE":
            print("Scale BLE")
            self.performSegue(withIdentifier: "goToScaleBLEData", sender: self)
        case "Bank":
            print("Bank")
            self.performSegue(withIdentifier: "goToDataRekening", sender: self)
        default:
            print("Unknown Setting")
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         if segue.destination is DataRekeningTableViewController
         {
             let vc = segue.destination as? DataRekeningTableViewController
             vc?.isPick = true
             vc?.delegate = self
         }
    }
}
