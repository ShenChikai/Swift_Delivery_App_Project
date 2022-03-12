//
//  MapNavigationController.swift
//  Harvest-Business
//
//  Created by Lihan Zhu on 2021/4/27.
//

import UIKit

class MapNavigationController: UINavigationController {
    
    var deliverySession: DeliverySession?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let vc = self.topViewController as? MapViewController {
            vc.deliverySession = self.deliverySession
        }
    }

}
