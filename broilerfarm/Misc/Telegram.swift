//
//  Telegram.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 3/8/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class Telegram {
    
    let ChickenAppBotToken = "1146799674:AAGlSrFvdr2xvQwdjbe84X_1-YiPOTGHtHc"
    
    let TeamPanenChatID = "-452473627"
    
    let ColdStorageChatID = "-444214025"
    
    let HeiHeiRetailChatID = "-424413636"
    
    let LaporanCFPinantikChatID = "-396396799"
    
    let LaporanCFKejayanChatID = "-335093222"
    
    let LaporanCFLewihChatID = "-497575732"
    
    let PembayaranPanenCFChatID = "-417280003"
    
    func postTelegramMessage(botToken: String, chatID: String, text: String, parse_mode : String) {
        let url = "https://api.telegram.org/bot\(botToken)/sendMessage"
        let parameters: Parameters = [
            "chat_id" : chatID,
            "text" : text,
            "parse_mode" : parse_mode
        ]

        AF.request(url, method: .post, parameters: parameters ).responseJSON{
            response in
            switch response.result {
            case .success(let value):
                let jsonResponse : JSON = JSON(value)
                //print(jsonResponse)
                if jsonResponse["ok"].boolValue {
                    print("Telegram Message Sent")
                }
                else {
                    print("Unable to Send Telegram Message")

                }
            case .failure(let error):
                print("THIS IS THE ERROR: Error \(String(describing: error))")

            }
        }
    }
}
