//
//  ColdStorageCalculations.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 6/30/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import Foundation


class ColdStorageCalculations {
    
    func calculateStorageCosts(numberOfFreeDays : [Int], pricePerKgPerDays : [Int], timestamps : [Double]) -> Int {
        //Append Current Timestamp
        var timestamps = timestamps
        timestamps.append(NSDate().timeIntervalSince1970)
        
        var storageCosts : [Int] = [Int]()
        for i in 0..<timestamps.count - 1 {
            //Calculate Cost in Current Storage
            let diffInDays : Int = Calendar.current.dateComponents([.day], from: Date(timeIntervalSince1970: timestamps[timestamps.count - 2 - i]), to:  Date(timeIntervalSince1970: timestamps[timestamps.count - 1 - i])).day!
            print(diffInDays)
            let countedDays = diffInDays - numberOfFreeDays[numberOfFreeDays.count - 1 - i]
            if countedDays > 0 {
                storageCosts.append(countedDays * pricePerKgPerDays[pricePerKgPerDays.count - 1 - i])
            }
        }
        return storageCosts.reduce(0,+)
    }
    
    func calculateCurrentHPP (additionalCosts : [Int], numberOfFreeDays : [Int], pricePerKgPerDays : [Int], timestamps : [Double]) -> Int {
        let additionalCost = additionalCosts.reduce(0,+)
        //Append Current Timestamp
        var timestamps = timestamps
        timestamps.append(NSDate().timeIntervalSince1970)
        
        var storageCosts : [Int] = [Int]()
        for i in 0..<timestamps.count - 1 {
            //Calculate Cost in Current Storage
            let diffInDays : Int = Calendar.current.dateComponents([.day], from: Date(timeIntervalSince1970: timestamps[timestamps.count - 2 - i]), to:  Date(timeIntervalSince1970: timestamps[timestamps.count - 1 - i])).day!
            let countedDays = diffInDays - numberOfFreeDays[numberOfFreeDays.count - 1 - i]
            if countedDays > 0 {
                storageCosts.append(countedDays * pricePerKgPerDays[pricePerKgPerDays.count - 1 - i])
            }
        }
        return additionalCost + storageCosts.reduce(0,+)
    }
    
    func calculateCurrentQuantity (operations : [Bool], quantities : [Float]) -> Float {
        var additions : [Float] = [Float]()
        var subtractions : [Float] = [Float]()
        for i in 0..<quantities.count {
            if operations[i] {
                additions.append(quantities[i])
            }
            else {
                subtractions.append(quantities[i])
            }
        }
        return additions.reduce(0,+) - subtractions.reduce(0,+)
    }
    
}
