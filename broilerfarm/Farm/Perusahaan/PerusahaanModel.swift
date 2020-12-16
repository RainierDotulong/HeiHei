//
//  PerusahaanModel.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/15/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Perusahaan: Codable {
    
    @DocumentID var id: String?
    var timestamp : Double
    var companyName : String
    var companyAddress : String
    var companyType : String
    var contactName : String
    var contactPhone : String
    var createdBy : String
    
    static func create(timestamp: Double, companyName: String, companyAddress: String, companyType: String, contactName: String, contactPhone: String, createdBy: String) -> Bool {
        let db = Firestore.firestore()
        
        let perusahaan = Perusahaan(timestamp: timestamp, companyName: companyName, companyAddress: companyAddress, companyType: companyType, contactName: contactName, contactPhone: contactPhone, createdBy: createdBy)
        
        do {
            try db.collection("dataPerusahaan").document().setData(from: perusahaan)
            print("Successfully Created Perusahaan Record!")
            return true
        } catch {
            print("Error Creating Perusahaan Record!")
            return false
        }
    }
    
    static func update(documentId: String, timestamp: Double, companyName: String, companyAddress: String, companyType: String, contactName: String, contactPhone: String, createdBy: String) -> Bool {
        let db = Firestore.firestore()
        
        let perusahaan = Perusahaan(id: documentId, timestamp: timestamp, companyName: companyName, companyAddress: companyAddress, companyType: companyType, contactName: contactName, contactPhone: contactPhone, createdBy: createdBy)
        
        do {
            try db.collection("dataPerusahaan").document(documentId).setData(from: perusahaan)
            print("Successfully Created Perusahaan Record!")
            return true
        } catch {
            print("Error Creating Perusahaan Record!")
            return false
        }
    }
}
