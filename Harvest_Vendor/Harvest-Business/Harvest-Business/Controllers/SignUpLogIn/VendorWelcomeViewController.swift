//
//  VendorWelcomeViewController.swift
//  Harvest-Business
//
//  Created by Lihan Zhu on 2021/2/9.
//  Modified by Zixuan Li on 2021/3/17.

import UIKit

class VendorWelcomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func buttonBackPressed(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func applyButtonPressed(_ sender: UIButton) {
        sender.tapAnimation {
            let vc = self.storyboard?.instantiateViewController(identifier: "VendorApplyViewController") as! VendorApplyViewController
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func signInButtonPressed(_ sender: UIButton) {
        sender.tapAnimation {
            let vc = self.storyboard?.instantiateViewController(identifier: "SignInViewController") as! SignInViewController
            vc.type = "farms"
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

}
