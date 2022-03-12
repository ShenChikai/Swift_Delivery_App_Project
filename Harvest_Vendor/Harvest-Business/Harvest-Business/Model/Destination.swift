//
//  Destination.swift
//  Harvest-Business
//
//  Created by Lihan Zhu on 2021/4/17.
//

import Foundation
import CoreLocation

/// Destination of market or customer
struct Destination {

    var type: DestinationType
    var lat: Double
    var lon: Double
    var addressTitle: String
    var addressSubtitle: String
    
    var displayName: String {
        switch type {
        case .market:
            return addressTitle
        case .customer:
            return addressSubtitle
        }
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

/// Types of destinations: market or customer
enum DestinationType {
    case market
    case customer
}
