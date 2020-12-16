//
//  PanenFunctions.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/28/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import Foundation

class PanenFunctions {
    func calculateTotals (data: Panen) -> PanenTotals {
        var validJumlah : [Int] = [Int]()
        var validBerat : [Float] = [Float]()
        var validTara : [Float] = [Float]()
        for i in 0..<data.isVoided.count {
            if data.isVoided[i] == false && data.isSubtract[i] == false {
                validJumlah.append(data.jumlah[i])
                validBerat.append(data.berat[i])
                validTara.append(data.tara[i])
            }
        }
        let validEntries = validJumlah.count
        let totalEkor = validJumlah.reduce(0,+)
        let netto = validBerat.reduce(0,+) - validTara.reduce(0,+)
        let averageBB = netto/Float(totalEkor)
        
        return PanenTotals(totalEkor: totalEkor, netto: netto, averageBB:averageBB, validEntries: validEntries)
    }
    
    func constructRecordingCsv(data: Panen) -> String {
        let mulaiMuatDate = Date(timeIntervalSince1970: data.mulaiMuatTimestamp)
        let selesaiMuatDate = Date(timeIntervalSince1970: data.selesaiMuatTimestamp)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        let mulaiMuatStringDate = dateFormatter.string(from: mulaiMuatDate).replacingOccurrences(of: ",", with: " ")
        let selesaiMuatStringDate = dateFormatter.string(from: selesaiMuatDate).replacingOccurrences(of: ",", with: " ")
        
        var csvText = "Detil Penerima\n"
        csvText.append("Nama Perusahaan,\(data.namaPerusahaan)\n")
        csvText.append("Alamat Perusahaan,\(data.alamatPerusahaan)\n")
        csvText.append("Mulai Muat,\(mulaiMuatStringDate)\n")
        csvText.append("Selesai Muat,\(selesaiMuatStringDate)\n")
        csvText.append("Nama Sopir,\(data.namaSopir)\n")
        csvText.append("Nomor Telp Sopir,\(data.noSopir)\n")
        csvText.append("Nomor Kendaraan,\(data.noKendaraaan)\n")
        csvText.append("Range BB,\(data.rangeBB.replacingOccurrences(of: ",", with: "."))\n")
        csvText.append("Recording Panen\n")
        csvText.append("NO,Tanggal,Jumlah(Ekor),Berat(KG),Tara(KG),Netto(KG)\n")
        
        var noUrut : Int = 0
        for i in 0..<data.berat.count {
            if data.isVoided[i] == false && data.isSubtract[i] == false {
                noUrut += 1
                let date = Date(timeIntervalSince1970: data.timestamps[i] )
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short
                let stringDate = dateFormatter.string(from: date).replacingOccurrences(of: ",", with: " ")
                let berat = String(format: "%.2f",data.berat[i]).replacingOccurrences(of: ",", with: ".")
                let tara = String(format: "%.2f",data.tara[i]).replacingOccurrences(of: ",", with: ".")
                let netto = String(format: "%.2f",data.berat[i] - data.tara[i]).replacingOccurrences(of: ",", with: ".")
                let newLine = "\(noUrut),\(stringDate),\(data.jumlah[i]),\(berat),\(tara),\(netto)\n"
                csvText.append(newLine)
            }
        }
        let panenTotals = PanenFunctions().calculateTotals(data: data)
        
        csvText.append("Total Ekor,\(panenTotals.totalEkor)\n")
        csvText.append("Total Netto (KG),\(String(format: "%.2f", panenTotals.netto).replacingOccurrences(of: ",", with: "."))\n")
        csvText.append("Average BB (KG),\(String(format: "%.2f", panenTotals.averageBB).replacingOccurrences(of: ",", with: "."))\n")
        csvText.append("Penimbang,\(data.penimbang)\n")
    
        return csvText
    }
}
