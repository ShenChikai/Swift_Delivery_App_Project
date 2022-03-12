//
//  MarketsCollectionViewController.swift
//  Harvest
//
//  Created by Lihan Zhu on 2021/2/28.
//  Modified by Zixuan Li on 2021/3/10

import UIKit
import FirebaseUI
import MapKit
import GeoFire
import CoreLocation

class MarketsCollectionViewController: UIViewController {
    
    @IBOutlet weak var activeAddress: RoundButton!
    
    let storageRef = Storage.storage().reference()
    
    @IBOutlet weak var collectionView: UICollectionView!

    private let options = [
        Market(image: UIImage(named:"Silverlake"), title: "Silverlake Farmers Market", description: "A description goes here", ratings: 0, distance:"3 miles away"),
        Market(image: UIImage(named:"Target"), title: "Target Market",
                   description: "A description goes here", ratings: 0, distance:"3 miles away"),
        Market(image: UIImage(named:"TraderJoe"), title: "Trader Joe's Market",
                   description: "A description goes here", ratings: 0, distance:"3 miles away")
    ]
    
    private let sectionTitles = ["Your Favorites", "Nearby"]
    private var savedMarkets = [Market]()
    private var allMarkets = [Market]()
    private var nearbyMarkets = [Market]()
    private var activeAddressText = "Unknown"
    private var myLat = 34.0224
    private var myLon = 118.2851

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        
        let nib = UINib(nibName: "MarketsCollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "MyCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // load active addr
        DatabaseManager.shared.retrieveActiveAddress { [weak self] (title, subtitle, lat, lon, apt, building, instruction) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.activeAddressText =  title
            strongSelf.myLat =  lat
            strongSelf.myLon =  lon
            DispatchQueue.main.async{
                strongSelf.activeAddress.setTitle(strongSelf.activeAddressText, for: .normal)
            }
        }
        
        // load nearby markets
        DispatchQueue.main.async{
            self.allMarkets = []
            self.nearbyMarkets = []
            let radiusInKilometers: Double = 20     // SET TO SEARCH FOR MARKETS WITHIN 20km
            DatabaseManager.shared.retrieveAllMarkets { [weak self] (market) in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.allMarkets.append(market)
                // NOTE!: hard coded all market count == 5
                if (strongSelf.allMarkets.count == 5) {
                    for market in strongSelf.allMarkets {
                        let lat = market.lat as Double
                        let lon = market.lon as Double
                        let coordinates = CLLocation(latitude: lat, longitude: lon)
                        let centerPoint = CLLocation(latitude: strongSelf.myLat, longitude: strongSelf.myLon)
                        // We have to filter out a few false positives due to GeoHash accuracy, but
                        // most will match
                        let distance = centerPoint.distance(from: coordinates)/1000
                        if distance <= radiusInKilometers {
                            market.distance = String(format: "%.1f", distance*0.621) + " miles"
                            strongSelf.nearbyMarkets.append(market)
                            print("found market:", market.title)
                            print("distance: ", distance)
                        }
                    }
                }
                
                strongSelf.collectionView.reloadData()
            }
        }
        
        // Load saved markets
        savedMarkets = []
        DatabaseManager.shared.retrieveSavedMarkets { [weak self] (market) in
            guard let strongSelf = self else {
                return
            }
            let coordinates = CLLocation(latitude: market.lat, longitude: market.lon)
            let centerPoint = CLLocation(latitude: strongSelf.myLat, longitude: strongSelf.myLon)
            // We have to filter out a few false positives due to GeoHash accuracy, but
            // most will match
            let distance = centerPoint.distance(from: coordinates)/1000
            market.distance = String(format: "%.1f", distance*0.621) + " miles"
            strongSelf.savedMarkets.append(market)
            DispatchQueue.main.async {
                strongSelf.collectionView.reloadData()
            }
        }
        
        loadCurrentOrder()
    }
    
    /// Setup and display the bottom sheet view
    func setupBottomSheetView(order: Order) {
        let vc = self.storyboard?.instantiateViewController(identifier: "BottomMapSheetViewController") as! BottomMapSheetViewController
        vc.order = order
        self.addChild(vc)
        self.view.addSubview(vc.view)
        vc.didMove(toParent: self)
        
        let height = view.frame.height
        let width = view.frame.width
        vc.view.frame = CGRect(x: 0, y: self.view.frame.maxY, width: width, height: height)
    }
    
    /// Check if current user has an order on delivery
    func loadCurrentOrder() {
        DatabaseManager.shared.retrieveCurrentOrder { [weak self] (order) in
            guard let strongSelf = self else {
                return
            }
            if let order = order {
                DispatchQueue.main.async {
                    strongSelf.setupBottomSheetView(order: order)
                }
            }
        }
    }
    
    @IBAction func addressButtonPressed(_ sender: RoundButton) {
        sender.tapAnimation {
            let vc = self.storyboard?.instantiateViewController(identifier: "DeliveryAddressViewController") as! DeliveryAddressViewController
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func showMarket(market: Market) {
        DispatchQueue.main.async {
            let vc = self.storyboard?.instantiateViewController(identifier: "VendorsCollectionViewController") as! VendorsCollectionViewController
            vc.market = market
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
//    func storeGeoHash(lat: Double, lon: Double) -> Dictionary<String, Any> {
//        let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
//        let hash = GFUtils.geoHash(forLocation: location)
//        // Add the hash and the lat/lng to the document. We will use the hash
//        // for queries and the lat/lng for distance comparisons.
//        let documentData: [String: Any] = [
//            "geohash": hash,
//            "lat": lat,
//            "lng": lon
//        ]
//
//        return documentData
//    }

}

extension MarketsCollectionViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return savedMarkets.count
        case 1:
            print(nearbyMarkets.count)
            return nearbyMarkets.count
        default:
            print("Error in numberOfItemsInSection")
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionHeader", for: indexPath) as! MarketsSectionHeader
        if indexPath.section < sectionTitles.count {
            sectionHeader.sectionNameLabel.text = sectionTitles[indexPath.section]
        } else {
            print("Error in viewForSupplementaryElementOfKind")
            sectionHeader.sectionNameLabel.text = "UNKNOWN"
        }
        return sectionHeader
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath) as! MarketsCollectionViewCell
        let markets: [Market] = {
            switch indexPath.section {
            case 0:
                return savedMarkets
            case 1:
                return nearbyMarkets
            default:
                return [Market]()
            }
        }()
        
        // load image from cloud
        let imgRef = storageRef.child(markets[indexPath.item].image_url)
        let imageView: UIImageView = cell.marketImageView
        let placeholderImg = UIImage(named: "placeholder")
        imageView.sd_setImage(with: imgRef, placeholderImage: placeholderImg)
        
//        cell.marketImageView.image = UIImage(named:"placeholder")  // TODO: fix it
        cell.marketImageView.layer.cornerRadius = 10
        cell.marketImageView.clipsToBounds = true
        cell.marketNameLabel.text = markets[indexPath.item].title
        cell.descriptionLabel.text = markets[indexPath.item].description
        cell.distanceLabel.text = markets[indexPath.item].distance
        cell.saveButton.isSelected = markets[indexPath.item].isSaved
        
        // Handle market added to / deleted from saved market
        cell.market = markets[indexPath.item]
        cell.saveButtonCompletion = { [weak self] (market, isAddition) in
            guard let strongSelf = self else {
                return
            }
            if isAddition {
                // TODO: delete
                strongSelf.nearbyMarkets = strongSelf.nearbyMarkets.filter { (nearbyMarket) -> Bool in
                    return nearbyMarket.ref != market.ref
                }
                strongSelf.savedMarkets.append(market)
            } else {
                strongSelf.savedMarkets = strongSelf.savedMarkets.filter { (savedMarket) -> Bool in
                    return savedMarket.ref != market.ref
                }
                // TODO: delete
                strongSelf.nearbyMarkets.append(market)
            }
            DispatchQueue.main.async {
                strongSelf.collectionView.reloadData()
            }
        }
        cell.seeVendorButtonAction = { [weak self] (market) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.showMarket(market: market)
        }
        
        return cell
    }
    
}

extension MarketsCollectionViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView.cellForItem(at: indexPath)?.tapAnimation {
            let markets: [Market] = {
                switch indexPath.section {
                case 0:
                    return self.savedMarkets
                case 1:
                    return self.nearbyMarkets
                default:
                    return [Market]()
                }
            }()
            let market = markets[indexPath.item]
            self.showMarket(market: market)
        }
    }
    
}

extension MarketsCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        return CGSize(width: self.view.frame.width, height: 280)
    }
    
}

extension MarketsCollectionViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let navVc = navigationController {
            return navVc.viewControllers.count > 1
        }
        return false
    }

}
