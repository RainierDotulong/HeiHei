//
//  StartCycleFloorDetailViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/11/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit

protocol sendFloorDataToStartCycleVC {
    func floorDataReceived(floorData : floorData)
}

class StartCycleFloorDetailViewController: UIViewController, UITextFieldDelegate {
    
    var selectedData : floorData = floorData(lantai: 99999, pakanAwal: 99999, startTimestamp: 99999, startingBodyWeight: 99999, startingPopulation: 99999, claimAge: 99999, claimQuantity: 99999, harvestedQuantity: 99999, harvestedWeight: 99999)
    var delegate : sendFloorDataToStartCycleVC?
    
    @IBOutlet var navItem: UINavigationItem!
    
    @IBOutlet var bwAwalTextField: UITextField!
    @IBOutlet var umurClaimTextField: UITextField!
    @IBOutlet var jumlahClaimTextField: UITextField!
    @IBOutlet var jumlahPanenTextField: UITextField!
    @IBOutlet var beratPanenTextField: UITextField!
    @IBOutlet var pakanAwalTextField: UITextField!
    @IBOutlet var populasiAwalTextField: UITextField!
    @IBOutlet var tanggalMulaiButton: UIButton!
    
    @IBOutlet var finishButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        //Add Done Button
        self.addDoneButtonOnKeyboard()
        
        navItem.title = "Lantai \(selectedData.lantai)"
        
        if selectedData.startingBodyWeight != 99999 {
            bwAwalTextField.text = "\(selectedData.startingBodyWeight)"
        }
        
        if selectedData.claimQuantity != 99999 {
            jumlahClaimTextField.text = "\(selectedData.claimQuantity)"
        }
        
        if selectedData.claimAge != 99999 {
            umurClaimTextField.text = "\(selectedData.claimAge)"
        }
        
        if selectedData.harvestedQuantity != 99999 {
            jumlahPanenTextField.text = "\(selectedData.harvestedQuantity)"
        }
        
        if selectedData.harvestedWeight != 99999 {
            beratPanenTextField.text = "\(selectedData.harvestedWeight)"
        }
        
        if selectedData.startingPopulation != 99999 {
            populasiAwalTextField.text = "\(selectedData.startingPopulation)"
        }
        
        if selectedData.pakanAwal != 99999 {
            pakanAwalTextField.text = "\(selectedData.pakanAwal)"
        }
        
        if selectedData.startTimestamp != 99999 {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: Date(timeIntervalSince1970: selectedData.startTimestamp))
            
            self.tanggalMulaiButton.setTitle(" \(stringDate)", for: .normal)
            self.tanggalMulaiButton.setTitleColor(.black, for: .normal)
            self.tanggalMulaiButton.tintColor = .black
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }

    @IBAction func tanggalMulaiButtonPressed(_ sender: Any) {
        print("Tanggal Mulai")
        let datePicker = UIDatePicker()
        if selectedData.startTimestamp != 99999 {
            datePicker.date = Date(timeIntervalSince1970: selectedData.startTimestamp)
        }
        let alert = UIAlertController(title: "\n\n\n\n\n\n\n\n\n\n\n", message: nil, preferredStyle: .actionSheet)
        alert.view.addSubview(datePicker)
        
        datePicker.snp.makeConstraints { (make) in
            make.centerX.equalTo(alert.view)
            make.top.equalTo(alert.view).offset(8)
        }
        
        let ok = UIAlertAction(title: "OK", style: .default) { (action) in
            self.selectedData.startTimestamp = datePicker.date.timeIntervalSince1970
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: datePicker.date)
            
            self.tanggalMulaiButton.setTitle(" \(stringDate)", for: .normal)
            self.tanggalMulaiButton.setTitleColor(.black, for: .normal)
            self.tanggalMulaiButton.tintColor = .black
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        alert.addAction(ok)
        alert.addAction(cancel)
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
        alert.popoverPresentationController?.permittedArrowDirections = []
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func finishButtonPressed(_ sender: Any) {
        print("Finish")
        guard Float(bwAwalTextField.text?.replacingOccurrences(of: ",", with: ".") ?? "99999") ?? 99999 != 99999 else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Invalid BW Awal", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard Int(umurClaimTextField.text ?? "99999") ?? 99999 != 99999 else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Invalid Umur Claim", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard Int(jumlahClaimTextField.text ?? "99999") ?? 99999 != 99999 else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Invalid Jumlah Claim", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard Int(jumlahPanenTextField.text ?? "99999") ?? 99999 != 99999 else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Invalid Jumlah Panen", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard Float(beratPanenTextField.text?.replacingOccurrences(of: ",", with: ".") ?? "99999") ?? 99999 != 99999 else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Invalid Berat Panen", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard Int(pakanAwalTextField.text ?? "99999") ?? 99999 != 99999 else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Invalid Pakan Awal", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard Int(populasiAwalTextField.text ?? "99999") ?? 99999 != 99999 else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Invalid BW Awal", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard selectedData.startTimestamp != 99999 else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Invalid Tanggal Mulai", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        selectedData.startingBodyWeight = Float(bwAwalTextField.text!.replacingOccurrences(of: ",", with: "."))!
        selectedData.claimAge = Int(umurClaimTextField.text!)!
        selectedData.claimQuantity = Int(jumlahClaimTextField.text!)!
        selectedData.harvestedWeight = Float(beratPanenTextField.text!.replacingOccurrences(of: ",", with: "."))!
        selectedData.harvestedQuantity = Int(jumlahPanenTextField.text!)!
        selectedData.pakanAwal = Int(pakanAwalTextField.text!)!
        selectedData.startingPopulation = Int(populasiAwalTextField.text!)!
        
        self.delegate?.floorDataReceived(floorData: selectedData)
        self.navigationController?.popViewController(animated: true)
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
        
        bwAwalTextField.inputAccessoryView = doneToolbar
        pakanAwalTextField.inputAccessoryView = doneToolbar
        populasiAwalTextField.inputAccessoryView = doneToolbar
        umurClaimTextField.inputAccessoryView = doneToolbar
        jumlahClaimTextField.inputAccessoryView = doneToolbar
        jumlahPanenTextField.inputAccessoryView = doneToolbar
        beratPanenTextField.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction(){
        bwAwalTextField.resignFirstResponder()
        pakanAwalTextField.resignFirstResponder()
        populasiAwalTextField.resignFirstResponder()
        umurClaimTextField.resignFirstResponder()
        jumlahClaimTextField.resignFirstResponder()
        jumlahPanenTextField.resignFirstResponder()
        beratPanenTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        bwAwalTextField.resignFirstResponder()
        pakanAwalTextField.resignFirstResponder()
        populasiAwalTextField.resignFirstResponder()
        umurClaimTextField.resignFirstResponder()
        jumlahClaimTextField.resignFirstResponder()
        jumlahPanenTextField.resignFirstResponder()
        beratPanenTextField.resignFirstResponder()
        return true
    }
}
