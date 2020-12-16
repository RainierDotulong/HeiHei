//
//  DailyRecordModel.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 7/26/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct DailyRecord: Codable {
    
    @DocumentID var id: String?
    let timestamp : Double
    let deplesiMati : Int
    let deplesiCuling : Int
    let pakanPakai  : Int
    let bodyWeight : Float
    let kesehatanAyam : String
    let notes : String
    let lantai : Int
    let reporterName : String
    
    
    static func create(farmName: String, cycleNumber: Int, timestamp: Double, deplesiMati: Int, deplesiCuling: Int, pakanPakai: Int, bodyWeight: Float, kesehatanAyam: String, notes: String, lantai: Int, reporterName: String) -> Bool {
        let db = Firestore.firestore()
        
        let dailyRecord = DailyRecord(timestamp: timestamp, deplesiMati: deplesiMati, deplesiCuling: deplesiCuling, pakanPakai: pakanPakai, bodyWeight: bodyWeight, kesehatanAyam: kesehatanAyam, notes: notes, lantai: lantai, reporterName: reporterName)
        
        do {
            try db.collection("\(farmName)\(cycleNumber)DailyRecordings").document().setData(from: dailyRecord)
            print("Successfully Created Daily Record!")
            return true
        } catch {
            print("Error Creating Daily Record!")
            return false
        }
    }
    
    static func update(documentId: String, farmName: String, cycleNumber: Int, timestamp: Double, deplesiMati: Int, deplesiCuling: Int, pakanPakai: Int, bodyWeight: Float, kesehatanAyam: String, notes: String, lantai: Int, reporterName: String) -> Bool {
        let db = Firestore.firestore()
        
        let dailyRecord = DailyRecord(timestamp: timestamp, deplesiMati: deplesiMati, deplesiCuling: deplesiCuling, pakanPakai: pakanPakai, bodyWeight: bodyWeight, kesehatanAyam: kesehatanAyam, notes: notes, lantai: lantai, reporterName: reporterName)
        
        do {
            try db.collection("\(farmName)\(cycleNumber)DailyRecordings").document(documentId).setData(from: dailyRecord)
            print("Successfully Created Daily Record!")
            return true
        } catch {
            print("Error Creating Daily Record!")
            return false
        }
    }
}

struct DetailedDailyRecord {
    let timestamp : Double
    let deplesiMati : Int
    let deplesiCuling : Int
    let pakanPakai  : Int
    let bodyWeight : Float
    let kesehatanAyam : String
    let notes : String
    let lantai : Int
    let reporterName : String
    let age : Int
    let adg : Float
    let rgr : Float
    let population : Int
    let totalDeplesi : Int
    let totalPakanPakai : Int
    let fcr : Float
    let kepadatan : Float
    let ip : Float
    let estimatedKg : Float
}
