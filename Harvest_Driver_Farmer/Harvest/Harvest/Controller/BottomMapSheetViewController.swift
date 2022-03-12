//
//  BottomMapSheetViewController.swift
//  Harvest
//
//  Created by Lihan Zhu on 2021/4/9.
//

import UIKit
import MapKit
import Firebase

class BottomMapSheetViewController: UIViewController {
    
    @IBOutlet weak var topDivider: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var destinationTableView: UITableView!
    @IBOutlet weak var constraintTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var driverNameLabel: UILabel!
    @IBOutlet weak var driverImageView: UIImageView!
    
    // View heights for swipe up
    var fullView: CGFloat {
        let statusBarHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        return 10 + statusBarHeight
    }
    var partialView: CGFloat {
        return UIScreen.main.bounds.height - 140
    }
    var nonView: CGFloat {
        return UIScreen.main.bounds.height
    }
    
    // Current order. Always loaded by parent
    var order: Order!
    var destinations: [String] = []
    let driverAnnotation = MKPointAnnotation()
    // Listeners
    var driverListner: ListenerRegistration?
    var deliverySessionListener: ListenerRegistration?
    // Storage for images
    let storageRef = Storage.storage().reference()
    // Map kit
    private let regionInMeters: Double = 10000
    
    // MARK: - Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Top divider
        topDivider.cornerRadius(cornerRadius: 1)
        // Pan gesture recognizer
        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(panGesture))
        view.addGestureRecognizer(gesture)
        // Map view
        mapView.delegate = self
        mapView.addAnnotation(driverAnnotation)
        driverAnnotation.title = "Driver location"
        // TableView
        destinationTableView.dataSource = self
        destinationTableView.delegate = self
        
        loadData()
        setupListeners()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        prepareBackgroundView()
        view.dropShadow()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.6, animations: { [weak self] in
            let frame = self?.view.frame
            let yComponent = self?.partialView
            self?.view.frame = CGRect(x: 0, y: yComponent!, width: frame!.width, height: frame!.height)
        })
    }
    
    deinit {
        driverListner?.remove()
        deliverySessionListener?.remove()
    }
    
    // MARK: - Data
    
    func loadData() {
        let driver = order.driver
        driverNameLabel.text = driver.firstName
        // Load driver image
        let imgRef = storageRef.child(driver.imageUrl)
        let placeholderImg = UIImage(named: "placeholder")
        driverImageView.sd_setImage(with: imgRef, placeholderImage: placeholderImg)
    }
    
    func setupListeners() {
        driverListner = DatabaseManager.shared.listenToDriverLocation(order: order, completion: { [weak self] (lat, lon) in
            guard let strongSelf = self else {
                return
            }
            // Update driver coordinate
            strongSelf.order.driver.lat = lat
            strongSelf.order.driver.lon = lon
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            strongSelf.driverAnnotation.coordinate = coordinate
        })
        deliverySessionListener = DatabaseManager.shared.listenToDeliverySession(order: order, completion: { [weak self] (orderState) in
            guard let strongSelf = self else {
                return
            }
            switch orderState {
            case .accepted:
                strongSelf.destinations = [
                    strongSelf.order.market.title,
                    strongSelf.order.customerAddress.title
                ]
                strongSelf.showDirectionOnMap(to: strongSelf.order.market.coordinate)
            case .toOther:
                strongSelf.destinations = [
                    "On the way to other customers",
                    strongSelf.order.customerAddress.title
                ]
                strongSelf.showDirectionOnMap(to: strongSelf.order.customerAddress.coordinate)
            case .toYou:
                strongSelf.destinations = [
                    strongSelf.order.customerAddress.title
                ]
                strongSelf.showDirectionOnMap(to: strongSelf.order.customerAddress.coordinate)
            case .arrived:
                strongSelf.destinations = [
                    "Your order has been delivered"
                ]
                strongSelf.resetDirectionOnMap()
            }
            strongSelf.centerMapView(to: strongSelf.order.driver.coordinate)
            DispatchQueue.main.async {
                strongSelf.destinationTableView.reloadData()
                strongSelf.constraintTableViewHeight.constant = strongSelf.destinationTableView.contentSize.height
            }
        })
    }
    
    // MARK: - Swipe up UI
    
    @objc func panGesture(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.view)
        let velocity = recognizer.velocity(in: self.view)
        let y = self.view.frame.minY
        if ( y + translation.y >= fullView) && (y + translation.y <= partialView ) {
            self.view.frame = CGRect(x: 0, y: y + translation.y, width: view.frame.width, height: view.frame.height)
            recognizer.setTranslation(CGPoint.zero, in: self.view)
        }
        
        if recognizer.state == .ended {
            var duration =  velocity.y < 0 ? Double((y - fullView) / -velocity.y) : Double((partialView - y) / velocity.y )
            
            duration = duration > 1.3 ? 1 : duration
            
            UIView.animate(withDuration: duration, delay: 0.0, options: [.allowUserInteraction], animations: {
                if  velocity.y >= 0 {
                    self.view.frame = CGRect(x: 0, y: self.partialView, width: self.view.frame.width, height: self.view.frame.height)
                } else {
                    self.view.frame = CGRect(x: 0, y: self.fullView, width: self.view.frame.width, height: self.view.frame.height)
                }
                
            }, completion: nil)
        }
    }
    
    func prepareBackgroundView(){
        let blurEffect = UIBlurEffect.init(style: .light)
        let visualEffect = UIVisualEffectView.init(effect: blurEffect)
        let bluredView = UIVisualEffectView.init(effect: blurEffect)
        bluredView.contentView.addSubview(visualEffect)
        
        visualEffect.frame = UIScreen.main.bounds
        bluredView.frame = UIScreen.main.bounds
        
        view.insertSubview(bluredView, at: 0)
    }
    
    // MARK: - Clean up
    
    /// Remove bottom sheet
    func dismissSheet() {
        UIView.animate(withDuration: 0.6, animations: { [weak self] in
            let frame = self?.view.frame
            let yComponent = self?.nonView
            self?.view.frame = CGRect(x: 0, y: yComponent!, width: frame!.width, height: frame!.height)
        }) { (finished) in
            if finished {
                self.willMove(toParent: nil)
                self.view.removeFromSuperview()
                self.removeFromParent()
            }
        }
    }
    
    @IBAction func chatButtonPressed(_ sender: UIButton) {
        let vc = self.storyboard?.instantiateViewController(identifier: "ChatVC") as! ChatViewController
        vc.title = order.driver.firstName
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.user2Name = order.driver.firstName
        vc.user2ID = order.driverId
        vc.user2Img_url = order.driver.imageUrl
        vc.user2PhoneNum = order.driver.phoneNum
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Map direction
    
    /// Show direction from driver to customer
    func showDirectionOnMap(to location: CLLocationCoordinate2D) {
        resetDirectionOnMap()
        let driverLocation = order.driver.coordinate
        
        let request = createDirectionRequest(sourceCoordinate: driverLocation, destinationCoordinate: location)
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
            }
        }
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
    
    /// Remove all current directions
    func resetDirectionOnMap() {
        mapView.removeOverlays(mapView.overlays)
    }
    
    func centerMapView(to center: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion.init(center: center, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        mapView.setRegion(region, animated: true)
    }
}

// MARK: - TableView Delegates

extension BottomMapSheetViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

extension BottomMapSheetViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return destinations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as! DestinationTableViewCell
        if indexPath.row < destinations.count {
            if indexPath.row == 0 {
                cell.labelNumber.backgroundColor = UIColor(named: "GreenTheme")
            }
            cell.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
            cell.labelNumber.text = String(indexPath.row + 1)
            cell.labelDestination.text = destinations[indexPath.row]
        }
        return cell
    }
    
}


// MARK: - MKMapViewDelegate

extension BottomMapSheetViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor(named: "GreenTheme")
        renderer.lineWidth = 5
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let pin = mapView.view(for: annotation) as? MKPinAnnotationView ?? MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
        pin.image = UIImage(systemName: "car.fill")
        pin.tintColor = UIColor(named: "GreenTheme")
        return pin
    }
}
