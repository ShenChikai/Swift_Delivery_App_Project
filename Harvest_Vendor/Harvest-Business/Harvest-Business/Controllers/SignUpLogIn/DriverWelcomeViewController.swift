//
//  DriverWelcomeViewController.swift
//  Harvest-Business
//
//  Created by Lihan Zhu on 2021/2/9.
//  Modified by Zixuan Li on 2021/3/17.

import UIKit

class DriverWelcomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func buttonBackPressed(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func applyButtonPressed(_ sender: UIButton) {
        sender.tapAnimation {
            let vc = self.storyboard?.instantiateViewController(identifier: "DriverApplyViewController") as! DriverApplyViewController
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func signInButtonPressed(_ sender: UIButton) {
        sender.tapAnimation {
            let vc = self.storyboard?.instantiateViewController(identifier: "SignInViewController") as! SignInViewController
            vc.type = "drivers"
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

}
