//
//  FarmFloorPickerViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 12/21/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit

class FarmFloorPickerViewController: UIViewController {
    
    var fullName : String = ""
    var selectedMenu : String = ""
    
    var selectedFarm : String = ""
    var selectedFloor : String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    @IBAction func buttonPressed(_ sender: Any) {
        if (sender as AnyObject).tag == 1 {
            print("Pinantik Lantai 1")
            selectedFarm = "pinantik"
            selectedFloor = "1"
        }
        else if (sender as AnyObject).tag == 2 {
            print("Pinantik Lantai 2")
            selectedFarm = "pinantik"
            selectedFloor = "2"
        }
        else if (sender as AnyObject).tag == 3 {
            print("Kejayan Lantai 1")
            selectedFarm = "kejayan"
            selectedFloor = "1"
        }
        else if (sender as AnyObject).tag == 4 {
            print("Kejayan Lantai 2")
            selectedFarm = "kejayan"
            selectedFloor = "2"
        }
        else if (sender as AnyObject).tag == 5 {
            print("Kejayan Lantai 3")
            selectedFarm = "kejayan"
            selectedFloor = "3"
        }
        else if (sender as AnyObject).tag == 6 {
            print("Lewih Lantai 1")
            selectedFarm = "lewih"
            selectedFloor = "1"
        }
        else if (sender as AnyObject).tag == 7 {
            print("Lewih Lantai 2")
            selectedFarm = "lewih"
            selectedFloor = "2"
        }
        else if (sender as AnyObject).tag == 8 {
            print("Lewih Lantai 3")
            selectedFarm = "lewih"
            selectedFloor = "3"
        }
        else if (sender as AnyObject).tag == 9 {
            print("Lewih Lantai 4")
            selectedFarm = "lewih"
            selectedFloor = "4"
        }
        else if (sender as AnyObject).tag == 10 {
            print("Lewih Lantai 5")
            selectedFarm = "lewih"
            selectedFloor = "5"
        }
        else if (sender as AnyObject).tag == 11 {
            print("Lewih Lantai 6")
            selectedFarm = "lewih"
            selectedFloor = "6"
        }
        
        if selectedMenu == "reference" {
            self.performSegue(withIdentifier: "goToReferenceItems", sender: self)
        }
        else {
            print("Unidentified Menu Selected")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is ReferenceItemsTableViewController
        {
            let vc = segue.destination as? ReferenceItemsTableViewController
            vc?.fullName = fullName
            vc?.selectedFarm = selectedFarm
            vc?.selectedFloor = selectedFloor
        }
    }
}
