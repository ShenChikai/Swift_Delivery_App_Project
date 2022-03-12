//
//  SignInViewController.swift
//  Harvest-Business
//
//  Created by Lihan Zhu on 2021/2/9.
//  Modified by Zixuan Li on 2021/3/17.

import UIKit
import Foundation
import Firebase

class SignInViewController: UIViewController {

    var type = String() // drivers or farms
    
    @IBOutlet weak var emailAddressTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        passwordTF.isSecureTextEntry = true
        
        emailAddressTF.applyShadow(cornerRadius: 20)
        passwordTF.applyShadow(cornerRadius: 20)
    }
    
    @IBAction func buttonBackPressed(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func forgetPasswordButtonDidTapped(_ sender: Any) {
        
    }
    
    @IBAction func signInButtonDidTapped(_ sender: UIButton) {
        sender.tapAnimation {
            self.signIn()
        }
    }
    
    func signIn() {
        let email = emailAddressTF.text!
        let password = passwordTF.text!
            
        Auth.auth().signIn(withEmail: email, password: password) { user, error in
            if error == nil{
                if self.type == "drivers"{
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "HomeNavigationController") as! UINavigationController
                    self.navigationController?.showDetailViewController(vc, sender: nil)
                }
                else{
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "farmHomeVC")
                    self.navigationController?.showDetailViewController(vc!, sender: nil)
                }
            } else {
                let alert = UIAlertController(title: "Email address and password do not match!", message: "Please try again", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func signOut() {
        let firebaseAuth = Auth.auth()
        do {
          try firebaseAuth.signOut()
        } catch let signOutError as NSError {
          print ("Error signing out: %@", signOutError)
        }
    }
    
}
