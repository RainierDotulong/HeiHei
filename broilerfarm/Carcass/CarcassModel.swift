//
//  CarcassModel.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/31/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct CarcassProduction: Codable {
    
    @DocumentID var id: String?
    var hargaBeliAyam : Int
    //Transport
    var transportName : String
    var transportBank : String
    var transportBankNumber : String
    var transportBankName : String
    var transportPaymentTerm : String
    var amountDueForTransport : Int
    var licensePlateNumber : String
    var sourceFarm : String
    var escort : String
    var transportedWeight : Float
    var transportedQuantity : Int
    var transportCreatedBy : String
    var transportCreatedTimestamp : Double
    //RPA
    var rpaName : String
    var rpaAddress : String
    var rpaLatitude : Double
    var rpaLongitude : Double
    var rpaNoNkv : String
    var rpaPerhitunganBiaya : String
    var rpaPaymentTerm : String
    var rpaSideProduct : Bool
    var rpaContactPerson : String
    var rpaContactPhone : String
    var rpaBank : String
    var rpaBankName : String
    var rpaBankNumber : String
    var slaughterTimestamp : Double
    var typeOfWork : String
    //Input RPA
    var receivedWeight : Float
    var receivedQuantity : Int
    var receivedDeadWeight : Float
    var receivedDeadQuantity : Int
    var rpaInputCreatedBy : String
    var rpaInputCreatedTimestamp : Double
    //Output RPA
    var yieldedWeight : Float
    var yieldedProductNames : [String]
    var yieldedProductUnits : [String]
    var yieldedProductQuantities : [Float]
    var initialStorageProvider : String
    var rpaOutputCreatedBy : String
    var rpaOutputCreatedTimestamp : Double
    var rpaHargaPerKG : Int
    
    static func create(carcass: CarcassProduction) -> Bool {
        let db = Firestore.firestore()
        
        do {
            try db.collection("carcassProduction").document().setData(from: carcass)
            print("Successfully Updated Carcass Production Record!")
            return true
        } catch {
            print("Error Updating Carcass Production Record!")
            return false
        }
    }
    
    static func update(carcass: CarcassProduction) -> Bool {
        let db = Firestore.firestore()
        
        do {
            try db.collection("carcassProduction").document(carcass.id!).setData(from: carcass)
            print("Successfully Updated Carcass Production Record!")
            return true
        } catch {
            print("Error Updating Carcass Production Record!")
            return false
        }
    }
}
