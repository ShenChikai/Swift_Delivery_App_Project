//
//  Order.swift
//  Harvest
//
//  Created by Lihan Zhu on 2021/4/21.
//

import Foundation

struct Order {
    
    let id: String
    var driver: Driver
    let deliverySessionId: String
    let driverId: String
    let customerAddress: Address
    let market: Market
    
}

enum OrderState {

    case accepted
    case toOther
    case toYou
    case arrived
}
