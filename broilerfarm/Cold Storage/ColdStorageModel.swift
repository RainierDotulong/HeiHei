//
//  ColdStorageModel.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/31/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct ColdStorageItem: Codable, Equatable {
    @DocumentID var id: String?
    var batchId : String
    var name : String
    var operations : [Bool]
    var notes : [String]
    var quantities : [Float]
    var units : [String]
    var creators : [String]
    var timestamps : [Double]
    var storages : [String]
    var pricePerKgPerDays : [Int]
    var numberOfFreeDays : [Int]
    var additionalCosts : [Int]
    var additionalCostDescriptions : [String]
    
    static func create(coldStorage : ColdStorageItem) -> Bool {

        let db = Firestore.firestore()
        
        do {
            try db.collection("coldStorage").document().setData(from: coldStorage)
            print("Successfully Created Cold Storage Record!")
            return true
        } catch {
            print("Error Creating Cold Storage Record!")
            return false
        }
    }

    static func update(coldStorage : ColdStorageItem) -> Bool {

        let db = Firestore.firestore()

        do {
            try db.collection("coldStorage").document(coldStorage.id!).setData(from: coldStorage)
            print("Successfully Updated Cold Storage Record!")
            return true
        } catch {
            print("Error Updating Cold Storage Record!")
            return false
        }
    }
}
