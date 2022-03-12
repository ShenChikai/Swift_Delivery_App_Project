//
//  DeliverySession.swift
//  Harvest-Business
//
//  Created by Lihan Zhu on 2021/4/12.
//

import Foundation
import CoreLocation

/// One delivery session of the driver including market and customer info
class DeliverySession {
    
    var id: String  // Delivery session id
    var orders: [Order]  // All orders to be delivered
    var destinations: [Destination]  // All destinations including market
    var step: Int  // Index of the current destination. 0 means market, others mean customer
    
    init(id: String, orders: [Order], step: Int = 0, marketLat: Double, marketLon: Double, marketAddressTitle: String, marketName: String) {
        self.id = id
        self.orders = orders
        self.step = step
        // Add customers to destinations
        self.destinations = orders.map({ (order) -> Destination in
            return Destination(type: .customer, lat: order.customerLat, lon: order.customerLon, addressTitle: order.customerAddressTitle, addressSubtitle: order.customerAddressSubtitle)
        })
        // Add market to destinations
        self.destinations.insert(Destination(type: .market, lat: marketLat, lon: marketLon, addressTitle: marketName, addressSubtitle: marketAddressTitle), at: 0)
    }
    
    /// Increment by one step
    public func incrementStep() {
        if step < destinations.count {
            step += 1
        }
    }
    
    /// Whether all orders are completed
    public var completed: Bool {
        return step >= destinations.count
    }
    
    /// Return the current order
    public var currentOrder: Order? {
        guard !completed else {
            return nil
        }
        if step == 0 {
            return orders[0]
        }
        return orders[step - 1]
    }
    
    /// Return the current destination
    public var currentDestination: Destination? {
        guard step < destinations.count else {
            return nil
        }
        return destinations[step]
    }
    
    /// Return the remaining destinations
    public var remainingDestinations: [Destination] {
        return Array(destinations[step...])
    }

}
