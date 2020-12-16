//
//  ColdStorageEditViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 7/4/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit

class ColdStorageEditViewController: UIViewController {
    
    var fullName : String = ""
    var loginClass : String = ""
    var selectedData : ColdStorageItem = ColdStorageItem(batchId: "", name: "", operations: [Bool](), notes: [String](), quantities: [Float](), units: [String](), creators: [String](), timestamps: [Double](), storages: [String](), pricePerKgPerDays: [Int](), numberOfFreeDays: [Int](), additionalCosts: [Int](), additionalCostDescriptions: [String]())

    @IBOutlet var navItem: UINavigationItem!
    @IBOutlet var additionalCostsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(fullName)
        print(loginClass)
        print(selectedData.id!)
    }
}
