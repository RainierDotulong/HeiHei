//
//  StorageHistoryDetailsViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 11/1/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import SVProgressHUD
import Firebase
import FirebaseStorage

class StorageHistoryDetailsViewController: UIViewController {
    
    var farmName : String = ""
    var fullName : String = ""
    var cycleNumber : Int  = 0
    var selectedDocumentId : String = ""
    var selectedCategory : String = ""
    var selectedJumlah : String = ""
    var selectedNamaBarang : String = ""
    var selectedReporterName : String = ""
    var selectedSatuan : String = ""
    var selectedAction : String = ""
    var selectedNomorSuratJalan : String = ""
    
    @IBOutlet var farmCycleLabel: UILabel!
    @IBOutlet var namaBarangLabel: UILabel!
    @IBOutlet var jumlahSatuanLabel: UILabel!
    @IBOutlet var dateReporterLabel: UILabel!
    @IBOutlet var actionLabel: UILabel!
    @IBOutlet var imageView: UIImageView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        let documentIdArray = selectedDocumentId.components(separatedBy: "-")
        //Format Date from timestamp
        let date = Date(timeIntervalSince1970: TimeInterval(Double(documentIdArray[1])!))
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        let stringDate = dateFormatter.string(from: date)
        
        if farmName == "Main" {
            farmCycleLabel.text = "Main Storage"
        }
        else {
            farmCycleLabel.text = "\(farmName.uppercased()) - \(cycleNumber)"
        }
        namaBarangLabel.text = selectedNamaBarang
        jumlahSatuanLabel.text = selectedJumlah + " " + selectedSatuan + "-" + selectedNomorSuratJalan
        dateReporterLabel.text = stringDate + " by " + selectedReporterName
        actionLabel.text = "Action: " + selectedAction
        
        if selectedAction == "Storage Import" || selectedAction == "Main Storage Import" {
            downloadFile()
        }
        else {
            imageView.image = UIImage(named: "redLogo")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }

    func downloadFile() {
        SVProgressHUD.show()
        let storageRef = Storage.storage().reference()
        // Create a reference to the file we want to download
        let imageRef = storageRef.child("\(farmName)\(cycleNumber)StorageImportImages/" + selectedNomorSuratJalan + ".jpeg")

        // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
        let downloadTask = imageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
          if let error = error {
            // Uh-oh, an error occurred!
            print(error)
          } else {
            // Data for "images/island.jpg" is returned
            let image = UIImage(data: data!)
            self.imageView.image = image
          }
        }

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
            SVProgressHUD.showProgress(Float(percentComplete))
        }

        downloadTask.observe(.success) { snapshot in
          // Download completed successfully
            SVProgressHUD.dismiss()
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
            SVProgressHUD.dismiss()
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
            SVProgressHUD.dismiss()
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
            SVProgressHUD.dismiss()
            // User cancelled the download
            print("User cancelled the download")
            break

          /* ... */

          case .unknown:
            SVProgressHUD.dismiss()
            // Unknown error occurred, inspect the server response
            print("Unknown error occurred, inspect the server responsed")
            break
          default:
            SVProgressHUD.dismiss()
            // Another error occurred. This is a good place to retry the download.
            break
          }
        }
    }
}
