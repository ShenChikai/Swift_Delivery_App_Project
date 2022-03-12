//
//  ApplyConpleteViewController.swift
//  Harvest-Business
//
//  Created by Lihan Zhu on 2021/2/9.
//

import UIKit

class ApplyCompleteViewController: UIViewController {

    var type = String() // drivers or farms
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func continueDidTapped(sender: UIButton) {
        sender.tapAnimation {
            if self.type == "drivers"{
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "HomeNavigationController") as! UINavigationController
                self.navigationController?.showDetailViewController(vc, sender: nil)
            }
            else{
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "farmHomeVC")
                self.navigationController?.showDetailViewController(vc!, sender: nil)
            }
        }
    }
}
