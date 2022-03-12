//
//  Address.swift
//  Harvest-Business
//
//  Created by Zixuan Li on 2021/3/17.
//

import Foundation
import UIKit

struct Address {
    
    var title: String = "default title"
    var subtitle : String = "subtitle goes here"
    var lat : Double = 0
    var lon : Double = 0
//  var cordHash: String
    
    init(){}
    // init without cord
    init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
        // set default to USC
        self.lat = 34.0224
        self.lon = 118.2851
    }
    // full init
    init(title: String, subtitle: String, lat: Double, lon: Double) {
        self.title = title
        self.subtitle = subtitle
        // set default to USC
        self.lat = lat
        self.lon = lon
    }
    
    var dictionary: [String: Any] {
        return [
            "title": self.title,
            "subtitle": self.subtitle,
            "lat": self.lat,
            "lon": self.lon
        ]
    }
}

