//
//  PaymentMethod.swift
//  Harvest
//
//  Created by Lihan Zhu on 2021/3/30.
//

import Foundation
import Stripe

struct PaymentMethod {
    
    var id: String
    var last4: String
    var brand: String
    var isDefault: Bool = false
    
    var brandImage: UIImage {
        switch brand {
        case "amex":
            return STPImageLibrary.amexCardImage()
        case "diners":
            return STPImageLibrary.dinersClubCardImage()
        case "discover":
            return STPImageLibrary.discoverCardImage()
        case "jcb":
            return STPImageLibrary.jcbCardImage()
        case "mastercard":
            return STPImageLibrary.mastercardCardImage()
        case "unionpay":
            return STPImageLibrary.unionPayCardImage()
        case "visa":
            return STPImageLibrary.visaCardImage()
        case "unknown":
            return STPImageLibrary.unknownCardCardImage()
        default:
            print("Unknown card image for id: \(id) and last 4: \(last4)")
            return STPImageLibrary.unknownCardCardImage()
        }
    }
    
}
