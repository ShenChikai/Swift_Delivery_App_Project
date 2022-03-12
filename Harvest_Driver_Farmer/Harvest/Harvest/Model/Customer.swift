//
//  Customer.swift
//  Harvest
//
//  Created by Lihan Zhu on 2021/3/1.
//

import Foundation

struct Customer {
    
    let firstName: String
    let lastName: String
    let email: String
    let phoneNum: String
    let imageUrl: String
    
    init(firstName: String, lastName: String, email: String, phoneNum: String, imageUrl: String = "image/customer_avatar/Link.jpeg") {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phoneNum = phoneNum
        self.imageUrl = imageUrl
    }
    
    init(dictionary: [String: Any]) {
        self.firstName = dictionary["first_name"] as! String
        self.lastName = dictionary["last_name"] as! String
        self.email = dictionary["email"] as! String
        self.phoneNum = dictionary["phone_num"] as! String
        self.imageUrl = dictionary["image_url"] as! String
    }
    
    var dictionary: [String: Any] {
        return [
            "first_name": self.firstName,
            "last_name": self.lastName,
            "email": self.email,
            "phone_num": self.phoneNum,
            "image_url": self.imageUrl
        ]
    }
    
}
