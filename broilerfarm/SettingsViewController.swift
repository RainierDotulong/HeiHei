//
//  SettingsViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 9/9/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import SVProgressHUD
import CoreData
import Reachability
import NotificationBannerSwift

protocol sendToHomepageViewController {
    func dataReceivedSettingsViewController(farmName : String, cycleNumber: Int, numberOfFloors: Int, hargaPerKwh: Float)
}

class SettingsViewController : UIViewController {
    
    var delegate : sendToHomepageViewController?
    
    var farmName : String = ""
    var fullName : String = ""
    var loginClass : String = ""
    var email : String = ""
    var cycleNumber : Int = 0
    var numberOfFloors : Int = 0
    var hargaPerKwh : Float = 0
    
    var farmData : [String] = [String]()
    var selectedFarmName : String = ""
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let request : NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
    
    var loadedUserData = [UserProfile]()
    
    var exportFlag : Bool  = false
    
    @IBOutlet var navItem: UINavigationItem!
    
    override func viewDidLoad() {
        
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        navItem.title = "Farm: " + farmName.uppercased()
        
        //Set default selected to be current farm
        selectedFarmName = farmName
        
        // Add reachability observer
        if let reachability = AppDelegate.sharedAppDelegate()?.reachability
        {
            NotificationCenter.default.addObserver( self, selector: #selector( self.reachabilityChanged ),name: Notification.Name.reachabilityChanged, object: reachability )
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
    
    @IBAction func pinantikButtonTapped(_ sender: Any) {
        selectedFarmName = "pinantik"
        navItem.title = "Farm: " + selectedFarmName.uppercased()
        print("Farm: " + selectedFarmName)
        selectFarm()
    }
    @IBAction func kejayanButtonTapped(_ sender: Any) {
        selectedFarmName = "kejayan"
        navItem.title = "Farm: " + selectedFarmName.uppercased()
        print("Farm: " + selectedFarmName)
        selectFarm()
    }
    @IBAction func lewihButtonTapped(_ sender: Any) {
        selectedFarmName = "lewih"
        navItem.title = "Farm: " + selectedFarmName.uppercased()
        print("Farm: " + selectedFarmName)
        selectFarm()
    }
    
    func selectFarm() {
        print("BACK BUTTON PRESSED")
        if selectedFarmName != farmName {
            farmName = selectedFarmName
            updateFirebaseUserProfile()
        }
        else {
            farmName = selectedFarmName
            updateFirebaseUserProfile()
        }
    }
    
    func updateFirebaseUserProfile(){
        SVProgressHUD.show()
        let usersProf = Firestore.firestore().collection("userProfiles").document(self.email)
        usersProf.updateData([
            "fullName": fullName,
            "class": loginClass,
            "farmName": farmName,
        ]) { err in
            if let err = err {
                print("Error writing document: \(err)")
                SVProgressHUD.dismiss()
            } else {
                print("Document successfully written!")
                self.selectCycle()
            }
        }
    }
    func selectCycle() {
        exportFlag = true
        
        let dialogMessage = UIAlertController(title: "Export Data Panen", message: "Select Export Type", preferredStyle: .alert)
        
        let previousCycle = UIAlertAction(title: "Previous Cycle", style: .default, handler: { (action) -> Void in
            print("Previous Cycle button tapped")
            if self.loginClass == "administrator" ||  self.loginClass == "superadmin" {
                self.getPreviousCycleNumber()
            }
            else {
                print("Not admin")
            }
        })
        let currentCycle = UIAlertAction(title: "Current Cycle", style: .default, handler: { (action) -> Void in
            print("Current Cycle Button Tapped")
            if self.loginClass == "administrator" ||  self.loginClass == "superadmin" {
                self.getCycleNumber()
            }
            else {
                print("NOt Admin")
            }
        })
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: { (action) -> Void in
            print("Cancel button tapped")
        })
        
        dialogMessage.addAction(previousCycle)
        dialogMessage.addAction(currentCycle)
        dialogMessage.addAction(cancel)
        
        self.present(dialogMessage, animated: true, completion: nil)
    }
    func getPreviousCycleNumber() {
        SVProgressHUD.show()
        //Get Cycle Number from Firebase
        let cycle = Firestore.firestore().collection(self.farmName + "Details").document("farmDetail")
        
        cycle.getDocument { (document, error) in
            if let document = document, document.exists {
                let dataDescription = document.data()
                self.cycleNumber = dataDescription!["currentCycleNumber"] as! Int - 1
                self.numberOfFloors = dataDescription!["numberOfFloors"] as! Int
                self.hargaPerKwh = dataDescription!["hargaPerKwh"] as! Float
                self.updateCoreDataUserProfile()
                
            } else {
                print("Current Cycle Document does not exist")
                SVProgressHUD.dismiss()
                //Declare Alert message
                let dialogMessage = UIAlertController(title: "Current Cycle Document does not exist", message: "Please Contact Administrator", preferredStyle: .alert)
                
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
    }
    func getCycleNumber() {
        SVProgressHUD.show()
        //Get Cycle Number from Firebase
        let cycle = Firestore.firestore().collection(self.farmName + "Details").document("farmDetail")
        
        cycle.getDocument { (document, error) in
            if let document = document, document.exists {
                let dataDescription = document.data()
                self.cycleNumber = dataDescription!["currentCycleNumber"] as! Int
                self.numberOfFloors = dataDescription!["numberOfFloors"] as! Int
                self.hargaPerKwh = dataDescription!["hargaPerKwh"] as! Float
                self.updateCoreDataUserProfile()
                
            } else {
                print("Current Cycle Document does not exist")
                SVProgressHUD.dismiss()
                //Declare Alert message
                let dialogMessage = UIAlertController(title: "Current Cycle Document does not exist", message: "Please Contact Administrator", preferredStyle: .alert)
                
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
    }
    
    func updateCoreDataUserProfile() {
        loadUserData()
        //Delete existing attribute
        self.context.delete(self.loadedUserData[0])
        //Update Local Array
        self.loadedUserData.remove(at: 0)
        //Save New Data
        let newUserProfile = UserProfile(context: context)
        newUserProfile.cycleNumber = Int16(cycleNumber)
        newUserProfile.numberOfFloors = Int16(numberOfFloors)
        newUserProfile.hargaPerKwh = hargaPerKwh
        newUserProfile.email = email
        newUserProfile.farmName = farmName
        newUserProfile.fullName = fullName
        newUserProfile.loginClass = loginClass
        
        self.save()
    }
    func loadUserData() {
        do {
            loadedUserData = try context.fetch(request)
        } catch {
            print("Error fetching data from context \(error)")
        }
    }
    
    func save() {
        do {
            try context.save()
            print("Data Saved")
            self.delegate?.dataReceivedSettingsViewController(farmName : self.farmName, cycleNumber : self.cycleNumber, numberOfFloors: self.numberOfFloors, hargaPerKwh: self.hargaPerKwh )
            SVProgressHUD.dismiss()
            _ = self.navigationController?.popViewController(animated: true)
        } catch {
            print ("Error Saving Context \(error)")
            SVProgressHUD.dismiss()
        }
    }
    
    @objc private func reachabilityChanged( notification: NSNotification )
    {
        guard let reachability = notification.object as? Reachability else
        {
            return
        }

        if reachability.connection != .unavailable
        {
            if reachability.connection == .wifi
            {
                print("Reachable via WiFi")
                let banner = StatusBarNotificationBanner(title: "Connected via WiFi", style: .success)
                banner.show()
            }
            else
            {
                print("Reachable via Cellular")
                let banner = StatusBarNotificationBanner(title: "Connected via Cellular", style: .success)
                banner.show()
            }
        }
        else
        {
            print("Network not reachable")
            let banner = StatusBarNotificationBanner(title: "Not Connected", style: .danger)
            banner.show()
        }
    }
}
