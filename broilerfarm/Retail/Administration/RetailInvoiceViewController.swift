//
//  RetailInvoiceViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 4/24/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import QuickLook

class RetailInvoiceViewController: UIViewController, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    
    var loginClass : String = ""
    var fullName : String = ""
    var purchaseOrder : RetailPurchaseOrder!

    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var invoiceNumberLabel: UILabel!
    @IBOutlet var customerNameLabel: UILabel!
    @IBOutlet var customerPhoneLabel: UILabel!
    @IBOutlet var customerAddressTextView: UITextView!
    @IBOutlet var deliveryZoneLabel: UILabel!
    @IBOutlet var deliverByLabel: UILabel!
    
    @IBOutlet var v1: UIView!
    @IBOutlet var v2: UIView!
    @IBOutlet var v3: UIView!
    @IBOutlet var v4: UIView!
    @IBOutlet var v5: UIView!
    @IBOutlet var v6: UIView!
    @IBOutlet var v7: UIView!
    @IBOutlet var v8: UIView!
    @IBOutlet var v9: UIView!
    @IBOutlet var v10: UIView!
    
    @IBOutlet var v1SubtotalLabel: UILabel!
    @IBOutlet var v1PricePerUnitLabel: UILabel!
    @IBOutlet var v1QuantityLabel: UILabel!
    @IBOutlet var v1ItemNameLabel: UILabel!
    
    @IBOutlet var v2SubtotalLabel: UILabel!
    @IBOutlet var v2PricePerUnitLabel: UILabel!
    @IBOutlet var v2QuantityLabel: UILabel!
    @IBOutlet var v2ItemNameLabel: UILabel!
    
    @IBOutlet var v3SubtotalLabel: UILabel!
    @IBOutlet var v3PricePerUnitLabel: UILabel!
    @IBOutlet var v3QuantityLabel: UILabel!
    @IBOutlet var v3ItemNameLabel: UILabel!
    
    @IBOutlet var v4SubtotalLabel: UILabel!
    @IBOutlet var v4PricePerUnitLabel: UILabel!
    @IBOutlet var v4QuantityLabel: UILabel!
    @IBOutlet var v4ItemNameLabel: UILabel!
    
    @IBOutlet var v5SubtotalLabel: UILabel!
    @IBOutlet var v5PricePerUnitLabel: UILabel!
    @IBOutlet var v5QuantityLabel: UILabel!
    @IBOutlet var v5ItemNameLabel: UILabel!
    
    @IBOutlet var v6SubtotalLabel: UILabel!
    @IBOutlet var v6PricePerUnitLabel: UILabel!
    @IBOutlet var v6QuantityLabel: UILabel!
    @IBOutlet var v6ItemNameLabel: UILabel!
    
    @IBOutlet var v7SubtotalLabel: UILabel!
    @IBOutlet var v7PricePerUnitLabel: UILabel!
    @IBOutlet var v7QuantityLabel: UILabel!
    @IBOutlet var v7ItemNameLabel: UILabel!
    
    @IBOutlet var v8SubtotalLabel: UILabel!
    @IBOutlet var v8PricePerUnitLabel: UILabel!
    @IBOutlet var v8QuantityLabel: UILabel!
    @IBOutlet var v8ItemNameLabel: UILabel!
    
    @IBOutlet var v9SubtotalLabel: UILabel!
    @IBOutlet var v9PricePerUnitLabel: UILabel!
    @IBOutlet var v9QuantityLabel: UILabel!
    @IBOutlet var v9ItemNameLabel: UILabel!
    
    @IBOutlet var v10SubtotalLabel: UILabel!
    @IBOutlet var v10PricePerUnitLabel: UILabel!
    @IBOutlet var v10QuantityLabel: UILabel!
    @IBOutlet var v10ItemNameLabel: UILabel!
    
    @IBOutlet var totalLabel: UILabel!
    @IBOutlet var preparedByLabel: UILabel!
    
    @IBOutlet var pdfView: UIView!
    
    @IBOutlet var discountLabel: UILabel!
    @IBOutlet var deliveryFeeLabel: UILabel!
    @IBOutlet var notesTextView: UITextView!
    @IBOutlet var paymentMethodLabel: UILabel!
    
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    var filePath : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let stringDate = dateFormatter.string(from: date)
        
        dateLabel.text = stringDate
        invoiceNumberLabel.text = purchaseOrder.purchaseOrderNumber
        customerNameLabel.text = purchaseOrder.deliveryContactName
        customerPhoneLabel.text = purchaseOrder.deliveryContactPhone
        customerAddressTextView.text = purchaseOrder.address
        deliveryZoneLabel.text = "Delivery Zone: \(purchaseOrder.deliveryZone)"
        
        let deliveryByDate = Date(timeIntervalSince1970: purchaseOrder.deliverByDate )
        let dateFormatter1 = DateFormatter()
        dateFormatter1.dateStyle = .medium
        let stringDeliveryByDate = dateFormatter1.string(from: deliveryByDate)
        deliverByLabel.text = "Deliver By: \(stringDeliveryByDate)"
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let formattedDeliveryFee = numberFormatter.string(from: NSNumber(value: purchaseOrder.deliveryFee))
        let formattedDiscount = numberFormatter.string(from: NSNumber(value: purchaseOrder.discount))
        deliveryFeeLabel.text = "Biaya Kirim: Rp. \(formattedDeliveryFee!)"
        discountLabel.text = "Discount: Rp. \(formattedDiscount!)"
        
        var notes : String = "Notes: "
        for i in 0..<purchaseOrder.realItemNotes.count {
            if purchaseOrder.realItemNotes[i] != "None" {
                notes.append("\(purchaseOrder.realItems[i].name) (\(purchaseOrder.realItemNotes[i]))")
                if i != purchaseOrder.realItemNotes.count - 1 {
                    notes.append(", ")
                }
            }
        }
        notesTextView.text = notes
        //Initialize Content Labels
        v1SubtotalLabel.text = ""
        v1PricePerUnitLabel.text = ""
        v1QuantityLabel.text = ""
        v1ItemNameLabel.text = ""
        v2SubtotalLabel.text = ""
        v2PricePerUnitLabel.text = ""
        v2QuantityLabel.text = ""
        v2ItemNameLabel.text = ""
        v3SubtotalLabel.text = ""
        v3PricePerUnitLabel.text = ""
        v3QuantityLabel.text = ""
        v3ItemNameLabel.text = ""
        v4SubtotalLabel.text = ""
        v4PricePerUnitLabel.text = ""
        v4QuantityLabel.text = ""
        v4ItemNameLabel.text = ""
        v5SubtotalLabel.text = ""
        v5PricePerUnitLabel.text = ""
        v5QuantityLabel.text = ""
        v5ItemNameLabel.text = ""
        v6SubtotalLabel.text = ""
        v6PricePerUnitLabel.text = ""
        v6QuantityLabel.text = ""
        v6ItemNameLabel.text = ""
        v7SubtotalLabel.text = ""
        v7PricePerUnitLabel.text = ""
        v7QuantityLabel.text = ""
        v7ItemNameLabel.text = ""
        v8SubtotalLabel.text = ""
        v8PricePerUnitLabel.text = ""
        v8QuantityLabel.text = ""
        v8ItemNameLabel.text = ""
        v9SubtotalLabel.text = ""
        v9PricePerUnitLabel.text = ""
        v9QuantityLabel.text = ""
        v9ItemNameLabel.text = ""
        v10SubtotalLabel.text = ""
        v10PricePerUnitLabel.text = ""
        v10QuantityLabel.text = ""
        v10ItemNameLabel.text = ""
        
        if purchaseOrder.paymentMethod != "" {
            paymentMethodLabel.text = "Payment: \(purchaseOrder.paymentMethod)"
        }
        else {
            paymentMethodLabel.text = ""
        }
        
        var subtotals : [Float] = [Float]()
        for i in 0..<purchaseOrder.realItems.count {
            subtotals.append((Float(purchaseOrder.realItems[i].pricePerUnit) * purchaseOrder.realItemQuantities[i]).rounded())
            switch i {
            case 0:
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .decimal
                let formattedPricePerUnit = numberFormatter.string(from: NSNumber(value:purchaseOrder.realItems[i].pricePerUnit))
                
                let subtotal = (Float(purchaseOrder.realItems[i].pricePerUnit) * purchaseOrder.realItemQuantities[i]).rounded()
                let formattedSubtotal = numberFormatter.string(from: NSNumber(value:subtotal))
                
                v1SubtotalLabel.text = "Rp. \(formattedSubtotal!)"
                v1PricePerUnitLabel.text = "Rp. \(formattedPricePerUnit!)/\(purchaseOrder.realItems[i].unit)"
                v1QuantityLabel.text = "\(String(format: "%.2f", purchaseOrder.realItemQuantities[i]))"
                v1ItemNameLabel.text = "\(purchaseOrder.realItems[i].name)"
            case 1:
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .decimal
                let formattedPricePerUnit = numberFormatter.string(from: NSNumber(value:purchaseOrder.realItems[i].pricePerUnit))
                
                let subtotal = (Float(purchaseOrder.realItems[i].pricePerUnit) * purchaseOrder.realItemQuantities[i]).rounded()
                let formattedSubtotal = numberFormatter.string(from: NSNumber(value:subtotal))
                
                v2SubtotalLabel.text = "Rp. \(formattedSubtotal!)"
                v2PricePerUnitLabel.text = "Rp. \(formattedPricePerUnit!)/\(purchaseOrder.realItems[i].unit)"
                v2QuantityLabel.text = "\(String(format: "%.2f", purchaseOrder.realItemQuantities[i]))"
                v2ItemNameLabel.text = "\(purchaseOrder.realItems[i].name)"
            case 2:
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .decimal
                let formattedPricePerUnit = numberFormatter.string(from: NSNumber(value:purchaseOrder.realItems[i].pricePerUnit))
                
                let subtotal = (Float(purchaseOrder.realItems[i].pricePerUnit) * purchaseOrder.realItemQuantities[i]).rounded()
                let formattedSubtotal = numberFormatter.string(from: NSNumber(value:subtotal))
                
                v3SubtotalLabel.text = "Rp. \(formattedSubtotal!)"
                v3PricePerUnitLabel.text = "Rp. \(formattedPricePerUnit!)/\(purchaseOrder.realItems[i].unit)"
                v3QuantityLabel.text = "\(String(format: "%.2f", purchaseOrder.realItemQuantities[i]))"
                v3ItemNameLabel.text = "\(purchaseOrder.realItems[i].name)"
            case 3:
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .decimal
                let formattedPricePerUnit = numberFormatter.string(from: NSNumber(value:purchaseOrder.realItems[i].pricePerUnit))
                
                let subtotal = (Float(purchaseOrder.realItems[i].pricePerUnit) * purchaseOrder.realItemQuantities[i]).rounded()
                let formattedSubtotal = numberFormatter.string(from: NSNumber(value:subtotal))
                
                v4SubtotalLabel.text = "Rp. \(formattedSubtotal!)"
                v4PricePerUnitLabel.text = "Rp. \(formattedPricePerUnit!)/\(purchaseOrder.realItems[i].unit)"
                v4QuantityLabel.text = "\(String(format: "%.2f", purchaseOrder.realItemQuantities[i]))"
                v4ItemNameLabel.text = "\(purchaseOrder.realItems[i].name)"
            case 4:
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .decimal
                let formattedPricePerUnit = numberFormatter.string(from: NSNumber(value:purchaseOrder.realItems[i].pricePerUnit))
                
                let subtotal = (Float(purchaseOrder.realItems[i].pricePerUnit) * purchaseOrder.realItemQuantities[i]).rounded()
                let formattedSubtotal = numberFormatter.string(from: NSNumber(value:subtotal))
                
                v5SubtotalLabel.text = "Rp. \(formattedSubtotal!)"
                v5PricePerUnitLabel.text = "Rp. \(formattedPricePerUnit!)/\(purchaseOrder.realItems[i].unit)"
                v5QuantityLabel.text = "\(String(format: "%.2f", purchaseOrder.realItemQuantities[i]))"
                v5ItemNameLabel.text = "\(purchaseOrder.realItems[i].name)"
            case 5:
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .decimal
                let formattedPricePerUnit = numberFormatter.string(from: NSNumber(value:purchaseOrder.realItems[i].pricePerUnit))
                
               let subtotal = (Float(purchaseOrder.realItems[i].pricePerUnit) * purchaseOrder.realItemQuantities[i]).rounded()
                let formattedSubtotal = numberFormatter.string(from: NSNumber(value:subtotal))
                
                v6SubtotalLabel.text = "Rp. \(formattedSubtotal!)"
                v6PricePerUnitLabel.text = "Rp. \(formattedPricePerUnit!)/\(purchaseOrder.realItems[i].unit)"
                v6QuantityLabel.text = "\(String(format: "%.2f", purchaseOrder.realItemQuantities[i]))"
                v6ItemNameLabel.text = "\(purchaseOrder.realItems[i].name)"
            case 6:
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .decimal
                let formattedPricePerUnit = numberFormatter.string(from: NSNumber(value:purchaseOrder.realItems[i].pricePerUnit))
                
                let subtotal = (Float(purchaseOrder.realItems[i].pricePerUnit) * purchaseOrder.realItemQuantities[i]).rounded()
                let formattedSubtotal = numberFormatter.string(from: NSNumber(value:subtotal))
                
                v7SubtotalLabel.text = "Rp. \(formattedSubtotal!)"
                v7PricePerUnitLabel.text = "Rp. \(formattedPricePerUnit!)/\(purchaseOrder.realItems[i].unit)"
                v7QuantityLabel.text = "\(String(format: "%.2f", purchaseOrder.realItemQuantities[i]))"
                v7ItemNameLabel.text = "\(purchaseOrder.realItems[i].name)"
            case 7:
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .decimal
                let formattedPricePerUnit = numberFormatter.string(from: NSNumber(value:purchaseOrder.realItems[i].pricePerUnit))
                
                let subtotal = (Float(purchaseOrder.realItems[i].pricePerUnit) * purchaseOrder.realItemQuantities[i]).rounded()
                let formattedSubtotal = numberFormatter.string(from: NSNumber(value:subtotal))
                
                v8SubtotalLabel.text = "Rp. \(formattedSubtotal!)"
                v8PricePerUnitLabel.text = "Rp. \(formattedPricePerUnit!)/\(purchaseOrder.realItems[i].unit)"
                v8QuantityLabel.text = "\(String(format: "%.2f", purchaseOrder.realItemQuantities[i]))"
                v8ItemNameLabel.text = "\(purchaseOrder.realItems[i].name)"
            case 8:
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .decimal
                let formattedPricePerUnit = numberFormatter.string(from: NSNumber(value:purchaseOrder.realItems[i].pricePerUnit))
                
                let subtotal = (Float(purchaseOrder.realItems[i].pricePerUnit) * purchaseOrder.realItemQuantities[i]).rounded()
                let formattedSubtotal = numberFormatter.string(from: NSNumber(value:subtotal))
                
                v9SubtotalLabel.text = "Rp. \(formattedSubtotal!)"
                v9PricePerUnitLabel.text = "Rp. \(formattedPricePerUnit!)/\(purchaseOrder.realItems[i].unit)"
                v9QuantityLabel.text = "\(String(format: "%.2f", purchaseOrder.realItemQuantities[i]))"
                v9ItemNameLabel.text = "\(purchaseOrder.realItems[i].name)"
            case 9:
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .decimal
                let formattedPricePerUnit = numberFormatter.string(from: NSNumber(value:purchaseOrder.realItems[i].pricePerUnit))
                
                let subtotal = (Float(purchaseOrder.realItems[i].pricePerUnit) * purchaseOrder.realItemQuantities[i]).rounded()
                let formattedSubtotal = numberFormatter.string(from: NSNumber(value:subtotal))
                
                v10SubtotalLabel.text = "Rp. \(formattedSubtotal!)"
                v10PricePerUnitLabel.text = "Rp. \(formattedPricePerUnit!)/\(purchaseOrder.realItems[i].unit)"
                v10QuantityLabel.text = "\(String(format: "%.2f", purchaseOrder.realItemQuantities[i]))"
                v10ItemNameLabel.text = "\(purchaseOrder.realItems[i].name)"
                
            default:
                print("Out of Bounds")
            }
            
            let total = Int(subtotals.reduce(0,+)) - purchaseOrder.discount + purchaseOrder.deliveryFee
            //Format Total
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            let formattedTotal = numberFormatter.string(from: NSNumber(value: total))
            
            totalLabel.text = "Total: Rp. \(formattedTotal!)"
            preparedByLabel.text = "Prepared By: \(purchaseOrder.preppedBy)"
        }
    }
    
    @IBAction func shareButtonPressed(_ sender: Any) {
        print("Share")
        createPDF()
    }
    
    func createPDF () {
        filePath = exportAsPdfFromView()
        let previewController = QLPreviewController()
        previewController.dataSource = self
        previewController.delegate = self
        present(previewController, animated: true)
    }
    
    // Export pdf from Save pdf in drectory and return pdf file path
    func exportAsPdfFromView() -> String {
        
        let pdfPageFrame = self.pdfView.bounds
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, pdfPageFrame, nil)
        UIGraphicsBeginPDFPageWithInfo(pdfPageFrame, nil)
        guard let pdfContext = UIGraphicsGetCurrentContext() else { return "" }
        self.pdfView.layer.render(in: pdfContext)
        UIGraphicsEndPDFContext()
        return self.saveViewPdf(data: pdfData)
        
    }
    
    // Save pdf file in document directory
    func saveViewPdf(data: NSMutableData) -> String {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docDirectoryPath = paths[0]
        let pdfPath = docDirectoryPath.appendingPathComponent("\(purchaseOrder.purchaseOrderNumber).pdf")
        if data.write(to: pdfPath, atomically: true) {
            return pdfPath.path
        } else {
            return ""
        }
    }
    
    //QLPreviewController Methods
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return URL(fileURLWithPath: filePath) as QLPreviewItem
    }
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        print("Preview Controller Dismissed")
    }
}
