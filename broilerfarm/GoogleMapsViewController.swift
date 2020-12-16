//
//  GoogleMapsViewController.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 4/23/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import Firebase
import FirebaseFirestore
import NotificationBannerSwift

protocol sendPlaceData {
    func placeDataReceived(address: String, latitude : String, longitude : String)
}

class GoogleMapsViewController: UIViewController, GMSMapViewDelegate {
    
    var loginClass : String = ""
    var fullName : String = ""
    var delegate : sendPlaceData?
    var previousMenu : String = ""
    var dataArray : [RetailPurchaseOrder] = [RetailPurchaseOrder]()
    
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var mapView: GMSMapView!
    var placesClient: GMSPlacesClient!
    var zoomLevel: Float = 15.0
    
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var resultView: UITextView?
    
    // An array to hold the list of likely places.
    var likelyPlaces: [GMSPlace] = []

    // The currently selected place.
    var selectedPlace: GMSPlace?
    var selectedCoordinate: CLLocationCoordinate2D?
    
    let defaultLocation = CLLocation(latitude: -8.6566, longitude: 115.2017)
    
    @IBOutlet var navItem: UINavigationItem!
    @IBOutlet var actionBarButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        overrideUserInterfaceStyle = .light
        GMSPlacesClient.provideAPIKey("AIzaSyDvXV55MAHcxySTKXGLc6X4Fb0Pru0kruo")
        GMSServices.provideAPIKey("AIzaSyDvXV55MAHcxySTKXGLc6X4Fb0Pru0kruo")
        
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self

        placesClient = GMSPlacesClient.shared()

        
        let camera = GMSCameraPosition.camera(withLatitude: defaultLocation.coordinate.latitude,
                                              longitude: defaultLocation.coordinate.longitude,
                                              zoom: zoomLevel)
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = self
        mapView.isMyLocationEnabled = true

        // Add the map to the view, hide it until we've got a location update.
        view.addSubview(mapView)
        //mapView.isHidden = true
        
        if previousMenu == "New Purchase Order" {
            navItem.title = "Delivery Location"
            
            resultsViewController = GMSAutocompleteResultsViewController()
            resultsViewController?.delegate = self

            searchController = UISearchController(searchResultsController: resultsViewController)
            searchController?.searchResultsUpdater = resultsViewController
            
            let filter = GMSAutocompleteFilter()
            filter.country = "ID"
            resultsViewController?.autocompleteFilter = filter
            print((self.navigationController?.navigationBar.frame.height)! + 20)
            let statusBarHeight = UIApplication.shared.statusBarFrame.height
            let navigationBarHeight = self.navigationController?.navigationBar.frame.height ?? 0
            let subView = UIView(frame: CGRect(x: 0, y: statusBarHeight + navigationBarHeight, width: 350.0, height: 45.0))

            subView.addSubview((searchController?.searchBar)!)
            view.addSubview(subView)
            searchController?.searchBar.sizeToFit()
            searchController?.hidesNavigationBarDuringPresentation = true

            // When UISearchController presents the results view, present it in
            // this view controller, not one further up the chain.
            definesPresentationContext = true
        }
        else if previousMenu == "Deliveries" {
            navItem.title = "Assign Delivery Zones"
            actionBarButton.isEnabled = false
            makePurchaseOrderLocationMarkers()
        }
        else if previousMenu == "RPA" || previousMenu == "Storage" {
            navItem.title = "\(previousMenu) Coordinates"
            resultsViewController = GMSAutocompleteResultsViewController()
            resultsViewController?.delegate = self

            searchController = UISearchController(searchResultsController: resultsViewController)
            searchController?.searchResultsUpdater = resultsViewController
            
            let filter = GMSAutocompleteFilter()
            filter.country = "ID"
            resultsViewController?.autocompleteFilter = filter
            print((self.navigationController?.navigationBar.frame.height)! + 20)
            let statusBarHeight = UIApplication.shared.statusBarFrame.height
            let navigationBarHeight = self.navigationController?.navigationBar.frame.height ?? 0
            let subView = UIView(frame: CGRect(x: 0, y: statusBarHeight + navigationBarHeight, width: 350.0, height: 45.0))

            subView.addSubview((searchController?.searchBar)!)
            view.addSubview(subView)
            searchController?.searchBar.sizeToFit()
            searchController?.hidesNavigationBarDuringPresentation = true

            // When UISearchController presents the results view, present it in
            // this view controller, not one further up the chain.
            definesPresentationContext = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    func makePurchaseOrderLocationMarkers () {
        //Add Markers for each Purchase Order Location
        var bounds = GMSCoordinateBounds()
        for purchaseOrder in dataArray {
            let deliveryCoordinate = CLLocationCoordinate2DMake(purchaseOrder.deliveryLatitude, purchaseOrder.deliveryLongitude)
            bounds = bounds.includingCoordinate(deliveryCoordinate)
            // Add a marker to the map.
            let deliveryLocationMarker = GMSMarker(position: (deliveryCoordinate))
            deliveryLocationMarker.title = purchaseOrder.purchaseOrderNumber
            deliveryLocationMarker.snippet = "\(purchaseOrder.name) - \(purchaseOrder.deliveryZone)"
            
            switch purchaseOrder.deliveryZone {
            case "A":
                deliveryLocationMarker.icon = GMSMarker.markerImage(with: .systemBlue)
            case "B":
                deliveryLocationMarker.icon = GMSMarker.markerImage(with: .systemGreen)
            case "C":
                deliveryLocationMarker.icon = GMSMarker.markerImage(with: .systemYellow)
            case "D":
                deliveryLocationMarker.icon = GMSMarker.markerImage(with: .systemTeal)
            case "E":
                deliveryLocationMarker.icon = GMSMarker.markerImage(with: .systemPurple)
            case "F":
                deliveryLocationMarker.icon = GMSMarker.markerImage(with: .systemGray)
            default:
                deliveryLocationMarker.icon = GMSMarker.markerImage(with: .systemRed)
            }

            deliveryLocationMarker.map = self.mapView
        }
        
        //Zoom to Markers
        //let camera: GMSCameraUpdate = GMSCameraUpdate.fit(bounds)
        let cameraWithPadding: GMSCameraUpdate = GMSCameraUpdate.fit(bounds, withPadding: 100.0)

        self.mapView.animate(with: cameraWithPadding)
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        if previousMenu == "Deliveries"
        {
            let alert = UIAlertController(title: "Assign Delivery Zone", message: "Type Delivery Zone in Text Field.", preferredStyle: .alert)
            
            alert.addTextField { (textField) in
                textField.placeholder = "A"
                textField.keyboardType = .default
                textField.autocapitalizationType = .words
            }
            
            alert.addTextField { (textField) in
                textField.placeholder = "1"
                textField.keyboardType = .numberPad
            }
            
            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
                let textField = alert.textFields![0]
                let textField1 = alert.textFields![1]
                print(textField.text ?? "")
                guard textField.text ?? "" != ""  else {
                    print("Incomplete Data")
                    let dialogMessage = UIAlertController(title: "Incomplete Data", message: "Text Field Empty", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                        print("Ok button tapped")
                    })
                    dialogMessage.addAction(ok)
                    self.present(dialogMessage, animated: true, completion: nil)
                    return
                }
                
                guard Int(textField1.text ?? "0") ?? 0 != 0  else {
                    print("Invalid Data")
                    let dialogMessage = UIAlertController(title: "Invalid Data", message: "Delivery Number is non-numerical", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                        print("Ok button tapped")
                    })
                    dialogMessage.addAction(ok)
                    self.present(dialogMessage, animated: true, completion: nil)
                    return
                }
                print("ASSIGN ZONE \(textField.text ?? "") for \(marker.title ?? "")")
                let currentSnippet = marker.snippet
                let newSnippet = "\(currentSnippet?.components(separatedBy: "-")[0] ?? "") - \(textField.text ?? "")"
                marker.snippet = newSnippet
                switch textField.text ?? "" {
                case "A":
                    marker.icon = GMSMarker.markerImage(with: .systemBlue)
                case "B":
                    marker.icon = GMSMarker.markerImage(with: .systemGreen)
                case "C":
                    marker.icon = GMSMarker.markerImage(with: .systemYellow)
                case "D":
                    marker.icon = GMSMarker.markerImage(with: .systemTeal)
                case "E":
                    marker.icon = GMSMarker.markerImage(with: .systemPurple)
                case "F":
                    marker.icon = GMSMarker.markerImage(with: .systemGray)
                default:
                    marker.icon = GMSMarker.markerImage(with: .systemRed)
                }
                self.setDeliveryZonePurchaseOrder(deliveryZone: textField.text ?? "", deliveryNumber: Int(textField1.text ?? "0")!, purchaseOrderNumber: marker.title ?? "")
            })
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
                print("Cancel button tapped")
            }
            
            alert.addAction(ok)
            alert.addAction(cancel)
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func setDeliveryZonePurchaseOrder (deliveryZone : String, deliveryNumber : Int, purchaseOrderNumber : String) {
        //Set Local Data Values
        for i in 0..<self.dataArray.count {
            if purchaseOrderNumber == self.dataArray[i].purchaseOrderNumber {
                self.dataArray[i].deliveryZone = deliveryZone
            }
        }
        print("Assign Deliver Zone Purchase Order")
        let doc = Firestore.firestore().collection("retailPurchaseOrders").document(purchaseOrderNumber)
        doc.updateData([
            "deliveryZone" : deliveryZone,
            "deliveryNumber" : deliveryNumber,
        ]) { err in
            if let err = err {
                print("Error writing new product document: \(err)")
                let banner = StatusBarNotificationBanner(title: "Error writing New Purchase Order Document", style: .danger)
                banner.show()
            } else {
                print("Purchase Order Zone Successfully Updated!")
                //Post Notification for finished purchase order creation
                let PurchaseOrderCreationNotification = Notification.Name("purchaseOrderCreated")
                NotificationCenter.default.post(name: PurchaseOrderCreationNotification, object: nil)
                let banner = StatusBarNotificationBanner(title: "Purchase Order Zone Successfully Updated!", style: .success)
                banner.show()
            }
        }
    }
    
    func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {
        let location = currentLocation ?? defaultLocation
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
        longitude: location.coordinate.longitude,
        zoom: zoomLevel)
        mapView.camera = camera
        return true
    }
    
    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        self.selectedPlace = nil
        self.selectedCoordinate = coordinate
        addSelectedPlaceMarker(place: false)
    }
    
    func placeDataReceived(selectedPlace: GMSPlace) {
        self.selectedPlace = selectedPlace
        self.selectedCoordinate = selectedPlace.coordinate
        addSelectedPlaceMarker(place: true)
    }
    
    func addSelectedPlaceMarker (place : Bool) {
        // Clear the map.
        mapView.clear()
        
        if place {
            // Add a marker to the map.
            let marker = GMSMarker(position: (selectedPlace?.coordinate)!)
            marker.title = selectedPlace?.name
            marker.snippet = selectedPlace?.formattedAddress
            marker.map = mapView
            
            let camera = GMSCameraPosition.camera(withLatitude: (selectedPlace?.coordinate.latitude)!,
                                                  longitude: (selectedPlace?.coordinate.longitude)!,
            zoom: zoomLevel)
            mapView.camera = camera
        }
        else {
            // Add a marker to the map.
            let marker = GMSMarker(position: (selectedCoordinate!))
            marker.title = "Tapped Location"
            marker.map = mapView
        }
    }
    
    @IBAction func actionButtonPressed(_ sender: Any) {
        guard selectedCoordinate != nil else {
            print("No coordinates")
            //Declare Alert message
            let dialogMessage = UIAlertController(title: "Coordinates Missing!", message: "Please Pick Coordinates by Tapping on Map View or search using the search bar", preferredStyle: .alert)

            let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("OK button tapped")
            })
            
            dialogMessage.addAction(ok)
            
            if let popoverController = dialogMessage.popoverPresentationController {
              popoverController.sourceView = self.view
              popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
              popoverController.permittedArrowDirections = []
            }
            
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        let latitude = String(format: "%.4f", self.selectedCoordinate!.latitude)
        let longitude = String(format: "%.4f", self.selectedCoordinate!.longitude)
        self.delegate?.placeDataReceived(address: selectedPlace?.formattedAddress ?? "", latitude: latitude, longitude: longitude)
        
        self.navigationController?.popViewController(animated: true)
    }
}

extension GoogleMapsViewController: CLLocationManagerDelegate {
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        currentLocation = location
        
        if previousMenu == "New Purchase Order" {
            let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel)
            if mapView.isHidden {
                mapView.isHidden = false
                mapView.camera = camera
                
            }
            else {
                mapView.animate(to: camera)
                
            }
        }
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            mapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        default:
            print("Unknown location status")
        }
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
}

// Handle the user's selection.
extension GoogleMapsViewController: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                         didAutocompleteWith place: GMSPlace) {
        searchController?.isActive = false
        // Do something with the selected place.
        self.selectedPlace = place
        self.selectedCoordinate = place.coordinate
        addSelectedPlaceMarker(place: true)
    }
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                         didFailAutocompleteWithError error: Error){
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
}
