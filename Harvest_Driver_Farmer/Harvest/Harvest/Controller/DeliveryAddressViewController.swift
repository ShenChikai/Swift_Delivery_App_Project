//
//  DeliveryAddressViewController.swift
//  Harvest
//
//  Created by Denny Shen on 2021/2/24.
//

import UIKit
import MapKit
import FirebaseUI
import CoreGraphics

class DeliveryAddressViewController: UIViewController, UISearchBarDelegate, MKLocalSearchCompleterDelegate {

    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchResultsTable: UITableView!
    
    private var activeAddressText = "Unknown"
    private var myLat = 34.0224
    private var myLon = 118.2851
    private var latestAddressText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // searchbar placeholder
        //searchBar.placeholder = "Enter an Address"

        searchCompleter.delegate = self
        searchBar?.delegate = self
        searchResultsTable?.delegate = self
        searchResultsTable?.dataSource = self
        
        setupNavigationBar()

        print("atp to load addr")
        // load saved address
        DatabaseManager.shared.retrieveSavedAddresses { [weak self] (addresses) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.savedAddr = addresses
            DispatchQueue.main.async {
                strongSelf.searchResultsTable.reloadData()
            }
        }
        
        // get active address
        DatabaseManager.shared.retrieveActiveAddress { [weak self] (title, subtitle, lat, lon, apt, building, instruction) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.activeAddressText =  title
            strongSelf.myLat =  lat
            strongSelf.myLon =  lon
            strongSelf.latestAddressText = title
        }
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    // GLOBAL VARIABLES
    // boolean value (show saved if 0, show searched if 1)
    var isSearching = false
    
    // retrieved saved addr
    var savedAddr = [
        Address(title: "", subtitle: ""),
    ]
    
    // searched variables
    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()
    
    func setupNavigationBar() {
        self.navigationController?.navigationBar.barTintColor = .white
        
        // Add back button
        let buttonBack = UIButton()
        buttonBack.tintColor = .black
        buttonBack.setImage(UIImage(systemName: "arrow.backward"), for: .normal)
        buttonBack.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: buttonBack)
        
        // Adjust font
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "Roboto-Medium", size: 18)!]
    }
    
    @objc func backButtonPressed() {
        self.navigationController?.popViewController(animated: true)
    }
    
    // delete
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) && (!isSearching) {
            print("deleting from tableView")
            // get parameters
            let title = savedAddr[indexPath.row].title
            let subtitle = savedAddr[indexPath.row].subtitle
            let lat = savedAddr[indexPath.row].lat
            let lon = savedAddr[indexPath.row].lon
            let apt = savedAddr[indexPath.row].apt
            let building = savedAddr[indexPath.row].building
            let instruction = savedAddr[indexPath.row].instruction
            
            savedAddr.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            // delate from database
            print("deleting from database")
            DatabaseManager.shared.deleteAddress(title: title, subtitle: subtitle, lat: lat, lon: lon, apt: apt, building: building, instruction: instruction)
        }
    }
    
    // update when typed in
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchText == "" {
            // display saved addresses when nothing is entered in the search bar
            isSearching = false
            // reload table
            DatabaseManager.shared.retrieveSavedAddresses { [weak self] (addresses) in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.savedAddr = addresses
                DispatchQueue.main.async {
                    strongSelf.searchResultsTable.reloadData()
                }
            }
        } else {
            // else, this is an actual search
            isSearching = true
            searchCompleter.queryFragment = searchText
        }
    }
    
    // new search results acquired
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Setting our searcResults variable to the results that the searchCompleter returned
        searchResults = completer.results
        print(searchResults)
        // Reload the tableview with our new searchResults
        searchResultsTable.reloadData()
    }
    
    // This method is called when there was an error with the searchCompleter
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Error
    }
    
    
}

// Extension
// update data in table
extension DeliveryAddressViewController: UITableViewDataSource {
    // This method declares the number of sections that we want in our table.
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // This method declares how many rows are the in the table
    // We want this to be the number of current search results that the
    // Completer has generated for us
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            return searchResults.count
        } else {
            return savedAddr.count
        }
    }
    
    // This method delcares the cells that are table is going to show at a particular index
    // Spawn the table
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("Loading Searching Result Table...")
        if isSearching {
            // this is an actual search
            // Get the specific searchResult at the particular index
            let searchResult = searchResults[indexPath.row]
            
            //Create  a new UITableViewCell object
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            
            //Set the content of the cell to our searchResult data
            cell.textLabel?.text = searchResult.title
            cell.detailTextLabel?.text = searchResult.subtitle
            return cell
        } else {
            // not searching, display saved addr
            // Get the saved addr
            let addr = savedAddr[indexPath.row]
            
            //Create  a new UITableViewCell object
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            
            
            //Set the content of the cell to our searchResult data
            cell.textLabel?.text = addr.title
            cell.detailTextLabel?.text = addr.subtitle
            //print("COMPARING:", addr.title, latestAddressText, activeAddressText)
            if latestAddressText == "" || activeAddressText == latestAddressText {
                if myLat == addr.lat && myLon == addr.lon {
                    cell.textLabel?.textColor = UIColor.init(red: 0, green: 0.5, blue: 0.3, alpha: 1)
                    cell.detailTextLabel?.textColor = UIColor.init(red: 0, green: 0.5, blue: 0.3, alpha: 1)
                    cell.backgroundColor = UIColor.init(red: 0.83, green: 0.83, blue: 0.83, alpha: 0.7)
                }
            } else {
                if latestAddressText == addr.title {
                    cell.textLabel?.textColor = UIColor.init(red: 0, green: 0.5, blue: 0.3, alpha: 1)
                    cell.detailTextLabel?.textColor = UIColor.init(red: 0, green: 0.5, blue: 0.3, alpha: 1)
                    cell.backgroundColor = UIColor.init(red: 0.83, green: 0.83, blue: 0.83, alpha: 0.7)
                }
            }
            return cell
        }
    }
}

// triggered when an addr is tapped
extension DeliveryAddressViewController: UITableViewDelegate {
    // This method declares the behavior of what is to happen when the row is selected
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if self.isSearching {
            // in the search results
            let result = searchResults[indexPath.row]
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
                
                var apt = ""
                var building = ""
                var instruction = ""
                
                self.showInputDialog(alertTitle: "Adding to Saved Address",
                                     title: title,
                                     subtitle: subtitle,
                                     lat: lat,
                                     lon: lon,
                                     apt: apt,
                                     building: building,
                                     instruction: instruction,
                                     actionType: "new",
                                     actionTitle: "Save",
                                     cancelTitle: "Cancel",
                                     actionHandler0:
                                            { (input:String?) in
                                                print("apt is \(input ?? "")")
                                                apt = input ?? ""
                                            },
                                     actionHandler1:
                                            { (input:String?) in
                                                print("building is \(input ?? "")")
                                                building = input ?? ""
                                            },
                                     actionHandler2:
                                            { (input:String?) in
                                                print("instruction is \(input ?? "")")
                                                instruction = input ?? ""
                                            },
                                     readyHandler:
                                            { (input:String?) in
                                                // nothing heappens here
                                                print("New addr: \(input ?? "")")
                                            }
                )

            }
        } else {
            // in saved address list
            
            let setTarget = savedAddr[indexPath.row]
            let title = setTarget.title
            let subtitle = setTarget.subtitle
            let lat = setTarget.lat
            let lon = setTarget.lon
            
            var apt = setTarget.apt
            var building = setTarget.building
            var instruction = setTarget.instruction
            
            
            showInputDialog(alertTitle: "Setting Active Address",
                            title: title,
                            subtitle: subtitle,
                            lat: lat,
                            lon: lon,
                            apt: apt,
                            building: building,
                            instruction: instruction,
                            actionType: "update",
                            actionTitle: "Update/Confirm",
                            cancelTitle: "Cancel",
                            actionHandler0:
                                    { (input:String?) in
                                        apt = input ?? ""
                                        print("apt is", apt)
                                    },
                            actionHandler1:
                                    { (input:String?) in
                                        building = input ?? ""
                                        print("building is", building)
                                    },
                            actionHandler2:
                                    { (input:String?) in
                                        instruction = input ?? ""
                                        print("instruction is", instruction)
                                    },
                            readyHandler:
                                    { (input:String?) in
                                        print("update addr: \(input ?? "")")
                                        if input != nil {
                                            self.latestAddressText = input!
                                        }
                                        // load saved address
                                        DatabaseManager.shared.retrieveSavedAddresses { [weak self] (addresses) in
                                            guard let strongSelf = self else {
                                                return
                                            }
                                            strongSelf.savedAddr = addresses
                                            DispatchQueue.main.async {
                                                strongSelf.searchResultsTable.reloadData()
                                            }
                                        }
                                        
                                    }
                            // end of input dialog
                            )

        }
    }
}


extension UIViewController{
    
    func showInputDialog(alertTitle:String? = nil,
                         title:String? = nil,
                         subtitle:String? = nil,
                         lat: Double? = nil,
                         lon: Double? = nil,
                         apt: String? = nil,
                         building: String? = nil,
                         instruction: String? = nil,
                         actionType: String? = nil,
                         actionTitle:String? = "Confirm/Update",
                         cancelTitle:String? = "Cancel",
                         inputPlaceholder:String? = nil,
                         inputKeyboardType:UIKeyboardType = UIKeyboardType.default,
                         cancelHandler: ((UIAlertAction) -> Swift.Void)? = nil,
                         actionHandler0: ((_ text: String?) -> Void)? = nil,
                         actionHandler1: ((_ text: String?) -> Void)? = nil,
                         actionHandler2: ((_ text: String?) -> Void)? = nil,
                         readyHandler: ((_ text: String?) -> Void)? = nil) {
    
        
        let alert = UIAlertController(title: alertTitle, message: title, preferredStyle: .alert)
        // customize alert box
        alert.setValue(NSAttributedString(string: title ?? "...", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.medium), NSAttributedString.Key.foregroundColor : UIColor.init(red: 0, green: 0.55, blue: 0.3, alpha: 1)]), forKey: "attributedMessage")
        
        alert.addTextField { (textField:UITextField) in
            textField.placeholder = "Apt / Suite / Floor"
            textField.keyboardType = inputKeyboardType
            // fill out text if exist
            if apt != "" {
                textField.text = apt
            }
        }
        alert.addTextField { textField in
            textField.addConstraint(textField.heightAnchor.constraint(equalToConstant: 2))
            textField.isEnabled = false
            textField.backgroundColor = UIColor.init(red: 0, green: 0.5, blue: 0.3, alpha: 1)
        }
        alert.addTextField { (textField:UITextField) in
            textField.placeholder = "Building name"
            textField.keyboardType = inputKeyboardType
            // fill out text if exist
            if building != "" {
                textField.text = building
            }
        }
        alert.addTextField { textField in
            textField.addConstraint(textField.heightAnchor.constraint(equalToConstant: 2))
            textField.isEnabled = false
            textField.backgroundColor = UIColor.init(red: 0, green: 0.5, blue: 0.3, alpha: 1)
        }
        alert.addTextField { (textField:UITextField) in
            textField.placeholder = "Delivery Instruction"
            textField.keyboardType = inputKeyboardType
            // fill out text if exist
            if instruction != "" {
                textField.text = instruction
            }
        }
        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { (action:UIAlertAction) in
            
            // get first
            guard let textField0 =  alert.textFields?.first else {
                actionHandler0?(nil)
                return
            }
            actionHandler0?(textField0.text)
            
            // get second
            guard let textField1 =  alert.textFields?[2] else {
                actionHandler1?(nil)
                return
            }
            actionHandler1?(textField1.text)
            
            // get third
            guard let textField2 =  alert.textFields?.last else {
                actionHandler2?(nil)
                return
            }
            actionHandler2?(textField2.text)
            
            // old data
            let Otitle = title ?? ""
            let Osubtitle = subtitle ?? ""
            let Olat = lat ?? 0
            let Olon = lon ?? 0
            let Oapt = apt ?? ""
            let Obuilding = building ?? ""
            let Oinstruction = instruction ?? ""
            
            // new updates
            let Xtitle = title ?? ""
            let Xsubtitle = subtitle ?? ""
            let Xlat = lat ?? 0
            let Xlon = lon ?? 0
            let Xapt = textField0.text ?? ""
            let Xbuilding = textField1.text ?? ""
            let Xinstruction = textField2.text ?? ""
            
            // update
            if (actionType == "new") {
                print("insert new address")
                DatabaseManager.shared.insertAddress2(title: Xtitle, subtitle: Xsubtitle, lat: Xlat, lon: Xlon, apt: Xapt, building: Xbuilding, instruction: Xinstruction)
            }
            else if (actionType == "update") {
                print("update saved address")
                // set active & delete old & insert new
                DatabaseManager.shared.setActiveAddress(title: Xtitle, subtitle: Xsubtitle, lat: Xlat, lon: Xlon, apt: Xapt, building: Xbuilding, instruction: Xinstruction)
                DatabaseManager.shared.deleteAddress(title: Otitle, subtitle: Osubtitle, lat: Olat, lon: Olon, apt: Oapt, building: Obuilding, instruction: Oinstruction)
                DatabaseManager.shared.insertAddress2(title: Xtitle, subtitle: Xsubtitle, lat: Xlat, lon: Xlon, apt: Xapt, building: Xbuilding, instruction: Xinstruction)
            }
            
            // refresh saved addr
            readyHandler?(Xtitle)
            
        }))
        
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: cancelHandler))
        self.present(alert, animated: true, completion: nil)
    }
}
