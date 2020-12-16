//
//  ListrikModel.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/7/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Listrik: Codable {
    
    @DocumentID var id: String?
    let timestamp : Double
    let kWh : Float
    let reporterName : String
    
    
    static func create(farmName: String, cycleNumber: Int, listrik: Listrik) -> String {
        let db = Firestore.firestore()
                
        do {
            let documentID = UUID().uuidString
            try db.collection("\(farmName)\(cycleNumber)Listrik").document(documentID).setData(from: listrik)
            print("Successfully Created Listrik Record!")
            print(documentID)
            return documentID
        } catch {
            print("Error Creating Listrik Record!")
            return "error"
        }
    }
    
    static func update(farmName: String, cycleNumber: Int, listrik: Listrik) -> Bool {
        let db = Firestore.firestore()
        
        do {
            try db.collection("\(farmName)\(cycleNumber)Listrik").document(listrik.id!).setData(from: listrik)
            print("Successfully Updated Listrik Record!")
            return true
        } catch {
            print("Error Updating Listrik Record!")
            return false
        }
    }
}
