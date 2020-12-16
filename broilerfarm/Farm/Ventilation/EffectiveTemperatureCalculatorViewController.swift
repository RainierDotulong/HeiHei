//
//  EffectiveTemperatureCalculatorViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 10/15/19.
//  Copyright © 2019 Troy Dotulong. All rights reserved.
//

import UIKit
import TextFieldEffects

class EffectiveTemperatureCalculatorViewController : UIViewController, UITextFieldDelegate {
    
    @IBOutlet var temperatureTextField: AkiraTextField!
    @IBOutlet var humidityTextField: AkiraTextField!
    @IBOutlet var windSpeedTextField: AkiraTextField!
    
    @IBOutlet var dryBulbTemperatureLabel: UILabel!
    @IBOutlet var dewPointTemperatureLabel: UILabel!
    @IBOutlet var wetBulbTemperatureLabel: UILabel!
    @IBOutlet var effectiveTemperatureLabel: UILabel!
    @IBOutlet var windSpeedLabel: UILabel!
    
    override func viewDidLoad() {
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        //Add Done button on Keyboards
        temperatureTextField.delegate = self
        humidityTextField.delegate = self
        windSpeedTextField.delegate = self
        addDoneButtonOnKeyboard()
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    @IBAction func calculateButtonPressed(_ sender: Any) {
        if temperatureTextField.text != "" && humidityTextField.text != "" && windSpeedTextField.text != "" {
            let dryBulbTemp = Float(temperatureTextField.text!)!
            let humidity = Float(humidityTextField.text!)!
            let windSpeed = Float(windSpeedTextField.text!)! / 196.85
            windSpeedLabel.text = "Wind Speed: " + String(format: "%.1f", windSpeed) + " m/s"
            calculateEffectiveTemperature(dryBulbTemperature: dryBulbTemp, humidity: humidity, windSpeed: windSpeed)
        }
        else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Incomplete Data", message: "Please Complete Input Data", preferredStyle: .alert)
            // Create OK button with action handler
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)
        }
    }
    func calculateEffectiveTemperature (dryBulbTemperature : Float, humidity : Float, windSpeed : Float) {
        
        let dewPointTemperature = dryBulbTemperature - ((100 - humidity) / 5)
        let wetBulbTemperature = dryBulbTemperature - ((dryBulbTemperature - dewPointTemperature) / 3)
        
        //Effective Temperature Constants & Calculation
        let c : Float = 0.7
        let d : Float = 43
        let e : Float = 0.5
        let effectiveTemperature1 = 0.794 * dryBulbTemperature + 0.25 * wetBulbTemperature + 0.70
        let effectiveTemperature2 = c * (d - dryBulbTemperature)
        let effectiveTemperature3 = pow(windSpeed,e) - pow(0.2,e)
        let effectiveTemperature = effectiveTemperature1 - effectiveTemperature2 * effectiveTemperature3
        
        //Set Labels
        dryBulbTemperatureLabel.text = "Dry Bulb Temperature: " + String(format: "%.1f", dryBulbTemperature) + "°C"
        wetBulbTemperatureLabel.text = "Wet Bulb Temperature: " + String(format: "%.1f", wetBulbTemperature) + "°C"
        dewPointTemperatureLabel.text = "Dew Point: " + String(format: "%.1f", dewPointTemperature) + "°C"
        effectiveTemperatureLabel.text = String(format: "%.2f",effectiveTemperature) + "°C"
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
        
        temperatureTextField.inputAccessoryView = doneToolbar
        humidityTextField.inputAccessoryView = doneToolbar
        windSpeedTextField.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction(){
        temperatureTextField.resignFirstResponder()
        humidityTextField.resignFirstResponder()
        windSpeedTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        temperatureTextField.resignFirstResponder()
        humidityTextField.resignFirstResponder()
        windSpeedTextField.resignFirstResponder()
        return true
    }
}
