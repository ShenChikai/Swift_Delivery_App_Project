//
//  Address.swift
//  Harvest
//
//  Created by Denny Shen on 2021/3/9.

//  MarketItem.swift
//  Harvest
//

import Foundation
import CoreLocation

struct Address {
    
    var title: String = "default title"
    var subtitle : String = "subtitle goes here"
    var lat : Double = 0
    var lon : Double = 0
    var apt : String = ""
    var building : String = ""
    var instruction : String = ""
//  var cordHash: String
    
    init(){}
    // init without cord
    init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
        // set default to USC
        self.lat = 34.0224
        self.lon = 118.2851
        self.apt = ""
        self.building = ""
        self.instruction = ""
    }
    // full init
    init(title: String, subtitle: String, lat: Double, lon: Double, apt: String, building: String, instruction: String) {
        self.title = title
        self.subtitle = subtitle
        // set default to USC
        self.lat = lat
        self.lon = lon
        self.apt = apt
        self.building = building
        self.instruction = instruction
    }
    
    var dictionary: [String: Any] {
        return [
            "title": self.title,
            "subtitle": self.subtitle,
            "lat": self.lat,
            "lon": self.lon,
            "apt": self.apt,
            "building": self.building,
            "instruction": self.instruction
        ]
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
}
