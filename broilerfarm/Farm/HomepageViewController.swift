//
//  HomepageViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 6/26/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import SVProgressHUD
import CoreData
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FileBrowser
import Reachability
import NotificationBannerSwift
import EmptyStateKit

class TabBarController : UITabBarController {
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
}

class HomepageTableViewCell : UITableViewCell {
    //homepageCell
    @IBOutlet var menuImageView: UIImageView!
    @IBOutlet var menuLabel: UILabel!
}

class HomepageViewController: UIViewController,sendToHomepageViewController, UITabBarControllerDelegate, UITableViewDelegate, UITableViewDataSource, EmptyStateDelegate {
    
    //Initalize Variables passed from previous VC
    var farmName : String = ""
    var fullName : String = ""
    var email : String = ""
    var loginClass : String = ""
    var cycleNumber : Int  = 0
    var numberOfFloors : Int  = 0
    var hargaPerKwh : Float  = 0
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let request : NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
    var loadedUserData = [UserProfile]()
    
    var cycleNumberChange : Bool = false
    var hargaPerKwhChange : Bool = false
    var farmNameChange : Bool = false
    var classChange : Bool = false
    
    var sections : [String] = ["Monitoring","Recording", "Gudang", "Panen", "Administrasi"]
    
    struct menuData {
        var image : String
        var title : String
    }
    
    var monitoringMenus : [menuData] = [menuData]()
    var recordingMenus : [menuData] = [menuData]()
    var gudangMenus : [menuData] = [menuData]()
    var panenMenus : [menuData] = [menuData]()
    var administrasiMenus : [menuData] = [menuData]()
    
    @IBOutlet var navItem: UINavigationItem!
    @IBOutlet var settingsButton: UIButton!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var loginClassLabel: UILabel!
    @IBOutlet var versionLabel: UILabel!
    
    @IBOutlet var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
                
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        nameLabel.text = fullName
        loginClassLabel.text = loginClass.uppercased()
        
        self.tabBarController?.delegate = self
        
        self.tableView.emptyState.delegate = self
        
        //Set Change States back to false
        cycleNumberChange = false
        farmNameChange = false
        classChange = false
        
        //Hide the back button on navigation bar
        navigationItem.hidesBackButton = true
        
        navItem.title = "\(farmName.uppercased())-\(cycleNumber)"
        
        //Set Version Label
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        versionLabel.text = "v" + String(appVersion!) + " (" + String(build!) + ")"
        //Check for user profile changes
        checkForUserProfileChanges()
        //Register for Push Notifications
        let pushManager = PushNotificationManager(userID: email)
        pushManager.registerForPushNotifications()
        
        enableDisableMenus()
        
        if connectionStatus == true {
            print("Connected")
        }
        else {
            let banner = StatusBarNotificationBanner(title: "Not Connected", style: .danger)
            banner.show()
        }
        
        // Add reachability observer
        if let reachability = AppDelegate.sharedAppDelegate()?.reachability
        {
            NotificationCenter.default.addObserver( self, selector: #selector( self.reachabilityChanged ),name: Notification.Name.reachabilityChanged, object: reachability )
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func emptyState(emptyState: EmptyState, didPressButton button: UIButton) {
        print("Empty State button pressed")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    func getCycleNumber() {
        //Get Cycle Number from Firebase
        let cycle = Firestore.firestore().collection(self.farmName + "Details").document("farmDetail")
        
        cycle.getDocument { (document, error) in
            if let document = document, document.exists {
                let dataDescription = document.data()
                if self.cycleNumber != dataDescription!["currentCycleNumber"] as! Int {
                    self.cycleNumber = dataDescription!["currentCycleNumber"] as! Int
                    self.cycleNumberChange = true
                }
                else {
                    print("Cycle Number is up to date")
                    self.cycleNumberChange = false
                }
                
                if self.hargaPerKwh != dataDescription!["hargaPerKwh"] as! Float {
                    self.hargaPerKwh = dataDescription!["hargaPerKwh"] as! Float
                    self.hargaPerKwhChange = true
                }
                else {
                    print("Harga Per KWH is up to date")
                    self.hargaPerKwhChange = false
                }
                
                if self.cycleNumberChange == true || self.farmNameChange == true || self.hargaPerKwhChange == true || self.classChange == true {
                    print("Updating Core Data User Profile")
                    self.updateCoreDataUserProfile()
                    self.enableDisableMenus()
                }
                else {
                    print("Core Data User Profile is up to date")
                }
                
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
    
    func checkForUserProfileChanges() {
        //Get Cycle Number from Firebase
        let userProf = Firestore.firestore().collection("userProfiles").document(self.email)
        
        userProf.getDocument { (document, error) in
            if let document = document, document.exists {
                let dataDescription = document.data()
                if self.loginClass != dataDescription!["class"] as! String {
                    self.loginClass = dataDescription!["class"] as! String
                    self.classChange = true
                }
                else {
                    print("Login Class is up to date")
                    self.classChange = false
                }
                if self.farmName != dataDescription!["farmName"] as! String {
                    self.farmName = dataDescription!["farmName"] as! String
                    self.farmNameChange = true
                }
                else {
                    print("Farm Name is up to date")
                    self.farmNameChange = false
                }
                
                //Check for cycle Number changes
                self.getCycleNumber()
                
            } else {
                print("User Profile Document does not exist")
                SVProgressHUD.dismiss()
                //Declare Alert message
                let dialogMessage = UIAlertController(title: "User Profile Document does not exist", message: "Please Contact Administrator", preferredStyle: .alert)
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
    
    func enableDisableMenus() {
        //Enable/Disable Menus
        let dailyRecordMenu : menuData = menuData(image: "dailyRecordIcon", title: "Daily Record")
        let dailyRecordDataMenu : menuData = menuData(image: "dailyRecordDataIcon", title: "Daily Record Data")
        let ventilationMenu : menuData = menuData(image: "ventilationIcon", title: "Ventilation")
        let ventilationDataMenu : menuData = menuData(image: "ventilationDataIcon", title: "Ventilation Data")
        let listrikMenu : menuData = menuData(image: "thunder", title: "Listrik")
        let pettyCashMenu : menuData = menuData(image: "pettyCash", title: "Petty Cash")
        let storageMenu : menuData = menuData(image: "stock", title: "Storage")
        let inventoryMenu : menuData = menuData(image: "inventory", title: "Inventory")
        let startCycle : menuData = menuData(image: "cycleIcon", title: "Start Cycle")
        let rekening : menuData = menuData(image: "record", title: "Rekening")
        let reference : menuData = menuData(image: "reference", title: "Reference")
        let referenceTemplate : menuData = menuData(image: "template", title: "Reference Template")
        let pemborongPanen : menuData = menuData(image: "team", title: "Pemborong Panen")
        let priceList : menuData = menuData(image: "priceList", title: "Price List")
        let pembayaran : menuData = menuData(image: "payments", title: "Pembayaran")
        let panen : menuData = menuData(image: "harvestIcon", title: "Panen")
        let dataPerusahaan : menuData = menuData(image: "companydata", title: "Data Perusahaan")
        let sensors : menuData = menuData(image: "coldStorage", title: "Sensors")
        let usersMenu : menuData = menuData(image: "usersIcon", title: "Users")
        
        if loginClass == "superadmin" {
            sections = ["Monitoring","Recording", "Gudang", "Panen", "Administrasi"]
            monitoringMenus = [sensors]
            recordingMenus = [dailyRecordMenu, dailyRecordDataMenu, ventilationMenu, ventilationDataMenu, listrikMenu, pettyCashMenu]
            gudangMenus = [storageMenu, inventoryMenu]
            panenMenus = [panen,pembayaran,pemborongPanen]
            administrasiMenus = [startCycle, reference, referenceTemplate, priceList, dataPerusahaan, rekening, usersMenu]
            
            let tabBarControllerItems = self.tabBarController?.tabBar.items
            tabBarControllerItems?[0].isEnabled = true
            tabBarControllerItems?[1].isEnabled = true
            tabBarControllerItems?[2].isEnabled = true
            tabBarControllerItems?[3].isEnabled = true
        }
        else if loginClass == "administrator" {
            sections = ["Monitoring","Recording", "Gudang", "Panen", "Administrasi"]
            monitoringMenus = [sensors]
            recordingMenus = [dailyRecordMenu, dailyRecordDataMenu, ventilationMenu, ventilationDataMenu, listrikMenu, pettyCashMenu]
            gudangMenus = [storageMenu, inventoryMenu]
            panenMenus = [panen,pembayaran,pemborongPanen]
            administrasiMenus = [startCycle, reference, referenceTemplate, priceList, dataPerusahaan, rekening, usersMenu]
            let tabBarControllerItems = self.tabBarController?.tabBar.items
            tabBarControllerItems?[0].isEnabled = true
            tabBarControllerItems?[1].isEnabled = true
            tabBarControllerItems?[2].isEnabled = true
            tabBarControllerItems?[3].isEnabled = true
        }
        else if loginClass == "farmManager" {
            sections = ["Monitoring","Recording", "Gudang", "Panen"]
            monitoringMenus = [sensors]
            recordingMenus = [dailyRecordMenu, dailyRecordDataMenu, ventilationMenu, ventilationDataMenu, listrikMenu, pettyCashMenu]
            gudangMenus = [storageMenu, inventoryMenu]
            panenMenus = [panen]
            administrasiMenus = [menuData]()
            let tabBarControllerItems = self.tabBarController?.tabBar.items
            tabBarControllerItems?[0].isEnabled = true
            tabBarController?.viewControllers?.remove(at: 1)
            tabBarController?.viewControllers?.remove(at: 1)
            tabBarController?.viewControllers?.remove(at: 1)
        }
        else if loginClass == "farmWorker" {
            sections = ["Monitoring","Recording", "Gudang"]
            monitoringMenus = [sensors]
            recordingMenus = [dailyRecordMenu, dailyRecordDataMenu, ventilationMenu, ventilationDataMenu, listrikMenu, pettyCashMenu]
            gudangMenus = [storageMenu, inventoryMenu]
            panenMenus = [menuData]()
            administrasiMenus = [menuData]()
            let tabBarControllerItems = self.tabBarController?.tabBar.items
            tabBarControllerItems?[0].isEnabled = true
            tabBarController?.viewControllers?.remove(at: 1)
            tabBarController?.viewControllers?.remove(at: 1)
            tabBarController?.viewControllers?.remove(at: 1)
        }
        else if loginClass == "harvester" {
            sections = ["Panen"]
            monitoringMenus = [menuData]()
            recordingMenus = [menuData]()
            gudangMenus = [menuData]()
            panenMenus = [panen]
            administrasiMenus = [menuData]()
            let tabBarControllerItems = self.tabBarController?.tabBar.items
            tabBarControllerItems?[0].isEnabled = true
            tabBarController?.viewControllers?.remove(at: 1)
            tabBarController?.viewControllers?.remove(at: 1)
            tabBarController?.viewControllers?.remove(at: 1)
        }
        else if loginClass == "retailer" {
            sections = []
            monitoringMenus = [menuData]()
            recordingMenus = [menuData]()
            gudangMenus = [menuData]()
            panenMenus = [menuData]()
            administrasiMenus = [menuData]()
            let tabBarControllerItems = self.tabBarController?.tabBar.items
            tabBarControllerItems?[0].isEnabled = true
            tabBarController?.viewControllers?.remove(at: 2)
            tabBarController?.viewControllers?.remove(at: 2)
        }
        else if loginClass == "retailAdministrator" {
            sections = []
            monitoringMenus = [menuData]()
            recordingMenus = [menuData]()
            gudangMenus = [menuData]()
            panenMenus = [menuData]()
            administrasiMenus = [menuData]()
            let tabBarControllerItems = self.tabBarController?.tabBar.items
            tabBarControllerItems?[0].isEnabled = true
            tabBarController?.viewControllers?.remove(at: 2)
            tabBarController?.viewControllers?.remove(at: 2)
        }
        else {
            let dialogMessage = UIAlertController(title: "Pending Approval", message: "Your Account has not been approved by the administrator", preferredStyle: .alert)
            
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
                self.logout()
            })
            
            dialogMessage.addAction(ok)
            
            self.present(dialogMessage, animated: true, completion: nil)
            
            recordingMenus = [menuData]()
            gudangMenus = [menuData]()
            panenMenus = [menuData]()
            administrasiMenus = [menuData]()
            
            let tabBarControllerItems = self.tabBarController?.tabBar.items
            tabBarControllerItems?[0].isEnabled = true
            tabBarControllerItems?[1].isEnabled = false
            tabBarControllerItems?[2].isEnabled = false
            tabBarControllerItems?[3].isEnabled = false
        }
        self.tableView.reloadData()
        self.reloadEmptyStateKit(state: "noData")
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
        
        enableDisableMenus()
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
            navItem.title = "\(farmName.uppercased())-\(cycleNumber)"
            SVProgressHUD.dismiss()
        } catch {
            print ("Error Saving Context \(error)")
            SVProgressHUD.dismiss()
        }
    }
    
    func dataReceivedSettingsViewController(farmName : String, cycleNumber: Int, numberOfFloors: Int, hargaPerKwh: Float) {
        self.farmName = farmName
        self.cycleNumber = cycleNumber
        self.numberOfFloors = numberOfFloors
        self.hargaPerKwh = hargaPerKwh
        navItem.title = "\(farmName.uppercased())-\(cycleNumber)"
    }
    
    @IBAction func settingsButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "goToSettings", sender: self)
    }
    @IBAction func filesButtonPressed(_ sender: Any) {
        let fileBrowser = FileBrowser()
        fileBrowser.modalPresentationStyle = .overFullScreen
        //fileBrowser.excludesFileExtensions = ["plist","mov"]
        present(fileBrowser, animated: true, completion: nil)
    }
    @IBAction func updateButtonPressed(_ sender: Any) {
        if let url = URL(string: "https://guard.globalxtreme.net/ipa/chickenapp-install.html") {
            UIApplication.shared.open(url)
        }
    }
    @IBAction func signOutButtonPressed(_ sender: Any) {
        //Declare Alert message
        let dialogMessage = UIAlertController(title: "Sign Out?", message: "Are you sure you want to Sign Out?", preferredStyle: .alert)
        
        // Create OK button with action handler
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            self.logout()
        })
        
        // Create Cancel button with action handlder
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            print("Cancel button tapped")
        }
        
        //Add OK and Cancel button to dialog message
        dialogMessage.addAction(ok)
        dialogMessage.addAction(cancel)
        
        // Present dialog message to user
        self.present(dialogMessage, animated: true, completion: nil)
    }
    
    func logout() {
        //Log out from Firebase
        do {
            try Auth.auth().signOut()
            self.dismiss(animated: true, completion: nil)
        } catch let err {
            print(err)
        }
        
        //Delete Core Data User Profile
        //Core Data Context
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let deleteProfileFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "UserProfile")
        let deleteProfileRequest = NSBatchDeleteRequest(fetchRequest: deleteProfileFetch)
        
        do
        {
            try context.execute(deleteProfileRequest)
            try context.save()
        }
        catch
        {
            print ("There was an error deleting UserProfile entity")
        }
        
        //Delete FCM Token Record
        let userRef = Firestore.firestore().collection("userProfiles").document(email)
        userRef.setData(["fcmToken": ""], merge: true)
        
        navigationController?.popViewController(animated: true)
        
    }
    
    func reloadEmptyStateKit(state: String) {
        if self.sections.isEmpty {
            switch state{
            case "noData":
                self.tableView.emptyState.show(State.noData)
            case "noSearch":
                self.tableView.emptyState.show(State.noSearch)
            default:
                self.tableView.emptyState.show(State.noInternet)
            }
        }
        else {
            self.tableView.emptyState.hide()
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
    
    // MARK: Table view data source
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch sections[section] {
        case "Recording":
            return recordingMenus.count
        case "Gudang":
            return gudangMenus.count
        case "Panen":
            return panenMenus.count
        case "Administrasi":
            return administrasiMenus.count
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.rowHeight = UITableView.automaticDimension
        
        func createCell(data : menuData) -> HomepageTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "homepageCell", for: indexPath) as! HomepageTableViewCell
            
            cell.menuLabel.text = data.title
            cell.menuImageView.image = UIImage(named: data.image)
        
            return cell
        }
        
        switch sections[indexPath.section] {
        case "Monitoring":
            return createCell(data: monitoringMenus[indexPath.row])
        case "Recording":
            return createCell(data: recordingMenus[indexPath.row])
        case "Gudang":
            return createCell(data: gudangMenus[indexPath.row])
        case "Panen":
            return createCell(data: panenMenus[indexPath.row])
        case "Administrasi":
            return createCell(data: administrasiMenus[indexPath.row])
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "homepageCell", for: indexPath) as! HomepageTableViewCell
            
            cell.menuLabel.text = "Title"
            cell.menuImageView.image = UIImage(named: "currentCycle")
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch sections[indexPath.section] {
        case "Monitoring":
            switch monitoringMenus[indexPath.row].title {
            case "Sensors":
                print("Sensors")
            default:
                print("Unknown Monitoring Menu")
            }
        case "Recording":
            switch recordingMenus[indexPath.row].title {
            case "Daily Record":
                self.performSegue(withIdentifier: "goToDailyRecord", sender: self)
            case "Daily Record Data":
                self.performSegue(withIdentifier: "goToDailyRecordData", sender: self)
            case "Ventilation":
                self.performSegue(withIdentifier: "goToVentilation", sender: self)
            case "Ventilation Data":
                self.performSegue(withIdentifier: "goToVentilationData", sender: self)
            case "Listrik":
                self.performSegue(withIdentifier: "goToListrik", sender: self)
            case "Petty Cash":
                self.performSegue(withIdentifier: "goToPettyCash", sender: self)
            default:
                print("Unknown Recording Menu")
            }
        case "Gudang":
            switch gudangMenus[indexPath.row].title {
            case "Inventory":
                self.performSegue(withIdentifier: "goToInventory", sender: self)
            case "Storage":
                self.performSegue(withIdentifier: "goToStorage", sender: self)
            default:
                print("Unknown Gudang Menu")
            }
        case "Panen":
            switch panenMenus[indexPath.row].title {
            case "Harvest":
                self.performSegue(withIdentifier: "goToHarvest", sender: self)
            case "Panen":
                print("Panen Tapped")
                self.performSegue(withIdentifier: "goToPanenTable", sender: self)
            case "Pembayaran":
                print("Pembayaran Tapped")
                self.performSegue(withIdentifier: "goToPembayaran", sender: self)
            case "Pemborong Panen":
                self.performSegue(withIdentifier: "goToPemborongData", sender: self)
            default:
                print("Unknown Panen Menu")
            }
        case "Administrasi":
            switch administrasiMenus[indexPath.row].title {
            case "Start Cycle":
                self.performSegue(withIdentifier: "goToStartCycle", sender: self)
            case "Reference":
                self.performSegue(withIdentifier: "goToFarmFloorPicker", sender: self)
            case "Reference Template":
                self.performSegue(withIdentifier: "goToReferenceTemplate", sender: self)
            case "Price List":
                self.performSegue(withIdentifier: "goToPriceList", sender: self)
            case "Data Supplier":
                self.performSegue(withIdentifier: "goToSupplierData", sender: self)
            case "Data Perusahaan":
                print("Data Perusahaan Tapped")
                self.performSegue(withIdentifier: "goToDataPerusahaan", sender: self)
            case "Rekening":
                self.performSegue(withIdentifier: "goToRekening", sender: self)
            case "Users":
                self.performSegue(withIdentifier: "goToUsers", sender: self)
            default:
                print("Unknown Administrasi Menu")
            }
        default:
            print("Unknown Section")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is VentilationViewController
        {
            let vc = segue.destination as? VentilationViewController
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.cycleNumber = cycleNumber
            vc?.numberOfFloors = numberOfFloors
        }
        else if segue.destination is VentilationDataViewController
        {
            let vc = segue.destination as? VentilationDataViewController
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.cycleNumber = cycleNumber
            vc?.numberOfFloors = numberOfFloors
            
        }
        else if segue.destination is DailyRecordViewController
        {
            let vc = segue.destination as? DailyRecordViewController
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.cycleNumber = cycleNumber
            vc?.numberOfFloors = numberOfFloors
        }
        else if segue.destination is DailyRecordDataViewController
        {
            let vc = segue.destination as? DailyRecordDataViewController
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.cycleNumber = cycleNumber
            vc?.numberOfFloors = numberOfFloors
        }
        else if segue.destination is SettingsViewController
        {
            let vc = segue.destination as? SettingsViewController
            vc?.farmName = farmName
            vc?.cycleNumber = cycleNumber
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.email = email
            vc?.delegate = self
        }
        else if segue.destination is StorageViewController
        {
            let vc = segue.destination as? StorageViewController
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.cycleNumber = cycleNumber
            vc?.loginClass = loginClass
        }
        else if segue.destination is PettyCashViewController
        {
            let vc = segue.destination as? PettyCashViewController
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.cycleNumber = cycleNumber
            vc?.loginClass = loginClass
        }
        else if segue.destination is InventoryTableViewController
        {
            let vc = segue.destination as? InventoryTableViewController
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.cycleNumber = cycleNumber
            vc?.loginClass = loginClass
        }
        else if segue.destination is ListrikHomepageViewController
        {
            let vc = segue.destination as? ListrikHomepageViewController
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.cycleNumber = cycleNumber
            vc?.loginClass = loginClass
            vc?.numberOfFloors = numberOfFloors
            vc?.hargaPerKwh = hargaPerKwh
        }
        else if segue.destination is StartCycleViewController
        {
            let vc = segue.destination as? StartCycleViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
        }
        else if segue.destination is ReferenceTemplateTableViewController {
            let vc = segue.destination as? ReferenceTemplateTableViewController
            vc?.fullName = fullName
        }
        else if segue.destination is FarmFloorPickerViewController {
            let vc = segue.destination as? FarmFloorPickerViewController
            vc?.fullName = fullName
            vc?.selectedMenu = "reference"
        }
        else if segue.destination is PriceListTableViewController
        {
            let vc = segue.destination as? PriceListTableViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
        }
        else if segue.destination is PemborongTableViewController
        {
            let vc = segue.destination as? PemborongTableViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
        }
        else if segue.destination is PerusahaanTableViewController
        {
            let vc = segue.destination as? PerusahaanTableViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.farmName = farmName
            vc?.cycleNumber = cycleNumber
        }
        else if segue.destination is PanenTableViewController
        {
            let vc = segue.destination as? PanenTableViewController
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.cycleNumber = cycleNumber
            vc?.loginClass = loginClass
            vc?.numberOfFloors = numberOfFloors
        }
        else if segue.destination is PembayaranTableViewController
        {
            let vc = segue.destination as? PembayaranTableViewController
            vc?.farmName = farmName
            vc?.fullName = fullName
            vc?.cycleNumber = cycleNumber
            vc?.loginClass = loginClass
            vc?.numberOfFloors = numberOfFloors
        }
        else if segue.destination is DataRekeningTableViewController
        {
            let vc = segue.destination as? DataRekeningTableViewController
            vc?.fullName = fullName
        }
        else if segue.destination is UsersTableViewController
        {
            let vc = segue.destination as? UsersTableViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
        }
    }
}
