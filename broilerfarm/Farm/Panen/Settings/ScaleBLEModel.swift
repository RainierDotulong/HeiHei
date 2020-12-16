//
//  ScaleBLEModel.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/25/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct scaleBle : Codable {
    @DocumentID var id: String?
    var name : String
    
    static func create(ble : scaleBle) -> Bool {

        let db = Firestore.firestore()
        
        do {
            try db.collection("scaleBle").document().setData(from: ble)
            print("Successfully Created Scale BLE Record!")
            return true
        } catch {
            print("Error Creating Scale BLE Record!")
            return false
        }
    }

    static func update(farmName: String, cycleNumber : Int, ble : scaleBle) -> Bool {

        let db = Firestore.firestore()

        do {
            try db.collection("scaleBle").document(ble.id!).setData(from: ble)
            print("Successfully Updated Scale BLE Record!")
            return true
        } catch {
            print("Error Updating Scale BLE Record!")
            return false
        }
    }
}
