//
//  Order.swift
//  Harvest-Business
//
//  Created by Lihan Zhu on 2021/4/12.
//

import Foundation
import CoreLocation

class Order {
    
    var id: String
    var date: Date
    // Customer info
    var customerId: String
    var customerAddressTitle: String
    var customerAddressSubtitle: String
    var customer: Customer
    var customerLon: Double
    var customerLat: Double
    // Market info
    var marketId: String
    var marketName: String
    var marketAddressTitle: String
    // Driver info
    var totalEarned: Double
    var numOfItems: Int
    var farmIDToOrder: [[String: Any]]
    var pickupStatus: Bool
    
    init(id: String, date: Date, customerId: String, customerAddressTitle: String, customerAddressSubtitle: String, customer: Customer, customerLon: Double, customerLat: Double, marketId: String, marketName: String, marketAddressTitle: String, totalEarned: Double, numOfItems: Int, farmIDToOrder: [[String : Any]], pickupStatus: Bool) {
        self.id = id
        self.date = date
        self.customerId = customerId
        self.customerAddressTitle = customerAddressTitle
        self.customerAddressSubtitle = customerAddressSubtitle
        self.customer = customer
        self.customerLon = customerLon
        self.customerLat = customerLat
        self.marketId = marketId
        self.marketName = marketName
        self.marketAddressTitle = marketAddressTitle
        self.totalEarned = totalEarned
        self.numOfItems = numOfItems
        self.farmIDToOrder = farmIDToOrder
        self.pickupStatus = pickupStatus
    }
    
    var customerCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: customerLat, longitude: customerLon)
    }
    
    var boughtDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let completeDate = dateFormatter.string(from: date)
        return String(completeDate.dropLast(6)) // drop year representation
    }
}
