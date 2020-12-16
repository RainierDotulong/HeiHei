//
//  StartCycleViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 8/10/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import UIEmptyState
import Firebase
import FirebaseFirestore
import NotificationBannerSwift

class StartCycleTableViewCell : UITableViewCell, UITextFieldDelegate {
    //startCycleCell
    @IBOutlet var lantaiLabel: UILabel!
    @IBOutlet var tanggalMulaiLabel: UILabel!
    @IBOutlet var bwAwalLabel: UILabel!
    @IBOutlet var pakanAwalLabel: UILabel!
    @IBOutlet var populasiAwalLabel: UILabel!
    @IBOutlet var umurClaimLabel: UILabel!
    @IBOutlet var jumlahClaimLabel: UILabel!
    @IBOutlet var jumlahPanenlabel: UILabel!
    @IBOutlet var beratPanenLabel: UILabel!
}

struct floorData {
    var lantai : Int
    var pakanAwal : Int
    var startTimestamp : Double
    var startingBodyWeight : Float
    var startingPopulation : Int
    var claimAge : Int
    var claimQuantity : Int
    var harvestedQuantity : Int
    var harvestedWeight : Float
}

class StartCycleViewController: UIViewController, sendFloorDataToStartCycleVC, UIEmptyStateDataSource, UIEmptyStateDelegate, UITableViewDelegate, UITableViewDataSource {
    
    //Initalize Variables passed from previous VC
    var fullName : String = ""
    var loginClass : String = ""
    
    var farmName : String = ""

    @IBOutlet var farmNameButton: UIButton!
    
    @IBOutlet var navItem: UINavigationItem!
    
    @IBOutlet var hargaListrikTextField: UITextField!
    @IBOutlet var nomorSiklusTextField: UITextField!
    
    @IBOutlet var finishButton: UIButton!
    
    @IBOutlet var tableView: UITableView!
    
    var numberOfFloors : Int = 0
    
    var dataArray : [floorData] = [floorData]()
    
    var selectedData : floorData = floorData(lantai: 99999, pakanAwal: 99999, startTimestamp: 99999, startingBodyWeight: 99999, startingPopulation: 99999, claimAge: 99999, claimQuantity: 99999, harvestedQuantity: 99999, harvestedWeight: 99999)
    
    var floor1Data : floorData = floorData(lantai: 1, pakanAwal: 99999, startTimestamp: 99999, startingBodyWeight: 99999, startingPopulation: 99999, claimAge: 99999, claimQuantity: 99999, harvestedQuantity: 99999, harvestedWeight: 99999)
    var floor2Data : floorData = floorData(lantai: 2, pakanAwal: 99999, startTimestamp: 99999, startingBodyWeight: 99999, startingPopulation: 99999, claimAge: 99999, claimQuantity: 99999, harvestedQuantity: 99999, harvestedWeight: 99999)
    var floor3Data : floorData = floorData(lantai: 3, pakanAwal: 99999, startTimestamp: 99999, startingBodyWeight: 99999, startingPopulation: 99999, claimAge: 99999, claimQuantity: 99999, harvestedQuantity: 99999, harvestedWeight: 99999)
    var floor4Data : floorData = floorData(lantai: 4, pakanAwal: 99999, startTimestamp: 99999, startingBodyWeight: 99999, startingPopulation: 99999, claimAge: 99999, claimQuantity: 99999, harvestedQuantity: 99999, harvestedWeight: 99999)
    var floor5Data : floorData = floorData(lantai: 5, pakanAwal: 99999, startTimestamp: 99999, startingBodyWeight: 99999, startingPopulation: 99999, claimAge: 99999, claimQuantity: 99999, harvestedQuantity: 99999, harvestedWeight: 99999)
    var floor6Data : floorData = floorData(lantai: 6, pakanAwal: 99999, startTimestamp: 99999, startingBodyWeight: 99999, startingPopulation: 99999, claimAge: 99999, claimQuantity: 99999, harvestedQuantity: 99999, harvestedWeight: 99999)
    
    //UI Empty State Variables
    var emptyStateTitle: NSAttributedString {
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor(red: 0.882, green: 0.890, blue: 0.859, alpha: 1.00),
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22)]
        return NSAttributedString(string: "Pilih Nama Kandang", attributes: attrs)
    }
    
    var emptyStateImage: UIImage? {
        return UIImage(named: "redLogo")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Force Interface Light Mode
        overrideUserInterfaceStyle = .light
        
        // Set the data source and delegate
        self.emptyStateDataSource = self
        self.emptyStateDelegate = self
        
        // Remove seperator lines from empty cells
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.reloadEmptyStateForTableView(tableView)
        
        self.addDoneButtonOnKeyboard()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Disable Autorotation
    override var shouldAutorotate: Bool {
        return false
    }
    
    @IBAction func getDataButtonPressed(_ sender: Any) {
        
        guard farmName != ""  else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Invalid Farm Name", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        print("Get Data")
        
        //Get Cycle Number from Firebase
        let farmDetailRef = Firestore.firestore().collection(self.farmName + "Details").document("farmDetail")
        
        farmDetailRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let dataDescription = document.data()
                
                let nomorSiklus = dataDescription!["currentCycleNumber"] as! Int
                self.nomorSiklusTextField.text = "\(nomorSiklus)"
                let numberOfFloors = dataDescription!["numberOfFloors"] as! Int
                self.hargaListrikTextField.text = String( dataDescription!["hargaPerKwh"] as! Int)
                
                var finishedCount = 0
                for i in 1...numberOfFloors {
                    print(i)
                    let floorDetailRef = Firestore.firestore().collection(self.farmName + "Details").document("floor\(i)Cycle\(nomorSiklus)Details")
                    
                    floorDetailRef.getDocument { (document, error) in
                        if let document = document, document.exists {
                            let dataDescription = document.data()
                            self.dataArray[i-1].claimAge = dataDescription!["claimAge"] as! Int
                            self.dataArray[i-1].claimQuantity = dataDescription!["claimQuantity"] as! Int
                            self.dataArray[i-1].harvestedWeight = dataDescription!["harvestedWeight"] as! Float
                            self.dataArray[i-1].harvestedQuantity = dataDescription!["harvestedQuantity"] as! Int
                            self.dataArray[i-1].pakanAwal = dataDescription!["pakanAwal"] as! Int
                            self.dataArray[i-1].startTimestamp = dataDescription!["startTimestamp"] as! Double
                            self.dataArray[i-1].startingBodyWeight = dataDescription!["startingBodyWeight"] as! Float
                            self.dataArray[i-1].startingPopulation = dataDescription!["startingPopulation"] as! Int
                            finishedCount += 1
                            //Reload Table view when all data acquired
                            if finishedCount == numberOfFloors {
                                self.tableView.reloadData()
                            }
                        }
                        else {
                            print("Floor Detail Does not exist")
                        }
                    }
                }
                
            } else {
                print("Current Cycle Document does not exist")
                //Declare Alert message
                let dialogMessage = UIAlertController(title: "Current Cycle Document does not exist", message: "Please Contact Administrator", preferredStyle: .alert)
                
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
        
    }
    
    
    func floorDataReceived(floorData: floorData) {
        switch floorData.lantai {
        case 1:
            dataArray[0] = floorData
        case 2:
            dataArray[1] = floorData
        case 3:
            dataArray[2] = floorData
        case 4:
            dataArray[3] = floorData
        case 5:
            dataArray[4] = floorData
        case 6:
            dataArray[5] = floorData
        default:
            print("Unknown Floor")
        }
        self.tableView.reloadData()
    }
    
    @IBAction func finishButtonPressed(_ sender: Any) {
        guard farmName != "" else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Invalid Farm", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard Int(hargaListrikTextField.text ?? "99999") ?? 99999 != 99999 else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Invalid Harga Listrik", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        
        guard Int(nomorSiklusTextField.text ?? "99999") ?? 99999 != 99999 else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Invalid Nomor Siklus", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
                
        guard Int(nomorSiklusTextField.text ?? "99999") ?? 99999 != 99999 else {
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Invalid Nomor Siklus", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            dialogMessage.addAction(ok)
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }

        
        for data in dataArray {
            guard data.lantai != 99999 else {
                let dialogMessage = UIAlertController(title: "Invalid Lantai", message: "", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            guard data.pakanAwal != 99999 else {
                let dialogMessage = UIAlertController(title: "Invalid Pakan Awal Lantai \(data.lantai)", message: "", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            guard data.startTimestamp != 99999 else {
                let dialogMessage = UIAlertController(title: "Invalid Tanggal Mulai Lantai \(data.lantai)", message: "", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            guard data.startingBodyWeight != 99999 else {
                let dialogMessage = UIAlertController(title: "Invalid BW Awal Lantai \(data.lantai)", message: "", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
            guard data.startingPopulation != 99999 else {
                let dialogMessage = UIAlertController(title: "Invalid Populasi Awal Lantai \(data.lantai)", message: "", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("Ok button tapped")
                })
                dialogMessage.addAction(ok)
                self.present(dialogMessage, animated: true, completion: nil)
                return
            }
        }
        print("Finish")
        
        let numberOfFloors = dataArray.count
        let cycleNumber = Int(nomorSiklusTextField.text!)!
        let hargaPerKwh = Int(hargaListrikTextField.text!)!
        
        uploadFarmDetailDocument(farmName: farmName, currentCycleNumber: cycleNumber, hargaPerKwh: hargaPerKwh, numberOfFloors: numberOfFloors)
        
        for i in 0..<dataArray.count {
            uploadFarmFloorDetailDocument(farmName: farmName, umurClaim: dataArray[i].claimAge, jumlahClaim: dataArray[i].claimQuantity, ekorPanen : dataArray[i].harvestedQuantity, KgPanen: dataArray[i].harvestedWeight, floorNumber: i+1, cycleNumber: cycleNumber, startTimestamp: dataArray[i].startTimestamp, startingBodyWeight: dataArray[i].startingBodyWeight, startingPopulation: dataArray[i].startingPopulation, pakanAwal: dataArray[i].pakanAwal)
        }
        
        self.navigationController?.popViewController(animated: true)
    }
    
    func uploadFarmDetailDocument(farmName: String, currentCycleNumber : Int, hargaPerKwh : Int, numberOfFloors: Int) {
        let doc = Firestore.firestore().collection("\(farmName)Details").document("farmDetail")
        doc.setData([
            "currentCycleNumber" : currentCycleNumber,
            "hargaPerKwh" : hargaPerKwh,
            "numberOfFloors" : numberOfFloors
        ]) { err in
            if let err = err {
                print("Error writing Farm Detail Document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error Writing Farm Detail Document", style: .danger)
                banner.show()
            } else {
                print("Farm Detail Document successfully written!")
            }
        }
    }
    
    func uploadFarmFloorDetailDocument(farmName: String, umurClaim : Int, jumlahClaim : Int, ekorPanen: Int, KgPanen: Float, floorNumber: Int, cycleNumber : Int, startTimestamp: Double, startingBodyWeight : Float, startingPopulation : Int, pakanAwal: Int) {
        let doc = Firestore.firestore().collection("\(farmName)Details").document("floor\(floorNumber)Cycle\(cycleNumber)Details")
        doc.setData([
            "claimAge" : umurClaim,
            "claimQuantity" : jumlahClaim,
            "harvestedQuantity" : ekorPanen,
            "harvestedWeight" : KgPanen,
            "pakanAwal" : pakanAwal,
            "startTimestamp" : startTimestamp,
            "startingBodyWeight" : startingBodyWeight,
            "startingPopulation" : startingPopulation
        ]) { err in
            if let err = err {
                print("Error writing Farm Floor Detail Document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error Writing Farm Detail Document", style: .danger)
                banner.show()
            } else {
                print("Farm Floor Detail Document successfully written!")
            }
        }
    }
    
    // MARK: Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        func createCell(data : floorData) -> StartCycleTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "startCycleCell", for: indexPath) as! StartCycleTableViewCell
            
            let date = Date(timeIntervalSince1970: data.startTimestamp )
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let stringDate = dateFormatter.string(from: date)
            
            cell.lantaiLabel.text = "Lantai \(data.lantai)"
            if data.startTimestamp != 99999 {
                cell.tanggalMulaiLabel.text = "Tanggal Mulai: \(stringDate)"
                cell.bwAwalLabel.text = "BW Awal: \(String(format: "%.2f", data.startingBodyWeight)) Gram"
                cell.pakanAwalLabel.text = "Pakan Awal: \(data.pakanAwal) zak"
                cell.populasiAwalLabel.text = "Populasi Awal: \(data.startingPopulation) Ekor"
                cell.umurClaimLabel.text = "Umur Claim: \(data.claimAge) hari"
                cell.jumlahClaimLabel.text = "Jumlah Claim: \(data.claimQuantity) Ekor"
                cell.jumlahPanenlabel.text = "Jumlah Panen: \(data.harvestedQuantity)"
                cell.beratPanenLabel.text = "Berat Panen: \(String(format: "%.2f", data.harvestedWeight))"
            }
            else {
                cell.tanggalMulaiLabel.text = "Tanggal Mulai"
                cell.bwAwalLabel.text = "BW Awal"
                cell.pakanAwalLabel.text = "Pakan Awal"
                cell.populasiAwalLabel.text = "Populasi Awal"
                cell.umurClaimLabel.text = "Umur Claim"
                cell.jumlahClaimLabel.text = "Jumlah Claim"
                cell.jumlahPanenlabel.text = "Jumlah Panen"
                cell.beratPanenLabel.text = "Berat Panen"
            }
            return cell
        }
        return createCell(data: dataArray[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        selectedData = dataArray[indexPath.row]
        
        self.performSegue(withIdentifier: "goToFloorDetails", sender: self)
    }

    @IBAction func farmNameButtonPressed(_ sender: Any) {
        let dialogMessage = UIAlertController(title: "Farm", message: "Pilih nama kandang", preferredStyle: .alert)
        
        let pinantik = UIAlertAction(title: "Pinantik", style: .default, handler: { (action) -> Void in
            self.farmName = "pinantik"
            self.dataArray = [self.floor1Data,self.floor2Data]
            self.farmNameButton.setTitle(" Farm: Pinantik", for: .normal)
            self.farmNameButton.setTitleColor(.black, for: .normal)
            self.farmNameButton.tintColor = .black
            self.tableView.reloadData()
            self.reloadEmptyStateForTableView(self.tableView)
        })
        
        let kejayan = UIAlertAction(title: "Kejayan", style: .default, handler: { (action) -> Void in
            self.farmName = "kejayan"
            self.dataArray = [self.floor1Data,self.floor2Data,self.floor3Data]
            self.farmNameButton.setTitle(" Farm: Kejayan", for: .normal)
            self.farmNameButton.setTitleColor(.black, for: .normal)
            self.farmNameButton.tintColor = .black
            self.tableView.reloadData()
            self.reloadEmptyStateForTableView(self.tableView)
        })
        
        let lewih = UIAlertAction(title: "Lewih", style: .default, handler: { (action) -> Void in
            self.farmName = "lewih"
            self.dataArray = [self.floor1Data,self.floor2Data,self.floor3Data,self.floor4Data,self.floor5Data,self.floor6Data]
            self.farmNameButton.setTitle(" Farm: Lewih", for: .normal)
            self.farmNameButton.setTitleColor(.black, for: .normal)
            self.farmNameButton.tintColor = .black
            self.tableView.reloadData()
            self.reloadEmptyStateForTableView(self.tableView)
        })
        dialogMessage.addAction(pinantik)
        dialogMessage.addAction(kejayan)
        dialogMessage.addAction(lewih)
        
        self.present(dialogMessage, animated: true, completion: nil)
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
        
        hargaListrikTextField.inputAccessoryView = doneToolbar
        nomorSiklusTextField.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction(){
        hargaListrikTextField.resignFirstResponder()
        nomorSiklusTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        hargaListrikTextField.resignFirstResponder()
        nomorSiklusTextField.resignFirstResponder()
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is StartCycleFloorDetailViewController
        {
            let vc = segue.destination as? StartCycleFloorDetailViewController
            vc?.selectedData = selectedData
            vc?.delegate = self
        }
    }
}
