//
//  DataModels.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 3/16/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import Foundation

struct User {
    var fullName : String
    var loginClass : String
    var farmName : String
    var email : String
}

struct FarmDetail {
    var farmName : String
    var currentCycleNumber : Int
    var numberOfFloors : Int
}

struct FarmFloorDetail {
    var farmName : String
    var cycleNumber : Int
    var floorNumber : Int
    var startingBodyWeight : Float
    var startingPopulation : Int
    var startTimestamp : Double
    var claimAge : Int
    var claimQuantity : Int
    var harvestedWeight : Float
    var harvestedQuantity : Int
    var pakanAwal : Int
}
struct Payment {
    var farm : String
    var cycle : Int
    var timestamp : String
    var company : String
    var fullName : String
    var nominal : String
    var notes : String
    var rekeningTujuan : String
    var status : String
    var type : String
}

struct Harvest {
    var farm : String
    var cycle : String
    var timestamp : String
    var company : String
    var companyAddress : String
    var deliveryOrderNumber : String
    var driver : String
    var driverContact : String
    var licensePlate : String
    var nomorSuratJalan : String
    var penimbang : String
    var sekat : String
    var totalNumber : String
    var totalWeight : String
    var tara : String
    var hargaPerKG : String
}

struct RetailCustomer {
    var name : String
    var address : String
    var phone : String
    var marketing : String
    var fullAddress : String
    var latitude : Double
    var longitude : Double
    var createdBy : String
    var timestamp : Double
}

struct RetailProduct {
    var name : String
    var description : String
    var pricePerUnit : Int
    var unit : String
    var createdBy : String
    var timestamp : Double
}

struct RetailStockOperation {
    var document : String
    var add : Bool
    var isCancelled : Bool
    var isAutomaticallyGenerated : Bool
    var productName : String
    var quantity : Float
    var unit : String
    var notes : String
    var createdBy : String
    var timestamp : Double
}

struct RetailStock {
    var productName : String
    var quantity : Float
    var unit : String
    var createdBy : String
    var timestamp : Double
}

struct RetailPurchaseOrder {
    var purchaseOrderNumber : String
    var name : String
    var address : String
    var phone : String
    var marketing : String
    var status : String //Created, Prepped, Quality Checked, Delivery in Progress, Delivered, Cancelled
    var deliveryContactName : String
    var deliveryContactPhone : String
    var deliveryAddress : String
    var deliveryLatitude : Double
    var deliveryLongitude : Double
    var deliverByDate : Double
    var paymentMethod : String
    var orderedItems : [RetailProduct]
    var orderedItemNotes : [String]
    var orderedItemQuantities : [Int]
    var realItems : [RetailProduct]
    var realItemNotes : [String]
    var realItemQuantities : [Float]
    var preppedBy : String
    var qualityCheckedBy : String
    var deliveredBy : String
    var deliveryZone : String
    var deliveryNumber : Int
    var deliveryTimestamp : Double
    var deliveryFee : Int
    var discount : Int
    var createdBy : String
    var timestamp : Double
    var isPaid : Bool
}

struct TransportProvider {
    var name : String
    var bank : String
    var bankNumber : String
    var bankName : String
    var paymentTerm : String
    var createdBy : String
    var timestamp : Double
}

struct RPA {
    var name : String
    var address : String
    var latitude : Double
    var longitude : Double
    var noNkv : String
    var perhitunganBiaya : String
    var referencePrice : Int
    var paymentTerm : String
    var sideProduct : Bool
    var contactPerson : String
    var contactPhone : String
    var bank : String
    var bankName : String
    var bankNumber : String
    var createdBy : String
    var timestamp : Double
}

struct RPAProduct {
    var name : String
    var unit : String
    var createdBy : String
    var timestamp : Double
}

struct StorageProvider {
    var name : String
    var address : String
    var latitude : Double
    var longitude : Double
    var contactPerson : String
    var contactPhone : String
    var pricePerKgPerDay : Int
    var numberOfFreeDays : Int
    var createdBy : String
    var timestamp : Double
}
