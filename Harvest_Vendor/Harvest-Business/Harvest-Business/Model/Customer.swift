//
//  Customer.swift
//  Harvest-Business
//
//  Created by Zixuan Li on 2021/4/12.
//

import Foundation

struct Customer {
    
    let firstName: String
    let lastName: String
    let phoneNum: String
    let imageUrl: String
    
    init(firstName: String, lastName: String, phoneNum: String, imageUrl: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNum = phoneNum
        self.imageUrl = imageUrl
    }
    
    init(dictionary: [String: String]) {
        firstName = dictionary["first_name"]!
        lastName = dictionary["last_name"]!
        phoneNum = dictionary["phone_num"]!
        imageUrl = dictionary["image_url"]!
    }
    
    var dictionary: [String: Any] {
        return [
            "first_name": self.firstName,
            "last_name": self.lastName,
            "phone_num": self.phoneNum,
            "image_url": self.imageUrl
        ]
    }
    
}
