//
//  MapViewController.swift
//  Harvest-Business
//
//  Created by Lihan Zhu on 2021/2/12.
//

import UIKit
import MapKit
import CoreLocation
import Firebase
import FirebaseUI
import FirebaseAuth
import NVActivityIndicatorView

class MapViewController: UIViewController {
    
    private static let TABLE_VIEW_CELL_IDENTIFIER = "TableViewCell"
    private static let DESTINATION_RADIUS = 20.0

    @IBOutlet weak var destinationTableView: UITableView!
    @IBOutlet weak var destinationsView: UIView!
    @IBOutlet weak var customerImageView: UIImageView!
    @IBOutlet weak var customerNameLabel: UILabel!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var constraintTableViewHeight: NSLayoutConstraint!
    
    // Popup view
    @IBOutlet weak var completeOrderView: UIView!
    @IBOutlet weak var completeOrderAddressLabel: UILabel!
    @IBOutlet weak var completeOrderButton: RoundButton!
    
    let activityIndicator = NVActivityIndicatorView(frame: .zero, type: .ballRotateChase, color: UIColor(named: "GreenTheme"), padding: 0)
    
    let storageRef = Storage.storage().reference()
    
    private let locationManager = CLLocationManager()
    private let regionInMeters: Double = 10000
    
    var deliverySession: DeliverySession?
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        destinationsView.layer.cornerRadius = 20
        destinationsView.clipsToBounds = true
        
        customerImageView.layer.cornerRadius = 15
        customerImageView.clipsToBounds = true
        
        mapView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        destinationTableView.delegate = self
        destinationTableView.dataSource = self
        mapView.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        
        setupPopupView()
        setupActivityIndicator()
        setupLocationServices()
        loadDeliverySession()
    }
    
    // MARK: - Activity indicator
    
    func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.widthAnchor.constraint(equalToConstant: 50),
            activityIndicator.heightAnchor.constraint(equalToConstant: 50),
            activityIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
    }
    
    // MARK: Popup view
    
    /// Setup popup view and hide it initially
    func setupPopupView() {
        completeOrderView.dropShadow()
        completeOrderView.cornerRadius(cornerRadius: 15)
        completeOrderView.alpha = 0
    }
    
    /// Show popup view depending on the current destination
    func showPopupView() {
        guard let currentDestination = deliverySession?.currentDestination else {
            print("MapViewController - showPopupView: no current destination")
            return
        }
        // Configure button text and action depending on destination type
        let buttonText: String = {
            switch currentDestination.type {
            case .market:
                return "Pick Up Orders"
            case .customer:
                return "Complete Order"
            }
        }()
        switch currentDestination.type {
        case .market:
            self.completeOrderButton.addTarget(self, action: #selector(pickUpOrdersPressed(_:)), for: .touchUpInside)
        case .customer:
            self.completeOrderButton.addTarget(self, action: #selector(completeCurrentOrderPressed(_:)), for: .touchUpInside)
        }
        completeOrderButton.isEnabled = true
        
        DispatchQueue.main.async {
            self.completeOrderAddressLabel.text = currentDestination.displayName
            self.completeOrderView.alpha = 0
            self.completeOrderButton.setTitle(buttonText, for: .normal)
            self.completeOrderView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            
            UIView.animate(withDuration: 0.5, delay: 0.5, usingSpringWithDamping: 0.55, initialSpringVelocity: 3, options: .curveEaseOut, animations: {
                self.completeOrderView.alpha = 1
                self.completeOrderView.transform = .identity
            }, completion: nil)
        }
    }
    
    /// Dismiss popup view and call completion when animation ends
    func dismissPopupView(completion: ((Bool) -> Void)?) {
        self.completeOrderButton.removeTarget(nil, action: nil, for: .allEvents)
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5, delay: 0.5, usingSpringWithDamping: 0.55, initialSpringVelocity: 3,options: .curveEaseOut, animations: {
                self.completeOrderView.alpha = 0
                self.completeOrderView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            }, completion: completion)
        }
    }
    
    @objc func pickUpOrdersPressed(_ sender: UIButton) {
        sender.tapAnimation {
            self.pickUpOrders()
        }
    }
    
    func pickUpOrders() {
        guard let deliverySession = deliverySession else {
            print("MapViewController - pickUpOrders: no delivery session found")
            return
        }
        print("Pick up orders")
        // Redirect to active orders VC
        let vc = self.storyboard?.instantiateViewController(identifier: "activeOrdersVC") as! ActiveOrdersViewController
        vc.allOrders = deliverySession.orders
        vc.deliverySession = deliverySession
        vc.completion = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.dismissPopupView { (completed) in
                strongSelf.reloadDestinations()
            }
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func completeCurrentOrderPressed(_ sender: UIButton) {
        sender.tapAnimation {
            self.completeCurrentOrder()
        }
    }
    
    func completeCurrentOrder() {
        print("Complete order")
        startMonitoringCurrentDestination()
        reloadDestinations()
        dismissPopupView { [weak self] (completed) in
            guard completed, let strongSelf = self else {
                return
            }
            guard let deliverySession = strongSelf.deliverySession else {
                return
            }
            // Increment step in database
            DatabaseManager.shared.incrementCurrentSessionStep(id: deliverySession.id) {
                deliverySession.incrementStep()
                // Check if all orders are completed
                if deliverySession.completed {
                    print("All orders completed")
                    DatabaseManager.shared.resetCurrentSession()
                    // Redirect to home
                    let vc = strongSelf.storyboard?.instantiateViewController(identifier: "HomeNavigationController") as! UINavigationController
                    strongSelf.navigationController?.showDetailViewController(vc, sender: nil)
                } else {
                    print("One destination arrived")
                }
            }
        }
    }
    
    // MARK: - Chat button
    
    @IBAction func buttonChatPressed(_ sender: UIButton) {
        guard let deliverySession = deliverySession, let currentOrder = deliverySession.currentOrder else {
            return
        }
        let vc = self.storyboard?.instantiateViewController(identifier: "ChatViewController") as! ChatViewController
        vc.title = currentOrder.customer.firstName
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.user2Name = currentOrder.customer.firstName
        vc.user2ID = currentOrder.customerId
        vc.user2Img_url = currentOrder.customer.imageUrl
        vc.user2PhoneNum = currentOrder.customer.phoneNum
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Location services
    
    func setupLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            checkLocationAuthorization()
        } else {
            
        }
    }
    
    func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedAlways:
            showLocation()
            break
        case .authorizedWhenInUse:
            showLocation()
            break
        case .denied:
            // Show alert instructing user how to turn on location
            break
        case .restricted:
            // Show alert to let user know what happened
            break
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            break
        default:
            print("Unknown authorization status")
        }
    }
    
    func showLocation() {
        mapView.showsUserLocation = true
        // Center on user's current location
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
        // Update location when user moves
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - Delivery destinations data
    
    /// Retrieve destinations of the current orders
    func loadDeliverySession() {
        if deliverySession != nil {
            reloadDestinations()
            return
        }
        activityIndicator.startAnimating()
        DatabaseManager.shared.retrieveCurrentSession { [weak self] (deliverySession) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.activityIndicator.stopAnimating()
            guard let deliverySession = deliverySession else {
                print("MapViewController - loadDeliverySession: no current delivery session found")
                return
            }
            strongSelf.deliverySession = deliverySession
            strongSelf.reloadDestinations()
        }
    }
    
    /// Reload data and adjust height
    func reloadDestinations() {
        print("MapViewController - reloadDestinations: with step \(deliverySession?.step ?? -1)")
        resetDirectionOnMap()
        showDirectionOnMap()
        DispatchQueue.main.async {
            // Update table view height according to number of destinations
            self.destinationTableView.reloadData()
            self.constraintTableViewHeight.constant = self.destinationTableView.contentSize.height
        }
        reloadCurrentCustomer()
    }
    
    /// Reload customer's name and image
    func reloadCurrentCustomer() {
        // Update customer info
        guard let currentOrder = deliverySession?.currentOrder else {
            return
        }
        // Load customer image
        let imgRef = storageRef.child(currentOrder.customer.imageUrl)
        let placeholderImg = UIImage(named: "placeholder")
        customerImageView.sd_setImage(with: imgRef, placeholderImage: placeholderImg)
        // Update customer name
        DispatchQueue.main.async {
            self.customerNameLabel.text = currentOrder.customer.firstName
        }
    }
    
    // MARK: - Directions
    
    /// Show direction to the current order from current location
    func showDirectionOnMap() {
        guard let location = locationManager.location?.coordinate, let currentDestination = deliverySession?.currentDestination else {
            print("Failed to get location")
            return
        }
        let request = createDirectionRequest(sourceCoordinate: location, destinationCoordinate: currentDestination.coordinate)
        let directions = MKDirections(request: request)
        
        directions.calculate { [weak self] (response, error) in
            guard let strongSelf = self else {
                return
            }
            if let error = error {
                print("Error calculating direction: \(error)")
                return
            }
            guard let response = response else {
                print("Error getting response")
                return
            }
            // Display the first route
            if let route = response.routes.first {
                strongSelf.mapView.addOverlay(route.polyline)
                strongSelf.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16), animated: true)
                
                // Start monitoring
                strongSelf.startMonitoringCurrentDestination()
            }
        }
    }
    
    /// Remove all current directions
    func resetDirectionOnMap() {
        mapView.removeOverlays(mapView.overlays)
    }
    
    /// Generate a direction request from source to destination
    func createDirectionRequest(sourceCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) -> MKDirections.Request {
        let source = MKPlacemark(coordinate: sourceCoordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: source)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes = false
        
        return request
    }
    
    /// Start monitoring all destinations for orders
    func startMonitoringCurrentDestination() {
        for monitoredRegion in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: monitoredRegion)
        }
        guard let deliverySession = deliverySession, let currentDestination = deliverySession.currentDestination else {
            return
        }
        let region = CLCircularRegion(center: currentDestination.coordinate, radius: MapViewController.DESTINATION_RADIUS, identifier: "IDENTIFIER")
        locationManager.startMonitoring(for: region)
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

// MARK: - TableView Delegates

extension MapViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

extension MapViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deliverySession?.remainingDestinations.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MapViewController.TABLE_VIEW_CELL_IDENTIFIER, for: indexPath) as! DestinationTableViewCell
        guard let deliverySession = deliverySession else {
            return cell
        }
        if indexPath.row < deliverySession.remainingDestinations.count {
            let destination = deliverySession.remainingDestinations[indexPath.row]
            if indexPath.row == 0 {
                cell.labelNumber.backgroundColor = UIColor(named: "GreenTheme")
            }
            cell.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
            cell.labelNumber.text = String(indexPath.row + 1)
            cell.labelDestination.text = destination.displayName
        }
        return cell
    }
    
}

// MARK: - CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        // Center mapView
        let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let region = MKCoordinateRegion.init(center: center, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        mapView.setRegion(region, animated: true)
        
        // Update driver location
        DatabaseManager.shared.updateDriverLocation(lat: lat, lon: lon)
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        print("didDetermineState: \(state)")
        switch state {
        case .inside:
            showPopupView()
        case .outside: break
        case .unknown: break
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
    
}

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor(named: "GreenTheme")
        renderer.lineWidth = 5
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            let pin = mapView.view(for: annotation) as? MKPinAnnotationView ?? MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
            pin.image = UIImage(systemName: "car.fill")
            pin.tintColor = UIColor(named: "GreenTheme")
            return pin
        }
        return nil
    }
}

extension MapViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let navVc = navigationController {
            return navVc.viewControllers.count > 1
        }
        return false
    }
}
