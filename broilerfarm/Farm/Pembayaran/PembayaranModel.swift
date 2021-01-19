//
//  PembayaranModel.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/28/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct recapPembayaran: Codable {
    var pembayaranTotal : Int
    var name : String
}

struct Pembayaran: Codable {
    
    @DocumentID var id: String?
    var creationTimestamp : Double
    var accTimestamp : Double
    var isAcc : Bool
    var isRefunded : Bool
    var nominal : Int
    var accBy : String
    var perusahaanId : String
    var perusahaanName : String
    var perusahaanType : String
    var rekeningName : String
    var bank : String
    var bankNumber : String
    var createdBy : String
    
    static func create(farmName: String, cycleNumber : Int, pembayaran : Pembayaran) -> Bool {

        let db = Firestore.firestore()
        do {
            try db.collection("\(farmName)\(cycleNumber)Pembayaran").document().setData(from: pembayaran)
            print("Successfully Created Pembayaran Record!")
            return true
        } catch {
            print("Error Creating Pembayaran Record!")
            return false
        }
    }

    static func update(farmName: String, cycleNumber : Int, pembayaran : Pembayaran) -> Bool {

        let db = Firestore.firestore()
        do {
            try db.collection("\(farmName)\(cycleNumber)Pembayaran").document(pembayaran.id!).setData(from: pembayaran)
            print("Successfully Updated Pembayaran Record!")
            return true
        } catch {
            print("Error Updating Pembayaran Record!")
            return false
        }
    }
}
