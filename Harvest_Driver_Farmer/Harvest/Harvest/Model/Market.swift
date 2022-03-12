//
//  MarketItem.swift
//  Harvest
//

import Foundation
import UIKit
import Firebase
import CoreLocation

class Market {
    
    var image: UIImage?
    var title: String = "default"
    var description : String = "description goes here"
    var ratings : Double = 5
    var distance : String = "3 miles"
    var image_url = String()
    var lat : Double = 0
    var lon : Double = 0
    var isSaved: Bool = false
    var ref: DocumentReference?
    var marketID = String()
    
    init() {}
    
    init(image: UIImage? = nil, title: String = "default", description: String = "description goes here", ratings: Double = 5, distance: String = "3 miles", image_url: String = String(), lat: Double = 0, lon: Double = 0, isSaved: Bool = false, ref: DocumentReference? = nil, marketID: String = "") {
        self.image = image
        self.title = title
        self.description = description
        self.ratings = ratings
        self.distance = distance
        self.image_url = image_url
        self.lat = lat
        self.lon = lon
        self.isSaved = isSaved
        self.ref = ref
        self.marketID = marketID
    }
    
    func invertSavedStatus() {
        isSaved = !isSaved
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
//    init(){}
//    init(image: UIImage? = nil, title: String, description: String, ratings: Double, distance: String) {
//        self.image = image
//        self.title = title
//        self.description = description
//        self.ratings = ratings
//        self.distance = distance
//    }
}
