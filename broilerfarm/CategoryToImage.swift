//
//  CategoryToImage.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 11/3/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import Foundation

func CategoryToImage(category: String) -> String {
    
    let selectedImage : String
    //["ATK","Dapur","Herbal","Obat","Pakan", "Sanitasi", "Utility","Vaksin","Vitamin","Tenaga Kerja","Humas","Lain-Lain"]
    //["Vitamin","Lain-Lain"]
    if category == "Tenaga Kerja" {
        selectedImage = "labor"
    }
    else if category == "Obat" {
        selectedImage = "ovk"
    }
    else if category == "Utility" {
        selectedImage = "utility"
    }
    else if category == "ATK" {
        selectedImage = "stationery"
    }
    else if category == "Dapur" {
        selectedImage = "food"
    }
    else if category == "Humas" {
        selectedImage = "humas"
    }
    else if category == "Pakan" {
        selectedImage = "sack"
    }
    else if category == "Sanitasi" {
        selectedImage = "hand-sanitizer"
    }
    else if category == "Herbal" {
        selectedImage = "herbal"
    }
    else if category == "Vaksin" {
        selectedImage = "syringe"
    }
    else if category == "Vitamin" {
        selectedImage = "vitamins"
    }
    else if category == "DOC" {
        selectedImage = "chick"
    }
    else {
        selectedImage = "item"
    }
    
    return selectedImage
    
}
