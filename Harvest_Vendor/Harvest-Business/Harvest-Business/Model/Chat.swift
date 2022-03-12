//
//  Chat.swift
//  Harvest-Business
//
//  Created by Zixuan Li on 2021/3/17.
//


import UIKit
import Foundation

struct Chat{
    var users: [String]
    var dictionary: [String: Any] {
        return [
            "users": users
        ]
    }
}

extension Chat{

    init?(dictionary: [String:Any]) {
        guard let chatUsers = dictionary["users"] as? [String] else {return nil}
        self.init(users: chatUsers)
    }
}

