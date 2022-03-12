//
//  Driver.swift
//  Harvest-Business
//
//  Created by Zixuan Li on 2021/3/17.
//

import Foundation
import UIKit

struct Driver {
    var image_url = String()
    var firstName: String
    var lastName: String
    var email: String
    var phoneNum: String
    var city = String()
    
    init(firstName: String,
         lastName: String,
         email: String,
         phoneNum: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phoneNum = phoneNum
    }
    
    init(dictionary: [String: String]) {
        firstName = dictionary["first_name"]!
        lastName = dictionary["last_name"]!
        email = dictionary["email"]!
        phoneNum = dictionary["phone_num"]!
    }
    
    var dictionary: [String: Any] {
        return [
            "first_name": self.firstName,
            "last_name": self.lastName,
            "email": self.email,
            "phone_num": self.phoneNum,
        ]
    }
}
