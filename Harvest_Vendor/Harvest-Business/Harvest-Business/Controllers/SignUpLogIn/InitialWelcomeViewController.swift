//
//  ViewController.swift
//  Harvest-Business
//
//  Created by Lihan Zhu on 2021/2/8.
//

import UIKit
import FirebaseAuth

class InitialWelcomeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        
        if Auth.auth().currentUser != nil {
            let vc = self.storyboard?.instantiateViewController(identifier: "HomeNavigationController") as! UINavigationController
            self.navigationController?.showDetailViewController(vc, sender: nil)
        }
    }
    
    @IBAction func vendorButtonTapped(_ sender: UIButton) {
        sender.tapAnimation {
            let vc = self.storyboard?.instantiateViewController(identifier: "VendorWelcomeViewController") as! VendorWelcomeViewController
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func driverButtonTapped(_ sender: UIButton) {
        sender.tapAnimation {
            let vc = self.storyboard?.instantiateViewController(identifier: "DriverWelcomeViewController") as! DriverWelcomeViewController
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}

extension InitialWelcomeViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let navVc = navigationController {
            return navVc.viewControllers.count > 1
        }
        return false
    }
}
