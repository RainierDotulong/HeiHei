//
//  PushNotificationSender.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 9/23/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit

//USAGE:
//let sender = PushNotificationSender()
//sender.sendPushNotification(to: "token", title: "Notification title", body: "Notification body")

class PushNotificationSender {
    func sendPushNotification(to token: String, title: String, body: String) {
        let urlString = "https://fcm.googleapis.com/fcm/send"
        let url = NSURL(string: urlString)!
        let paramString: [String : Any] = ["to" : token,
                                           "notification" : ["title" : title, "body" : body, "sound": "default"],
                                           "data" : ["user" : "test_id"]
        ]
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=AAAAlUjddIc:APA91bHYud8X0WfFfbIfHgUQopBeuHM3PWp0oQqQwweiVyhM2FobdQfPO3mbuOoWrV-JrgYhjJhFY-oeK4vv1bllA9MOhlIt_mFJ5ynThXFmyTNqvirxT6-iglB2q1BjauYOFY5Mlx9D", forHTTPHeaderField: "Authorization")
        let task =  URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in
            do {
                if let jsonData = data {
                    if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                        NSLog("Received data:\n\(jsonDataDict))")
                    }
                }
            } catch let err as NSError {
                print(err.debugDescription)
            }
        }
        task.resume()
    }
}
