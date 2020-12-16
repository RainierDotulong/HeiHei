//
//  QRCodeGenerator.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 3/19/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit

class QRCodeGenerator {
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            filter.setValue("M", forKey: "inputCorrectionLevel")
            let transform = CGAffineTransform(scaleX: 12, y: 12)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        return nil
    }
    
    func textToImage(drawText text: String, inImage image: UIImage, atPoint point: CGPoint) -> UIImage {
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(image.size, false, scale)
        
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
        
        let rect = CGRect(origin: point, size: image.size)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attrs = [NSAttributedString.Key.font: UIFont(name: "Helvetica Bold", size: 40)!,NSAttributedString.Key.foregroundColor : UIColor.black , NSAttributedString.Key.paragraphStyle: paragraphStyle]
        
        
        text.draw(with: rect, options: .usesLineFragmentOrigin, attributes: attrs, context: nil)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
