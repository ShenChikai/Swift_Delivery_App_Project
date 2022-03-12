//
//  SignInaddLocationViewController.swift
//  Harvest
//

import Foundation
import UIKit
import CoreGraphics
import MapKit

class SignUpAddLocationViewController: UIViewController, MKLocalSearchCompleterDelegate {
    
    @IBOutlet weak var addressTF: UITextField!
    @IBOutlet weak var unitTF: UITextField!
    @IBOutlet weak var buildingNameTF: UITextField!
    @IBOutlet weak var deliveryInstructionTF: UITextField!
    
    // searched addresses
//    var addressList = [
//        Address(title: "test1", subtitle: "test"),
//        Address(title: "test2", subtitle: "test"),
//        Address(title: "test3", subtitle: "test")
//    ]
    
    // pickerView and Accessorybar
    var pikerView = UIPickerView()
    var pickerSelectedIdx = 0
    let toolBar = UIToolbar()
    
    // state typing/searching
    var isSearching = false
    
    // searched variables
    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()
    
    // parameters
    var titleX = ""
    var subtitle = ""
    var lat:Double = 0.0
    var lon:Double = 0.0
    var apt = ""
    var building = ""
    var instruction = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        self.searchCompleter.delegate = self
        // set up picker for addressTF
        self.pikerView.delegate = self
        self.pikerView.dataSource = self
        
        // addressTF first appear to be keyboard, show picker when search tapped
        addressTF.delegate = self
        unitTF.delegate = self
        buildingNameTF.delegate = self
        
        // initialize addressTF attributes
        addressTF.clearButtonMode = .whileEditing
        addressTF.inputView = nil
        addressTF.returnKeyType = UIReturnKeyType.search
        
        // Accessory Toolbar Done
        toolBar.sizeToFit()
        
        let button = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.doneButtonPressed))
        toolBar.setItems([button], animated: true)
        toolBar.isUserInteractionEnabled = true
        // addressTF.inputAccessoryView = toolBar
        
    }
    
    // update when typed in addressTF
    @IBAction func textFieldChanged(_ sender: UITextField) {
        print("address input changed: ", addressTF.text ?? "<empty>")
        searchCompleter.queryFragment = addressTF.text ?? ""
    }
    // new search results acquired
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Setting our searcResults variable to the results that the searchCompleter returned
        searchResults = completer.results
        print("search results: " , searchResults)
        DispatchQueue.main.async {
            print("reloading...")
            self.pikerView.reloadAllComponents()
        }
    }
    // This method is called when there was an error with the searchCompleter
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Error
        print("Error in MKLocalSearchCompleter")
    }
    
    
    @objc private func doneButtonPressed() {
        view.endEditing(true)
    }
    
    
    
    @IBAction func continueButtonPressed(_ sender: RoundButton) {
        sender.tapAnimation {
            self.addAddress()
        }
    }
    
    private func addAddress() {
        print("Continue.")
        clearErrors()
        
        guard let address = addressTF.text, !address.isEmpty else {
            alertAddressError(title: "Invalid Address", message: "Please fill in with valid address.")
            return
        }
        self.apt = unitTF.text ?? ""
        self.building = buildingNameTF.text ?? ""
        self.instruction = deliveryInstructionTF.text ?? ""
        
        // save and set this addresss
        // set active & delete old & insert new
        DatabaseManager.shared.setActiveAddress(title: titleX, subtitle: subtitle, lat: lat, lon: lon, apt: apt, building: building, instruction: instruction)
        DatabaseManager.shared.insertAddress2(title: titleX, subtitle: subtitle, lat: lat, lon: lon, apt: apt, building: building, instruction: instruction)
        
        // Push new view controller
        // Push new view controller
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "SignUpAddPaymentViewController") as! SignUpAddPaymentViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    /// Display an alert
    private func alertAddressError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    /// Clear all errors on labels and textFields
    private func clearErrors() {
        DispatchQueue.main.async {
            // TODO
        }
    }
    
    /// Display error on label and textField
    private func displayError(label: UILabel, textField: UITextField?, message: String) {
        DispatchQueue.main.async {
            if let textField = textField {
                textField.setShadowColor(color: UIColor.red)
            }
            label.alpha = 1
            label.text = message
        }
    }
}

extension SignUpAddLocationViewController: UITextFieldDelegate {
    
    // switch state when addressTF tapped
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == addressTF && self.isSearching {
            addressTF.inputView = nil
            addressTF.inputAccessoryView = nil
            addressTF.returnKeyType = UIReturnKeyType.search
            addressTF.becomeFirstResponder()
            self.isSearching = false
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("return key pressed")
        switch textField {
        case addressTF:
            print("textFieldShouldReturn: SEARCH")
            // hide keyboard and show picker
            addressTF.resignFirstResponder()
            addressTF.inputView = self.pikerView
            addressTF.inputAccessoryView = self.toolBar
            addressTF.becomeFirstResponder()
            self.isSearching = true
            
        case unitTF:
            buildingNameTF.becomeFirstResponder()
        case buildingNameTF:
            deliveryInstructionTF.becomeFirstResponder()
        case deliveryInstructionTF:
            addAddress()
        default:
            textField.resignFirstResponder()
        }
        
        return true
    }
    
    
    
}

extension SignUpAddLocationViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return searchResults.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return searchResults[row].title + ", " + searchResults[row].subtitle
    }
    
    // on select
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print("Selected index: \(row)")
        // insert and set address
        self.pickerSelectedIdx = row
        let result = searchResults[pickerSelectedIdx]
        let searchRequest = MKLocalSearch.Request(completion: result)
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { (response, error) in
            guard let coordinate = response?.mapItems[0].placemark.coordinate else {
                return
            }
            
            guard let title = response?.mapItems[0].name else {
                return
            }
            
            guard let placemark = response?.mapItems[0].placemark else {
                return
            }
            
            let subtitle = (placemark.subThoroughfare ?? "") + " " + (placemark.thoroughfare ?? "detail address unknown")
            let lat = coordinate.latitude
            let lon = coordinate.longitude
            
            print(title)
            print(subtitle)
            print(lat)
            print(lon)
            
            self.titleX = title
            self.subtitle = subtitle
            self.lat = lat
            self.lon = lon
            
            self.addressTF.text = title+" "+subtitle
        }

    }
    
}
