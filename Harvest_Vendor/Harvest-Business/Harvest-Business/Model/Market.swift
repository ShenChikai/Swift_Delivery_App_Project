//
//  Market.swift
//  Harvest-Business
//
//  Created by Zixuan Li on 2021/4/11.
//

import Foundation
import UIKit
import Firebase

class Market {
    
    var image: UIImage?
    var title: String = "default"
    var description : String = "description goes here"
    var ratings : Double = 5
    var distance : Double = 0
    var image_url = String()
    var lat : Double = 0
    var lon : Double = 0
    var address: String = "default address"
    var isSaved: Bool = false
    var ref: DocumentReference?
    var marketID = String()
    
    init() {}
    
    // for driver
    init(title: String, address: String, lat: Double, lon: Double, distance: Double, marketID: String){
        self.title = title
        self.address = address
        self.lat = lat
        self.lon = lon
        self.distance = distance
        self.marketID = marketID
    }
    
    init(image: UIImage? = nil, title: String = "default", description: String = "description goes here", ratings: Double = 5, distance: Double, image_url: String = String(), lat: Double = 0, lon: Double = 0, address: String, isSaved: Bool = false, ref: DocumentReference? = nil, marketID: String = "") {
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
    }
    
    func invertSavedStatus() {
        isSaved = !isSaved
    }
    
}
