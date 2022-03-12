//
//  Driver.swift
//  Harvest
//
//  Created by Lihan Zhu on 2021/4/21.
//

import Foundation
import CoreLocation

struct Driver {
    
    let firstName: String
    let lastName: String
    let email: String
    let phoneNum: String
    let imageUrl: String
    
    var lat: Double
    var lon: Double
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
}
