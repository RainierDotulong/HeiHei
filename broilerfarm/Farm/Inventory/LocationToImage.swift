//
//  LocationToImage.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 1/2/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import Foundation

func LocationToImage(location: String) -> String {
    
    let selectedImage : String
    //lokasiData = ["Lantai 1","Lantai 2","Lantai 3","Lantai 4","Lantai 5","Lantai 6","Kantor","Pos Satpam","Dapur","General"]
    switch location {
    case "Lantai 1":
        selectedImage = "lantai1"
    case "Lantai 2":
        selectedImage = "lantai2"
    case "Lantai 3":
        selectedImage = "lantai3"
    case "Lantai 4":
        selectedImage = "lantai4"
    case "Lantai 5":
        selectedImage = "lantai5"
    case "Lantai 6":
        selectedImage = "lantai6"
    case "Kantor":
        selectedImage = "office"
    case "Pos Satpam":
        selectedImage = "security"
    case "General":
        selectedImage = "general"
    case "Dapur":
        selectedImage = "dapur"
    default:
        selectedImage = "redLogo"
        
    }
    return selectedImage
    
}

