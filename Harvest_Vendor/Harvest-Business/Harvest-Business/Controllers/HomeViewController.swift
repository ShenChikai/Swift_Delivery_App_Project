//
//  HomeViewController.swift
//  Harvest-Business
//
//  Created by Zixuan Li on 2021/4/10.
//

import Foundation
import UIKit
import MapKit
import CoreLocation
import NVActivityIndicatorView
import Firebase

class HomeViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    // map related
    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager()
    var userPinView: MKAnnotationView!
    
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var onlineStatusButton: RoundButton!
    @IBOutlet weak var totalDrivingTimeBtn: RoundButton!
    @IBOutlet weak var lightbulbButton: UIButton!
    @IBOutlet weak var goOnlineButton: RoundButton!
    
    @IBOutlet weak var totalEarnedBtn: RoundButton! // TODO: fix with variable
    
    @IBOutlet weak var searchingView: UIView!
    @IBOutlet weak var acceptDeliveryView: UIView!
    @IBOutlet weak var bottomView: UIView!
    
    // for acceptdeliveryview
    @IBOutlet weak var marketName: UILabel!
    @IBOutlet weak var marketAddress: UILabel!
   
    // 1st order
    @IBOutlet weak var viewOrder0: UIView!
    @IBOutlet weak var stackOrder0: UIStackView!
    @IBOutlet weak var checkOrder0: UIButton!
    @IBOutlet weak var nameOrder0: UILabel!
    @IBOutlet weak var numOrder0: UILabel!
    @IBOutlet weak var moneyOrder0: UILabel!
    // 2nd order (might not be displayed)
    @IBOutlet weak var viewOrder1: UIView!
    @IBOutlet weak var stackOrder1: UIStackView!
    @IBOutlet weak var checkOrder1: UIButton!
    @IBOutlet weak var nameOrder1: UILabel!
    @IBOutlet weak var numOrder1: UILabel!
    @IBOutlet weak var moneyOrder1: UILabel!
    
    private var orders = [Order]()
    private var orderRefs = [DocumentReference]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchingView.alpha = 0
        bottomView.alpha = 0
        acceptDeliveryView.alpha = 0
        acceptDeliveryView.cornerRadius(cornerRadius: 15)
        acceptDeliveryView.dropShadow()
        
        // check for location service
        mapView.delegate = self
        mapView.showsUserLocation = true
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.startUpdatingLocation()
        }

        // zoom in to current location
        if let userLocation = locationManager.location?.coordinate {
            print("update loc")
            let viewRegion = MKCoordinateRegion(center: userLocation, latitudinalMeters: 200, longitudinalMeters: 200)
            mapView.setRegion(viewRegion, animated: true)
        }
        
        // set radius
        goOnlineButton.cornerRadius = 25
        onlineStatusButton.cornerRadius = 25
        totalEarnedBtn.cornerRadius = 25
        
        switchOnlineStatus("offline")
        
        configureTimer()
        loadDeliverySession()
    }
    
    func loadDeliverySession() {
        DatabaseManager.shared.retrieveCurrentSession { [weak self] (deliverySession) in
            guard let strongSelf = self else {
                return
            }
            if let deliverySession = deliverySession {
                let vc = strongSelf.storyboard?.instantiateViewController(identifier: "MapNavigationController") as! MapNavigationController
                vc.deliverySession = deliverySession
                self?.navigationController?.showDetailViewController(vc, sender: nil)
            }
        }
    }
    
    // MARK: - map configuration
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            let pin = mapView.view(for: annotation) ?? MKAnnotationView(annotation: annotation, reuseIdentifier: nil)
            pin.image = UIImage(named: "userPinImage") // set pin image to custom car
            userPinView = pin
            return pin

        }
        
        return nil
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
            print("locations = \(locValue.latitude) \(locValue.longitude)")
        }
    
    // MARK: -buttons
    @IBAction func goOnlineTapped(_ sender: UIButton) {
        sender.tapAnimation {
            self.goOnline()
        }
    }
    
    func goOnline() {
        searchingView.alpha = 1
        searchingView.isHidden = false
        bottomView.alpha = 1
        bottomView.isHidden = false
        
        // switch on/offline status
        switchOnlineStatus("online")
        
        // add loading animation
        let loading = NVActivityIndicatorView(frame: .zero, type: .ballPulse, color: UIColor(named: "GreenTheme"), padding: 0)
        loading.translatesAutoresizingMaskIntoConstraints = false
        searchingView.addSubview(loading)
        NSLayoutConstraint.activate([
            loading.widthAnchor.constraint(equalToConstant: 50),
            loading.heightAnchor.constraint(equalToConstant: 50),
            loading.centerXAnchor.constraint(equalTo: searchingView.centerXAnchor),
            loading.bottomAnchor.constraint(equalTo: searchingView.bottomAnchor, constant: 16)
        ])
        
        loading.startAnimating()
        
        startRetrievingOrders()
        
        // auto offline if no orders after 20 sec
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 20) {
            if(self.acceptDeliveryView.alpha == 0 && self.orders.count == 0) {
                loading.stopAnimating()
                
                self.searchingView.alpha = 0
                self.bottomView.alpha = 0
                
                self.switchOnlineStatus("offline")
            }
        }
    }
    
    
    // MARK: - Accept Order pop-up

    func startRetrievingOrders() {
        
        // clear last retrieved
        self.orders.removeAll()
        self.orderRefs.removeAll()
        
        DatabaseManager.shared.retrieveSortedMarkets(locationManager.location!) { (sortedMarkets) in
            
            DatabaseManager.shared.retrieveOrders(self.locationManager.location!, marketIdx: 0,  sortedMarkets) { (order, orderRef) in
                self.orders.append(order)
                self.orderRefs.append(orderRef)
                
                // show pop up
                DispatchQueue.main.async {
                    print("orders size is \(self.orders.count)")

                    self.displayOrders()
                }
            }
        }
    }
    
    /// switch on/off checker
    @IBAction func checkOrder(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
    }
    
    /// show orders pop up
    private func displayOrders() {
        if(!orders.isEmpty){
            self.switchOnlineStatus("online") // avoid auto update back to offline
            
            popInAnimation()
            
            // draw border for order stack
            viewOrder0.dropShadow()
            viewOrder0.cornerRadius(cornerRadius: 15)
            viewOrder1.dropShadow()
            viewOrder1.cornerRadius(cornerRadius: 15)

        
            let order0 = orders[0]
            marketName.text = order0.marketName
            marketAddress.text = order0.marketAddressTitle
            
            nameOrder0.text = order0.customer.firstName + " " + order0.customer.lastName
            numOrder0.text = order0.numOfItems > 1 ? "\(order0.numOfItems) items" : "\(order0.numOfItems) item"
            moneyOrder0.text = String(format: "$%.2f", order0.totalEarned)
        
            if(orders.count > 1){
                viewOrder1.alpha = 1 // show stack in case it's not shown
                
                let order1 = orders[1]
                nameOrder1.text = order1.customer.firstName + " " + order1.customer.lastName
                numOrder1.text = order1.numOfItems > 1 ? "\(order1.numOfItems) items" : "\(order1.numOfItems) item"
                moneyOrder1.text = String(format: "$%.2f", order1.totalEarned)
            }
            else{
                viewOrder1.alpha = 0 // if only 1 order, hide 2nd stack
            }
        }
    }
    
    @IBAction func acceptOrderTapped(_ sender: UIButton) {
        sender.tapAnimation {
            self.acceptOrder()
        }
    }
    
    @IBAction func declineOrderTapped(_ sender: UIButton) {
        sender.tapAnimation {
            self.declineOrder()
        }
    }
    
    func acceptOrder() {
        // do nothing if none of orders are checked
        if(!checkOrder0.isSelected && !checkOrder1.isSelected){
            return
        }
        
        // save orders to driver active orders
        if(checkOrder0.isSelected && checkOrder1.isSelected) {
            DatabaseManager.shared.addDeliverySession(marketID: orders[0].marketId, order1ID: orders[0].id, order2ID: orders[1].id)
            acceptSingleOrder(0)
            acceptSingleOrder(1)
        }
        else if(checkOrder0.isSelected) {
            DatabaseManager.shared.addDeliverySession(marketID: orders[0].marketId, order1ID: orders[0].id, order2ID: nil)
            acceptSingleOrder(0)
            
            // update delivery status back to created
            if(orders.count > 1){
                DatabaseManager.shared.updateOrderStatus(status: "created", orderRef: orderRefs[1])
            }
        }
        else if (checkOrder1.isSelected) {
            DatabaseManager.shared.addDeliverySession(marketID: orders[0].marketId, order1ID: nil, order2ID: orders[1].id)
            acceptSingleOrder(1)
            
            // update delivery status back to created
            DatabaseManager.shared.updateOrderStatus(status: "created", orderRef: orderRefs[0])
        }
        
        // start chat with customer
        popOutAnimation("accept")
        
        // go to next controller
        let vc = self.storyboard?.instantiateViewController(identifier: "MapNavigationController") as! UINavigationController
        self.navigationController?.showDetailViewController(vc, sender: nil)
    }
    
    func acceptSingleOrder(_ orderIdx: Int) {
        print("accepting order \(orderIdx)...")
        
        // update delivery status to accepted
        DatabaseManager.shared.updateOrderStatus(status: "accepted", orderRef: orderRefs[orderIdx])
        
        // load clock icon
        loadTimerIcon()
        startTimer() // recording how many time spend on current delivery session
        
        print("order \(orderIdx) accepted!")
    }
    
    func declineOrder() {
        print("decline all orders")
        
        // update delivery status to created
        for ref in orderRefs {
            DatabaseManager.shared.updateOrderStatus(status: "created", orderRef: ref)
        }
        
        popOutAnimation("decline")
        
        updateEarned(amount: 30)
    }
    
    // MARK: - Timer related
    
    var timer = Timer()
    var hours: Int = 0
    var minutes: Int = 0
    var iconString = NSAttributedString()
    
    func loadTimerIcon () {
        let clockIcon = NSTextAttachment()
        clockIcon.image = UIImage(systemName: "clock")?.withRenderingMode(.alwaysTemplate)
        clockIcon.image = clockIcon.image?.withTintColor(UIColor.lightGray) //set icon to grey
        // set bound to reposition
        clockIcon.bounds = CGRect(x: 0, y: -5.0, width: clockIcon.image!.size.width, height: clockIcon.image!.size.height)
        iconString = NSAttributedString(attachment: clockIcon) // create string from icon
    }
    
    /// update timer (total driving time)
    func configureTimer() {
        let timerText = NSAttributedString(string: String(format: "%02d", hours) + ":" + String(format: "%02d", minutes))
        
        let completeText = NSMutableAttributedString(string:"")
        completeText.append(iconString)
        completeText.append(NSAttributedString(string: " "))
        completeText.append(timerText)
        
        totalDrivingTimeBtn.setAttributedTitle(completeText, for: .normal)
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(timerCounter), userInfo: nil, repeats: true) // 1 min as interval
    }
    
    func stopTimer() {
        timer.invalidate()
        minutes = 0
        hours = 0
        configureTimer()
    }
    
    @objc func timerCounter() {
        // update every 1 min
        minutes += 1
        if(minutes == 60) {
            minutes = 0
            hours += 1
        }
        if(hours == 24){
            alertOverTime()
            stopTimer()
            return
        }
        configureTimer()
    }
    
    /// an alert notifying driver who has been driving 24 hrs
    func alertOverTime() {
        let alert = UIAlertController(title: "Drive about 24 hours", message: "Have a rest!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OKAY", style: .cancel, handler: { (_) in
            // do nothing
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: -configuration helpers
    
    func configureRoundButtons(_ button: UIButton) {
        button.layer.cornerRadius = button.frame.size.height / 2
    }
    
    /// switch on/offline status
    func switchOnlineStatus(_ state: String) {
        if (state == "online"){
            onlineStatusButton.setTitle("online", for: .normal)
            onlineStatusButton.backgroundColor = UIColor(named: "GreenTheme")
            onlineStatusButton.setTitleColor(.white, for: .normal)
        }
        else{
            onlineStatusButton.setTitle("offline", for: .normal)
            onlineStatusButton.backgroundColor = .white
            onlineStatusButton.setTitleColor(UIColor(named: "GreenTheme"), for: .normal)
            
//            onlineStatusButton.borderWidth = 1
//            onlineStatusButton.borderColor = UIColor(named: "GreenTheme")!
        }
    }
    
    // MARK: - Driver total earned
    var driverEarned: Double = 0
    
    func updateEarned(amount: Double) {
        driverEarned += amount
        totalEarnedBtn.setAttributedTitle(NSAttributedString(string: String(format: "$%.2f", driverEarned)), for: .normal)
    }
    
    // MARK: - pop in/out functions
    
    func popInAnimation() {
        searchingView.alpha = 0
        bottomView.alpha = 0
        goOnlineButton.alpha = 0
        
        // make the pop up invisible and scale it to 0.5x
        acceptDeliveryView.alpha = 0
        acceptDeliveryView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        UIView.animate(withDuration: 0.5, delay: 0.5, usingSpringWithDamping: 0.55, initialSpringVelocity: 3, options: .curveEaseOut, animations: {
            self.acceptDeliveryView.alpha = 1
            self.acceptDeliveryView.transform = .identity
        }, completion: nil)
    }
    
    func popOutAnimation(_ action: String) {
        UIView.animate(
            withDuration: 0.5, delay: 0.5, usingSpringWithDamping: 0.55, initialSpringVelocity: 3,
            options: .curveEaseOut, animations: {
                self.acceptDeliveryView.alpha = 0
                self.acceptDeliveryView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            }, completion: { w in
                self.checkOrder0.isSelected = false
                self.checkOrder1.isSelected = false
                self.goOnlineButton.alpha = 1
                if(action == "decline") {
                    self.switchOnlineStatus("offline")
                }
            })
    }
    
    @IBAction func profileButtonPressed(_ sender: UIButton) {
        sender.tapAnimation {
            do {
                try Auth.auth().signOut()
                let vc = self.storyboard?.instantiateViewController(identifier: "InitialWelcomeNavigationController") as! UINavigationController
                self.navigationController?.showDetailViewController(vc, sender: nil)
            } catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
            }
        }
    }
}
