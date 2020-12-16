//
//  VentilationModel.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 7/26/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Ventilation: Codable {
    
    @DocumentID var id: String?
    var timestamp : Double
    var ventilasiManual : Int
    var ventilasiIntermittent : Int
    var ventilasiOn : Int
    var ventilasiOff : Int
    var ventilasiHeater : Float
    var inverter : Int
    var inverterPinggir : Int
    var inverterTengah : Int
    var floor : Int
    var reporterName : String
    var pintuBlowerSuhu : Float
    var pintuBlowerSpeed : Int
    var pintuBlowerRh : Int
    var pintuBlowerNh3 : Int
    var pintuBlowerCo2 : Int
    var pintuCellDeckSuhu : Float
    var pintuCellDeckSpeed : Int
    var pintuCellDeckRh : Int
    var pintuCellDeckNh3 : Int
    var pintuCellDeckCo2 : Int
    var luarKandangSuhu : Float
    var luarKandangSpeed : Int
    var luarKandangRh : Int
    var luarKandangNh3 : Int
    var luarKandangCo2 : Int
    
    
    static func create(farmName: String, cycleNumber : Int, ventilation : Ventilation) -> Bool {
        
        let db = Firestore.firestore()
        
        do {
            try db.collection("\(farmName)\(cycleNumber)VentilationData").document().setData(from: ventilation)
            print("Successfully Created Ventilation Record!")
            return true
        } catch {
            print("Error Creating Ventilation Record!")
            return false
        }
    }
    
    static func update(farmName: String, cycleNumber : Int, ventilation : Ventilation) -> Bool {
        
        let db = Firestore.firestore()
        
        do {
            try db.collection("\(farmName)\(cycleNumber)VentilationData").document(ventilation.id!).setData(from: ventilation)
            print("Successfully Created Ventilation Record!")
            return true
        } catch {
            print("Error Creating Ventilation Record!")
            return false
        }
    }
}

