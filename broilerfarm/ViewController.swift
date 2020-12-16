//
//  ViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 6/26/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    var userData = [UserProfile]()
    
    var farmName : String = ""
    var fullName : String = ""
    var email : String = ""
    var loginClass : String = ""
    
    var cycleNumber : Int = 0
    var numberOfFloors : Int = 0
    var hargaPerKwh : Float = 0

    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Get UserProfile Data
        getDataFromLocalStorage()
        
        if userData != [] {
            
            farmName = userData[0].farmName!
            fullName = userData[0].fullName!
            email = userData[0].email!
            loginClass = userData[0].loginClass!
            cycleNumber = Int(userData[0].cycleNumber)
            numberOfFloors = Int(userData[0].numberOfFloors)
            hargaPerKwh = userData[0].hargaPerKwh
            
            self.performSegue(withIdentifier: "goToHomepage", sender: self)
        }
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }

    @IBAction func signInButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "goToAuthentication", sender: self)
    }
    @IBAction func signUpButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "goToRegister", sender: self)
    }
    
    func getDataFromLocalStorage() {
        //Core Data Context
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        //Specify context and reqeust for core data
        let requestUserProfile : NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        do {
            userData = try context.fetch(requestUserProfile)
        } catch {
            print("Error fetching data from context \(error)")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is UITabBarController {
            let barViewControllers = segue.destination as! UITabBarController
            
            // access the first tab bar
            let navVC1 = barViewControllers.viewControllers?[0] as! UINavigationController
            let vc1 = navVC1.topViewController as? HomepageViewController
            vc1?.farmName = self.farmName
            vc1?.fullName = self.fullName
            vc1?.email = self.email
            vc1?.loginClass = self.loginClass
            vc1?.cycleNumber = self.cycleNumber
            vc1?.numberOfFloors = self.numberOfFloors
            vc1?.hargaPerKwh = self.hargaPerKwh
                        
            // access the second tab bar
            let navVC2 = barViewControllers.viewControllers?[1] as! UINavigationController
            let vc2 = navVC2.topViewController as? RetailHomepageViewController
            vc2?.fullName = self.fullName
            vc2?.email = self.email
            vc2?.loginClass = self.loginClass
            
            // access the third tab bar
            let navVC3 = barViewControllers.viewControllers?[2] as! UINavigationController
            let vc3 = navVC3.topViewController as? CarcassHomepageTableViewController
            vc3?.fullName = self.fullName
            vc3?.email = self.email
            vc3?.loginClass = self.loginClass
            
            // access the fourth tab bar
            let navVC4 = barViewControllers.viewControllers?[3] as! UINavigationController
            let vc4 = navVC4.topViewController as? ColdStorageHomepageViewController
            vc4?.fullName = self.fullName
            vc4?.email = self.email
            vc4?.loginClass = self.loginClass
            
        }
    }
    
}

//Disable Rotation
extension UINavigationController {
    
    override open var shouldAutorotate: Bool {
        get {
            if let visibleVC = visibleViewController {
                return visibleVC.shouldAutorotate
            }
            return super.shouldAutorotate
        }
    }
    
    override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation{
        get {
            if let visibleVC = visibleViewController {
                return visibleVC.preferredInterfaceOrientationForPresentation
            }
            return super.preferredInterfaceOrientationForPresentation
        }
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        get {
            if let visibleVC = visibleViewController {
                return visibleVC.supportedInterfaceOrientations
            }
            return super.supportedInterfaceOrientations
        }
    }
    
}

