//
//  Farm.swift
//  Harvest-Business
//
//  Created by Zixuan Li on 2021/3/17.
//

import Foundation
import UIKit

struct Farmer {
    var image_url = String()
    var farmName: String
    var market: String
    var firstName: String
    var lastName: String
    var email: String
    var phoneNum: String
    var stallNum = String()
    var vendorType: String // Veggie, Fruit
    
    init(farmName: String,
         market: String,
         firstName: String,
         lastName: String,
         email: String,
         phoneNum: String,
         vendorType: String) {
        self.farmName = farmName
        self.market = market
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phoneNum = phoneNum
        self.vendorType = vendorType
    }
    
    init(dictionary: [String: String]) {
        farmName = dictionary["name"]!
        market = dictionary["market"]!
        firstName = dictionary["first_name"]!
        lastName = dictionary["last_name"]!
        email = dictionary["email"]!
        phoneNum = dictionary["phone_num"]!
        vendorType = dictionary["category"]!
    }
    
    var dictionary: [String: Any] {
        return [
            "name": self.farmName,
            "market": self.market,
            "first_name": self.firstName,
            "last_name": self.lastName,
            "email": self.email,
            "phone_num": self.phoneNum,
            "category": self.vendorType
        ]
    }
}
