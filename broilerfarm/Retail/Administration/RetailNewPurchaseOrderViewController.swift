//
//  RetailNewPurchaseOrderViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 4/22/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import SVProgressHUD
import NotificationBannerSwift
import EmptyStateKit

class RetailNewPurchaseOrderTableViewCell : UITableViewCell {
    //RetailNewPurchaseOrderCell
    @IBOutlet var productNameLabel: UILabel!
    @IBOutlet var pricePerUnitLabel: UILabel!
    @IBOutlet var notesLabel: UILabel!
    @IBOutlet var quantityLabel: UILabel!
    @IBOutlet var qtyButton: UIButton!
    @IBOutlet var quantityStepper: UIStepper!
}

class RetailNewPurchaseOrderViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, EmptyStateDelegate, sendProductData, sendRetailCustomerData, sendPlaceData, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var loginClass : String = ""
    var fullName : String = ""
    
    var isNewPurchaseOrder : Bool = true
    var purchaseOrder : RetailPurchaseOrder!
    
    var retailCustomer : RetailCustomer!
    var orderedItems : [RetailProduct] = [RetailProduct]()
    var orderedItemNotes : [String] = [String]()
    var orderedItemQuantities : [Int] = [Int]()
    
    var deliverByTimestamp : Double = 0
    var paymentMethod : String = "Cash"
    var deliveryFee : Int = 0
    var discount : Int = 0
    
    // Retail Customer Details
    @IBOutlet var customerNameLabel: UILabel!
    @IBOutlet var customerAddressLabel: UILabel!
    @IBOutlet var customerPhoneLabel: UILabel!
    
    // Delivery Details
    @IBOutlet var deliveryNameTextField: UITextField!
    @IBOutlet var deliveryPhoneTextField: UITextField!
    @IBOutlet var deliveryAddressTextField: UITextField!
    @IBOutlet var deliveryLatitudeTextField: UITextField!
    @IBOutlet var deliveryLongitudeTextField: UITextField!
    @IBOutlet var deliverByLabel: UILabel!
    @IBOutlet var paymentMethodLabel: UILabel!
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var orderTotalLabel: UILabel!
    @IBOutlet var createButton: UIButton!
    
    @IBOutlet var navItem: UINavigationItem!
    
    @IBOutlet var discountButton: UIButton!
    @IBOutlet var deliveryFeeButton: UIButton!
    
    var pickerData : [String] = ["Cash","Transfer"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if loginClass == "superadmin" {
            discountButton.isEnabled = true
        }
        else {
            discountButton.isEnabled = false
        }
        //Add Done Button on keboard
        addDoneButtonOnKeyboard()
        
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        if isNewPurchaseOrder == false {
            var savedRetailCustomer : RetailCustomer = RetailCustomer(name: "", address: "", phone: "", marketing: "", fullAddress: "", latitude: 0, longitude: 0, createdBy: "", timestamp: 0)
            savedRetailCustomer.name = purchaseOrder.name
            savedRetailCustomer.address = purchaseOrder.address
            savedRetailCustomer.phone = purchaseOrder.phone
            savedRetailCustomer.marketing = purchaseOrder.marketing
            retailCustomer = savedRetailCustomer
            customerNameLabel.text = purchaseOrder.name
            customerAddressLabel.text = purchaseOrder.address
            customerPhoneLabel.text = purchaseOrder.phone
            deliveryNameTextField.text = purchaseOrder.deliveryContactName
            deliveryPhoneTextField.text = purchaseOrder.deliveryContactPhone
            deliveryAddressTextField.text = purchaseOrder.deliveryAddress
            deliveryLatitudeTextField.text = String(purchaseOrder.deliveryLatitude)
            deliveryLongitudeTextField.text = String(purchaseOrder.deliveryLongitude)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            let stringDate = dateFormatter.string(from: Date(timeIntervalSince1970: purchaseOrder.deliverByDate))
            deliverByLabel.text = "Deliver By: \(stringDate)"
            deliverByTimestamp = purchaseOrder.deliverByDate
            paymentMethodLabel.text = "Payment: \(purchaseOrder.paymentMethod)"
            orderedItems = purchaseOrder.orderedItems
            orderedItemNotes = purchaseOrder.orderedItemNotes
            orderedItemQuantities = purchaseOrder.orderedItemQuantities
            
            updateTotalLabel()
            
            navItem.title = "Update P.O."
            createButton.setTitle(" Update", for: .normal)
        }
        else {
            navItem.title = "New P.O."
            createButton.setTitle(" Create", for: .normal)
        }
                
        self.tableView.emptyState.delegate = self
        self.tableView.emptyState.format.imageSize = CGSize(width: 100, height: 100)
        self.tableView.emptyState.format.verticalMargin = 10
        
        // Remove seperator lines from empty cells
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        self.tableView.reloadData()
        self.reloadEmptyStateKit(state: "noList")
    }
    
    func emptyState(emptyState: EmptyState, didPressButton button: UIButton) {
        self.performSegue(withIdentifier: "goToProducts", sender: self)
    }
    
    func placeDataReceived(address: String, latitude: String, longitude: String) {
        deliveryAddressTextField.text = address
        deliveryLatitudeTextField.text = latitude
        deliveryLongitudeTextField.text = longitude
    }
    
    func productDataReceived(product: RetailProduct) {
        var newProduct : Bool = true
        for i in 0..<orderedItems.count {
            if orderedItems[i].name == product.name {
                print("Product Already Added")
                newProduct = false
                orderedItemQuantities[i] += 1
                updateTotalLabel()
                self.tableView.reloadData()
                self.reloadEmptyStateKit(state: "noList")
            }
        }
        if newProduct {
            orderedItems.append(product)
            orderedItemNotes.append("None")
            orderedItemQuantities.append(1)
            updateTotalLabel()
            self.tableView.reloadData()
            self.reloadEmptyStateKit(state: "noList")
        }
    }
    
    func retailCustomerDataReceived(customer: RetailCustomer) {
        retailCustomer = customer
        customerNameLabel.text = "\(customer.name)"
        customerAddressLabel.text = "Address: \(customer.address)"
        customerPhoneLabel.text = "Phone: \(customer.phone)"
        
        deliveryNameTextField.text = customer.name
        deliveryPhoneTextField.text = customer.phone
        deliveryAddressTextField.text = customer.fullAddress
        if customer.latitude != 0 && customer.longitude != 0 {
            deliveryLatitudeTextField.text = String(customer.latitude)
            deliveryLongitudeTextField.text = String(customer.longitude)
        }
        else {
            deliveryLatitudeTextField.text = ""
            deliveryLongitudeTextField.text = ""
        }
    }
    
    @IBAction func addProductButtonPressed(_ sender: Any) {
        print("Add Product")
        self.performSegue(withIdentifier: "goToProducts", sender: self)
    }
    @IBAction func customerDetailsViewTapped(_ sender: Any) {
        print("Customer Details")
        self.performSegue(withIdentifier: "goToCustomers", sender: self)
    }
    @IBAction func mapsButonPressed(_ sender: Any) {
        print("Maps")
        self.performSegue(withIdentifier: "goToGoogleMaps", sender: self)
    }
    @IBAction func deliverByLabelTapped(_ sender: Any) {
        print("Deliver By")
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        
        let alert = UIAlertController(title: "\n\n\n\n\n\n\n\n\n\n\n", message: nil, preferredStyle: .actionSheet)
        alert.view.addSubview(datePicker)
        
        datePicker.snp.makeConstraints { (make) in
            make.centerX.equalTo(alert.view)
            make.top.equalTo(alert.view).offset(8)
        }
        
        let ok = UIAlertAction(title: "OK", style: .default) { (action) in
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            let stringDate = dateFormatter.string(from: datePicker.date)
            self.deliverByLabel.text = "Deliver By: \(stringDate)"
            self.deliverByTimestamp = datePicker.date.timeIntervalSince1970
            self.tableView.reloadData()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        alert.addAction(ok)
        alert.addAction(cancel)
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
        alert.popoverPresentationController?.permittedArrowDirections = []
        present(alert, animated: true, completion: nil)
    }
    @IBAction func paymentMethodLabelTapped(_ sender: Any) {
        print("Payment Method")
        paymentMethod = "Cash"
        paymentMethodLabel.text = "Payment: Cash"
        let vc = UIViewController()
        vc.preferredContentSize = CGSize(width: 250,height: 100)
        let pickerView = UIPickerView(frame: CGRect(x: 0, y: 0, width: 250, height: 100))
        pickerView.delegate = self
        pickerView.dataSource = self
        vc.view.addSubview(pickerView)
        let paymentMethodAlert = UIAlertController(title: "Choose Payment Method", message: "", preferredStyle: UIAlertController.Style.alert)
        paymentMethodAlert.setValue(vc, forKey: "contentViewController")
        paymentMethodAlert.addAction(UIAlertAction(title: "Done", style: .default, handler: nil))
        self.present(paymentMethodAlert, animated: true)
    }
    @IBAction func quantityStepperValueChanged(_ sender: UIStepper) {
        orderedItemQuantities[sender.tag] = Int(sender.value)
        updateTotalLabel()
        tableView.reloadData()
    }
    @IBAction func quantityButtonTapped(_ sender: UIButton) {
        print(sender.tag)
        let alert = UIAlertController(title: "Specify Quantity", message: "", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "200"
            textField.keyboardType = .numberPad
        }
        
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            let textField = alert.textFields![0]
            print(textField.text ?? "")
            guard textField.text ?? "" != "" else {
                print("Incomplete Data")
                let dialogMessage = UIAlertController(title: "Incomplete Data", message: "Text Field Empty", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            guard Int(textField.text ?? "") ?? 0 != 0 else {
                print("Invalid Data")
                let dialogMessage = UIAlertController(title: "Invalid Data", message: "Non integer value specified", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            self.orderedItemQuantities[sender.tag] = Int(textField.text ?? "0") ?? 0
            self.updateTotalLabel()
            self.tableView.reloadData()
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            print("Cancel button tapped")
        }
        
        alert.addAction(ok)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    @IBAction func discountButtonPressed(_ sender: Any) {
        print("Discount Button Pressed")
        let alert = UIAlertController(title: "Specify Discount (Rp.)", message: "", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "10000"
            textField.keyboardType = .numberPad
        }
        
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            let textField = alert.textFields![0]
            print(textField.text ?? "")
            guard textField.text ?? "" != "" else {
                print("Incomplete Data")
                let dialogMessage = UIAlertController(title: "Incomplete Data", message: "Text Field Empty", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            guard Int(textField.text ?? "") ?? 0 != 0 else {
                print("Discount not Integer value")
                //Declare Alert message
                let dialogMessage = UIAlertController(title: "Invalid Discount", message: "Delivery Fee is non-integer value.", preferredStyle: .alert)
                // Create OK button with action handler
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                //Add OK and Cancel button to dialog message
                dialogMessage.addAction(ok)
                // Present dialog message to user
                self.present(dialogMessage, animated: true, completion: nil)

                return
            }
            print("Set Discount")
            //Format Total
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            let formattedDiscount = numberFormatter.string(from: NSNumber(value: Int(textField.text ?? "")!))
            self.discountButton.setTitle("Discount: Rp.\(formattedDiscount!)", for: .normal)
            self.discount = Int(textField.text ?? "0")!
            self.updateTotalLabel()
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            print("Cancel button tapped")
        }
        
        alert.addAction(ok)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func ongkirButtonPressed(_ sender: Any) {
        print("Ongkir Button Pressed")
        let alert = UIAlertController(title: "Specify Delivery Fee (Rp)", message: "", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "100000"
            textField.keyboardType = .numberPad
        }
        
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            let textField = alert.textFields![0]
            print(textField.text ?? "")
            guard textField.text ?? "" != "" else {
                print("Incomplete Data")
                let dialogMessage = UIAlertController(title: "Incomplete Data", message: "Text Field Empty", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            guard Int(textField.text ?? "") ?? 0 != 0 else {
                print("Delivery Fee not Int value")
                //Declare Alert message
                let dialogMessage = UIAlertController(title: "Invalid Delivery Fee", message: "Delivery Fee is non-integer value.", preferredStyle: .alert)
                // Create OK button with action handler
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                //Add OK and Cancel button to dialog message
                dialogMessage.addAction(ok)
                // Present dialog message to user
                self.present(dialogMessage, animated: true, completion: nil)

                return
            }
            print("Set Delivery Fee")
            //Format Total
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            let formattedDeliveryFee = numberFormatter.string(from: NSNumber(value: Int(textField.text ?? "")!))
            self.deliveryFeeButton.setTitle("Ongkir: Rp. \(formattedDeliveryFee!)", for: .normal)
            self.deliveryFee = Int(textField.text ?? "0")!
            self.updateTotalLabel()
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            print("Cancel button tapped")
        }
        
        alert.addAction(ok)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func createButtonPressed(_ sender: Any) {
        //Guard for missing Datas
        guard retailCustomer != nil else {
            print("Please Choose or create Customer for this Purchase Order")
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Customer Data Missing!", message: "Please choose or create Customer for this purchase order by tapping on customer details pane.", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)

            return
        }
        guard deliveryNameTextField.text ?? "" != "" else {
            print("Delivery Name Text Field Empty")
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Delivery Contact Name Text Field Empty!", message: "", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)

            return
        }
        guard deliveryPhoneTextField.text ?? "" != "" else {
            print("Delivery Phone Text Field Empty")
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Delivery Contact Phone Text Field Empty!", message: "", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)

            return
        }
        guard deliveryAddressTextField.text ?? "" != "" else {
            print("Delivery Address Text Field Empty")
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Delivery Address Text Field Empty!", message: "", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)

            return
        }
        guard Double(deliveryLatitudeTextField.text ?? "") ?? 0 != 0 else {
            print("Latitude not Double value")
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Invalid Delivery Latitude", message: "Latitude is non-numerical (Double value required).", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)

            return
        }
        guard Double(deliveryLongitudeTextField.text ?? "") ?? 0 != 0 else {
            print("Longitude not Double value")
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Invalid Delivery Longitude", message: "Longitude is non-numerical (Double value required).", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)

            return
        }
        guard deliverByTimestamp != 0 else {
            print("Deliver By Timestamp Empty")
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Delivery Date Empty!", message: "Please choose delivery date by tapping on Deliver By Label", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)

            return
        }
        guard orderedItems.isEmpty == false else {
            print("No Items in Purchase Order")
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "No Items in Purchase Order!", message: "Add Items to purchase order using the top right bar button.", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)

            return
        }
        guard paymentMethod != "" else {
            print("Payment Method Unspecified")
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Payment Method Unspecified!", message: "Tap on payment method label to select a payment method.", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)

            return
        }
        //Declare Alert message
        let dialogMessage = UIAlertController(title: "Confirm", message: "Are you sure you want to Create this Purchase Order?", preferredStyle: .alert)
        // Create OK button with action handler
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            //Update Customer Full Address and Coordinates
            self.updateCustomerData(name: self.retailCustomer.name, fullAddress: self.deliveryAddressTextField.text!, latitude: Double(self.deliveryLatitudeTextField.text!)!, longitude: Double(self.deliveryLongitudeTextField.text!)!)
            //Call Create Purchase Order
            var retailProductNames : [String] = [String]()
            var retailProductDescriptions : [String] = [String]()
            var retailProductPricePerUnits : [Int] = [Int]()
            var retailProductUnits : [String] = [String]()
            var retailProductCreatedBys : [String] = [String]()
            var retailProductTimestamps : [Double] = [Double]()
            
            for orderedItem in self.orderedItems {
                retailProductNames.append(orderedItem.name)
                retailProductDescriptions.append(orderedItem.description)
                retailProductPricePerUnits.append(orderedItem.pricePerUnit)
                retailProductUnits.append(orderedItem.unit)
                retailProductCreatedBys.append(orderedItem.createdBy)
                retailProductTimestamps.append(orderedItem.timestamp)
            }
            self.createPurchaseOrder(name: self.retailCustomer.name,
                                     address: self.retailCustomer.address,
                                     phone: self.retailCustomer.phone,
                                     marketing: self.retailCustomer.marketing,
                                     deliveryContactName: self.deliveryNameTextField.text!,
                                     deliveryContactPhone: self.deliveryPhoneTextField.text!,
                                     deliveryAddress: self.deliveryAddressTextField.text!,
                                     deliveryLatitude: Double(self.deliveryLatitudeTextField.text!)!,
                                     deliveryLongitude: Double(self.deliveryLongitudeTextField.text!)!,
                                     deliverByDate: self.deliverByTimestamp,
                                     paymentMethod: self.paymentMethod,
                                     itemNotes: self.orderedItemNotes,
                                     itemQuantities: self.orderedItemQuantities,
                                     retailProductNames: retailProductNames,
                                     retailProductDescriptions: retailProductDescriptions,
                                     retailProductPricePerUnits: retailProductPricePerUnits,
                                     retailProductUnits: retailProductUnits,
                                     retailProductCreatedBys: retailProductCreatedBys,
                                     retailProductTimestamps: retailProductTimestamps)
        })
        // Create Cancel button with action handlder
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            print("Cancel button tapped")
        }
        //Add OK and Cancel button to dialog message
        dialogMessage.addAction(ok)
        dialogMessage.addAction(cancel)
        // Present dialog message to user
        self.present(dialogMessage, animated: true, completion: nil)
    }
    
    func createPurchaseOrder (name : String, address : String, phone : String, marketing : String, deliveryContactName : String, deliveryContactPhone : String, deliveryAddress : String, deliveryLatitude : Double, deliveryLongitude : Double, deliverByDate : Double, paymentMethod : String, itemNotes : [String], itemQuantities : [Int], retailProductNames : [String], retailProductDescriptions : [String], retailProductPricePerUnits : [Int], retailProductUnits : [String], retailProductCreatedBys : [String], retailProductTimestamps : [Double]) {
        print("Create/Update Purchase Order")
        createButton.isEnabled = false
        //Exception when updating
        var purchaseOrderNumber : String
        if isNewPurchaseOrder {
            purchaseOrderNumber = "RPO-\(Int(NSDate().timeIntervalSince1970))"
        }
        else {
            purchaseOrderNumber = purchaseOrder.purchaseOrderNumber
        }
        let doc = Firestore.firestore().collection("retailPurchaseOrders").document(purchaseOrderNumber)
        doc.setData([
            "name" : name,
            "address" : address,
            "phone" : phone,
            "marketing" : marketing,
            "deliveryContactName" : deliveryContactName,
            "deliveryContactPhone" : deliveryContactPhone,
            "deliveryAddress" : deliveryAddress,
            "deliveryLatitude" : deliveryLatitude,
            "deliveryLongitude" : deliveryLongitude,
            "deliverByDate" : deliverByDate,
            "paymentMethod" : paymentMethod,
            
            //RetailProduct
            "retailProductNames" : retailProductNames,
            "retailProductDescriptions" : retailProductDescriptions,
            "retailProductPricePerUnits" : retailProductPricePerUnits,
            "retailProductUnits" : retailProductUnits,
            "retailProductCreatedBys" : retailProductCreatedBys,
            "retailProductTimestamps" : retailProductTimestamps,
            
            "orderedItemNotes" : orderedItemNotes,
            "orderedItemQuantities" : orderedItemQuantities,
            "status" : "Created",
            "discount" : discount,
            "deliveryFee" : deliveryFee,
            "createdBy" : fullName,
            "timestamp" : NSDate().timeIntervalSince1970
        ]) { err in
            if let err = err {
                print("Error writing new product document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error writing New Purchase Order Document", style: .danger)
                banner.show()
                self.createButton.isEnabled = true
            } else {
                print("Purchase Order successfully Created!")
                //Post Notification for finished purchase order creation
                let PurchaseOrderCreationNotification = Notification.Name("purchaseOrderCreated")
                NotificationCenter.default.post(name: PurchaseOrderCreationNotification, object: nil)
                let banner = StatusBarNotificationBanner(title: "Purchase Order Successfully Created!", style: .success)
                banner.show()
                self.createButton.isEnabled = true
                
                //Send Telegram Message for PO Creation/Update
                var telegramText : String = ""
                if self.isNewPurchaseOrder {
                    telegramText = "*PO CREATED*\n----------------------------\nPO Number: \(purchaseOrderNumber)\nName: \(name)\nAddress: \(address)\nDeliver To: \(deliveryContactName) - \(deliveryContactPhone)\nMarketing: \(marketing)\nCreated By: \(self.fullName)\nCONTENTS:\n"
                }
                else {
                    telegramText = "*PO UPDATED*\n----------------------------\nPO Number: \(purchaseOrderNumber)\nName: \(name)\nAddress: \(address)\nDeliver To: \(deliveryContactName) - \(deliveryContactPhone)\nMarketing: \(marketing)\nCreated By: \(self.fullName)\nCONTENTS:\n"
                }
                
                for i in 0..<retailProductNames.count {
                    telegramText.append("_\(retailProductNames[i]) -- \(self.orderedItemQuantities[i]) \(retailProductUnits[i])_\n")
                }
                telegramText.append("Payment: \(paymentMethod)")
                Telegram().postTelegramMessage(botToken: Telegram().ChickenAppBotToken, chatID: Telegram().HeiHeiRetailChatID, text: telegramText, parse_mode: "Markdown")
                
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func updateCustomerData (name: String, fullAddress : String, latitude : Double, longitude : Double) {
        print("Update Customer Data")
        let doc = Firestore.firestore().collection("retailCustomers").document(name)
        doc.updateData([
            "fullAddress" : fullAddress,
            "latitude" : latitude,
            "longitude" : longitude,
            "timestamp" : NSDate().timeIntervalSince1970
        ]) { err in
            if let err = err {
                print("Error writing new product document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error Updating Customer Document", style: .danger)
                banner.show()
                self.createButton.isEnabled = true
            } else {
                print("Customer Data successfully updated!")
            }
        }
    }
    
    func updateTotalLabel() {
        var subtotals : [Int] = [Int]()
        for i in 0..<orderedItems.count {
            let subtotal = orderedItems[i].pricePerUnit * orderedItemQuantities[i]
            subtotals.append(subtotal)
        }
        let total = subtotals.reduce(0,+) - discount + deliveryFee
        //Format Total
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let formattedTotal = numberFormatter.string(from: NSNumber(value: total))
        
        orderTotalLabel.text = "Total: Rp. \(formattedTotal!)"
    }
    
    //MARK: Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orderedItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        func createSelectedItemCells(data : RetailProduct, note: String, quantity: Int, index : Int) -> RetailNewPurchaseOrderTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RetailNewPurchaseOrderCell", for: indexPath) as! RetailNewPurchaseOrderTableViewCell
            
            //Format Price
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            let formattedPrice = numberFormatter.string(from: NSNumber(value:Float(data.pricePerUnit)))
            
            cell.productNameLabel.text = data.name
            cell.pricePerUnitLabel.text = "Rp. \(formattedPrice!)/\(data.unit)"
            cell.notesLabel.text = "Notes: \(note)"
            cell.quantityLabel.text = "Qty. \(quantity)"
            cell.qtyButton.tag = index
            cell.quantityStepper.tag = index
            cell.quantityStepper.value = Double(quantity)
            cell.quantityStepper.minimumValue = 1
            
            return cell
        }
        
        return createSelectedItemCells(data: orderedItems[indexPath.row],note: orderedItemNotes[indexPath.row],quantity: orderedItemQuantities[indexPath.row], index: indexPath.row)
    }
    
    //MARK: Table Cell Button Actions
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let delete = UIContextualAction(style: .normal, title: "Delete") {  (contextualAction, view, boolValue) in
            
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Confirm", message: "Are you sure you want to Delete this Product?", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
                self.orderedItems.remove(at: indexPath.row)
                self.orderedItemNotes.remove(at: indexPath.row)
                self.orderedItemQuantities.remove(at: indexPath.row)
                self.tableView.reloadData()
                self.reloadEmptyStateKit(state: "noList")
            })
            // Create Cancel button with action handlder
            let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
                print("Cancel button tapped")
            }
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            dialogMessage.addAction(cancel)
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)
        }
        
        delete.image = UIImage(systemName: "trash")
        delete.backgroundColor = .systemRed
        
        return UISwipeActionsConfiguration(actions: [delete])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(orderedItems[indexPath.row].name)
        let alert = UIAlertController(title: "Add Note to Item", message: "", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Range 900 Gram"
            textField.keyboardType = .default
            textField.autocapitalizationType = .words
        }
        
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            let textField = alert.textFields![0]
            print(textField.text ?? "")
            guard textField.text ?? "" != "" else {
                print("Incomplete Data")
                let dialogMessage = UIAlertController(title: "Incomplete Data", message: "Text Field Empty", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            self.orderedItemNotes[indexPath.row] = textField.text ?? "None"
            self.tableView.reloadData()
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            print("Cancel button tapped")
        }
        
        alert.addAction(ok)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    //Add Done Button on Keyboard
    func addDoneButtonOnKeyboard(){
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))
        
        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        deliveryNameTextField.inputAccessoryView = doneToolbar
        deliveryPhoneTextField.inputAccessoryView = doneToolbar
        deliveryAddressTextField.inputAccessoryView = doneToolbar
        deliveryLatitudeTextField.inputAccessoryView = doneToolbar
        deliveryLongitudeTextField.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction(){
        deliveryNameTextField.resignFirstResponder()
        deliveryPhoneTextField.resignFirstResponder()
        deliveryAddressTextField.resignFirstResponder()
        deliveryLatitudeTextField.resignFirstResponder()
        deliveryLongitudeTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        deliveryNameTextField.resignFirstResponder()
        deliveryPhoneTextField.resignFirstResponder()
        deliveryAddressTextField.resignFirstResponder()
        deliveryLatitudeTextField.resignFirstResponder()
        deliveryLongitudeTextField.resignFirstResponder()
        return true
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print(pickerData[row])
        paymentMethod = pickerData[row]
        paymentMethodLabel.text = "Payment: \(pickerData[row])"
    }
    
    func reloadEmptyStateKit(state: String) {
        if self.orderedItems.isEmpty {
            switch state{
            case "noList":
                self.tableView.emptyState.show(State.noList)
            case "noSearch":
                self.tableView.emptyState.show(State.noSearch)
            default:
                self.tableView.emptyState.show(State.noInternet)
            }
        }
        else {
            self.tableView.emptyState.hide()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is RetailCustomersTableViewController
        {
            let vc = segue.destination as? RetailCustomersTableViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.previousMenu = "New Purchase Order"
            vc?.delegate = self
        }
        else if segue.destination is RetailProductsTableViewController
        {
            let vc = segue.destination as? RetailProductsTableViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.previousMenu = "New Purchase Order"
            vc?.delegate = self
        }
        else if segue.destination is GoogleMapsViewController
        {
            let vc = segue.destination as? GoogleMapsViewController
            vc?.fullName = fullName
            vc?.loginClass = loginClass
            vc?.previousMenu = "New Purchase Order"
            vc?.delegate = self
        }
    }
}
