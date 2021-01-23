//
//  PanenModel.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/19/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct recapPanen: Codable {
    var panenTotal : Int
    var name : String
    var jumlahBerat : Float
    var panenNumber : Int
}
struct recapName: Codable {
    var name : String
}

struct PanenLantai: Codable {
    @DocumentID var id: String?
    var creationTimestamp : Double
    var isChecked : Bool
    var hargaPerKG : Int
    var mulaiMuatTimestamp : Double
    var selesaiMuatTimestamp : Double
    var jumlahKGDO : Float
    var namaPerusahaan : String
    var alamatPerusahaan : String
    var metodePembayaran : String
    var namaSopir : String
    var noKendaraaan : String
    var noSopir : String
    var pembuatDO : String
    var rangeBB : String
    var rangeBawah : Float
    var rangeAtas : Float
    var status : String //Created, ACC, Started, Finished
    var pengambilanTimestamp : Double
    var timestamps : [Double]
    var lantai : [Int]
    var jumlah : [Int]
    var isSubtract : [Bool]
    var isVoided : [Bool]
    var sekat : [String]
    var tara : [Float]
    var berat : [Float]
    var pemborongPanen : String
    var penimbang : String
    var accBy : String
    
    static func create(farmName: String, cycleNumber : Int, panen : Panen) -> Bool {

        let db = Firestore.firestore()
        
        do {
            try db.collection("\(farmName)\(cycleNumber)Panen").document().setData(from: panen)
            print("Successfully Created Panen Record!")
            return true
        } catch {
            print("Error Creating Panen Record!")
            return false
        }
    }

    static func update(farmName: String, cycleNumber : Int, panen : Panen) -> Bool {

        let db = Firestore.firestore()

        do {
            try db.collection("\(farmName)\(cycleNumber)Panen").document(panen.id!).setData(from: panen)
            print("Successfully Updated Panen Record!")
            return true
        } catch {
            print("Error Updating Panen Record!")
            return false
        }
    }
}
    
struct Panen: Codable {
    
    @DocumentID var id: String?
    var creationTimestamp : Double
    var isChecked : Bool
    var hargaPerKG : Int
    var mulaiMuatTimestamp : Double
    var selesaiMuatTimestamp : Double
    var jumlahKGDO : Float
    var namaPerusahaan : String
    var alamatPerusahaan : String
    var metodePembayaran : String
    var namaSopir : String
    var noKendaraaan : String
    var noSopir : String
    var pembuatDO : String
    var rangeBB : String
    var rangeBawah : Float
    var rangeAtas : Float
    var status : String //Created, ACC, Started, Finished
    var pengambilanTimestamp : Double
    var timestamps : [Double]
    var lantai : [Int]
    var jumlah : [Int]
    var isSubtract : [Bool]
    var isVoided : [Bool]
    var sekat : [String]
    var tara : [Float]
    var berat : [Float]
    var pemborongPanen : String
    var penimbang : String
    var accBy : String
    
    static func create(farmName: String, cycleNumber : Int, panen : Panen) -> Bool {

        let db = Firestore.firestore()
        
        do {
            try db.collection("\(farmName)\(cycleNumber)Panen").document().setData(from: panen)
            print("Successfully Created Panen Record!")
            return true
        } catch {
            print("Error Creating Panen Record!")
            return false
        }
    }

    static func update(farmName: String, cycleNumber : Int, panen : Panen) -> Bool {

        let db = Firestore.firestore()

        do {
            try db.collection("\(farmName)\(cycleNumber)Panen").document(panen.id!).setData(from: panen)
            print("Successfully Updated Panen Record!")
            return true
        } catch {
            print("Error Updating Panen Record!")
            return false
        }
    }
}

struct PanenTotals {
    let totalEkor : Int
    let netto : Float
    let averageBB : Float
    let validEntries : Int
}

