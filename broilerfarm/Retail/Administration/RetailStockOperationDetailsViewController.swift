//
//  RetailStockOperationDetailsViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 5/26/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import JGProgressHUD

class RetailStockOperationDetailsViewController: UIViewController {
    
    var fullName : String = ""
    var loginClass : String = ""
    
    var selectedStockOperation : RetailStockOperation!
    
    @IBOutlet var productNameLabel: UILabel!
    @IBOutlet var addImageView: UIImageView!
    @IBOutlet var cancelledImageView: UIImageView!
    @IBOutlet var quantityUnitsLabel: UILabel!
    @IBOutlet var notesLabel: UILabel!
    @IBOutlet var createdByLabel: UILabel!
    @IBOutlet var operationImageView: UIImageView!
    
    var hud = JGProgressHUD(style: .dark)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set Labels
        productNameLabel.text = selectedStockOperation.productName
        quantityUnitsLabel.text = "Qty: \(selectedStockOperation.quantity) \(selectedStockOperation.unit)"
        notesLabel.text = "Notes: \(selectedStockOperation.notes)"
        
        let date = Date(timeIntervalSince1970: selectedStockOperation.timestamp )
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        let stringDate = dateFormatter.string(from: date)
        createdByLabel.text = "\(selectedStockOperation.createdBy) On \(stringDate)"
        
        //Set Image Views
        if selectedStockOperation.add {
            addImageView.image = UIImage(named: "import")
        }
        else {
            addImageView.image = UIImage(named: "export")
        }
        
        if selectedStockOperation.isCancelled {
            cancelledImageView.image = UIImage(named: "error")
        }
        else {
            cancelledImageView.image = UIImage(named: "success")
        }
        
        if selectedStockOperation.isAutomaticallyGenerated {
            operationImageView.image = UIImage(named: "redLogo")
        }
        else {
            downloadFile(imageRef: "RetailStockOperationImages/\(selectedStockOperation.document).jpeg")
        }
    }
    
    func downloadFile(imageRef : String) {
        self.hud.detailTextLabel.text = "0% Complete"
        self.hud.textLabel.text = "Loading"
        self.hud.show(in: self.view)
        let storageRef = Storage.storage().reference()
        // Create a reference to the file we want to download
        let imageRef = storageRef.child(imageRef)
        
        // Start the download (in this case writing to a file)
        let downloadTask = imageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
          if let error = error {
            // Uh-oh, an error occurred!
            print(error)
          } else {
            // Data for "images/island.jpg" is returned
            let image = UIImage(data: data!)
            self.operationImageView.image = image
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
}
