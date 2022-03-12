//
//  SignInViewController.swift
//  Harvest
//
//  Modified by Lihan Zhu on 2021/3/18.

import UIKit
import Foundation
import Firebase
import GoogleSignIn

class SignInViewController: UIViewController {
    
    @IBOutlet weak var forgetPasswordButton: UIButton!
    @IBOutlet weak var emailAddressTF: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var signInButton: RoundButton!
    @IBOutlet weak var googleSignInButton: GIDSignInButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        errorLabel.alpha = 0
        signInButton.isEnabled = false
        signInButton.alpha = 0.5
        
        setupTextfields()
    }
    
    override func viewDidLoad() {
        GIDSignIn.sharedInstance()?.presentingViewController = self
        super.viewDidLoad()
    }
    
    private func setupTextfields() {
        passwordTF.isSecureTextEntry = true
        
        emailAddressTF.delegate = self
        emailAddressTF.applyShadow(cornerRadius: 20)
        
        passwordTF.delegate = self
        passwordTF.applyShadow(cornerRadius: 20)
    }
    
    @IBAction func forgetPasswordButtonDidTapped(_ sender: Any) {
        
    }
    
    @IBAction func signInButtonDidTapped(_ sender: RoundButton) {
        sender.tapAnimation {
            self.signIn()
        }
    }
    
    @IBAction func buttonBackPressed(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func signOut() {
        let firebaseAuth = Auth.auth()
        do {
          try firebaseAuth.signOut()
        } catch let signOutError as NSError {
          print ("Error signing out: %@", signOutError)
        }
    }
    
    private func signIn() {
        removeError()
        let email = emailAddressTF.text!
        let password = passwordTF.text!
        
        guard email.isValidEmail() else {
            displayInvalidEmailError(message: "Please enter a valid email address")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (user, error) in
            guard let strongSelf = self else {
                return
            }
            if error == nil{
                let vc = strongSelf.storyboard?.instantiateViewController(withIdentifier: "MarketsNavigationController") as! UINavigationController
                strongSelf.navigationController?.showDetailViewController(vc, sender: nil)
            } else {
                strongSelf.displayNoAccountError(message: "There is no account associate with that information")
            }
        }
    }
    
    private func displayNoAccountError(message: String) {
        DispatchQueue.main.async {
            self.errorLabel.text = message
            self.errorLabel.alpha = 1
            self.emailAddressTF.setShadowColor(color: UIColor.red)
            self.passwordTF.setShadowColor(color: UIColor.red)
        }
    }
    
    private func displayInvalidEmailError(message: String) {
        DispatchQueue.main.async {
            self.errorLabel.text = message
            self.errorLabel.alpha = 1
            self.emailAddressTF.setShadowColor(color: UIColor.red)
        }
    }
    
    private func removeError() {
        DispatchQueue.main.async {
            self.errorLabel.alpha = 0
            self.emailAddressTF.setShadowColor()
            self.passwordTF.setShadowColor()
        }
    }
    
    @IBAction func backgroundTapped(_ sender: UITapGestureRecognizer) {
        passwordTF.resignFirstResponder()
        emailAddressTF.resignFirstResponder()
    }
    
}

extension SignInViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case emailAddressTF:
            passwordTF.becomeFirstResponder()
        case passwordTF:
            passwordTF.resignFirstResponder()
        default:
            print("Invalid text field")
        }
        return true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        guard let email = emailAddressTF.text, let password = passwordTF.text, !email.isEmpty, !password.isEmpty else {
            signInButton.isEnabled = false
            signInButton.alpha = 0.5
            return
        }
        signInButton.isEnabled = true
        signInButton.alpha = 1
    }
}
