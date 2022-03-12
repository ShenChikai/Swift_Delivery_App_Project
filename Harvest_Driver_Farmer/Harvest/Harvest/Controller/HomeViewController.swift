//
//  ViewController.swift
//  Harvest
//
//

import UIKit
import Foundation
import FirebaseAuth

class HomeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        
        if Auth.auth().currentUser != nil {
            let vc = self.storyboard?.instantiateViewController(identifier: "MarketsNavigationController") as! UINavigationController
            self.navigationController?.showDetailViewController(vc, sender: nil)
        }
    }
    
    @IBAction func logInButtonPressed(_ sender: RoundButton) {
        sender.tapAnimation {
            let vc = self.storyboard?.instantiateViewController(identifier: "SignInViewController") as! SignInViewController
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func signUnButtonPressed(_ sender: RoundButton) {
        sender.tapAnimation {
            let vc = self.storyboard?.instantiateViewController(identifier: "SignUpViewController") as! SignUpViewController
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}

extension HomeViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let navVc = navigationController {
            return navVc.viewControllers.count > 1
        }
        return false
    }

}

