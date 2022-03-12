//
//  VendorApplyViewController.swift
//  Harvest-Business
//
//  Created by Lihan Zhu on 2021/2/9.
//  Modified by Zixuan Li on 2021/3/17.

import UIKit
import Foundation
import Firebase

class VendorApplyViewController: UIViewController {
    
    // farm info
    @IBOutlet weak var farmNameTF: UITextField!
    @IBOutlet weak var marketTF: UITextField!
    @IBOutlet weak var vendorTypeTF: UITextField!
    // owner info
    @IBOutlet weak var firstNameTF: UITextField!
    @IBOutlet weak var lastNameTF: UITextField!
    @IBOutlet weak var checkboxButton: UIButton!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var phoneNumTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var confirmPasswordTF: UITextField!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureNavBarUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        passwordTF.isSecureTextEntry = true
        confirmPasswordTF.isSecureTextEntry = true
        
        firstNameTF.delegate = self
        lastNameTF.delegate = self
        emailTF.delegate = self
        passwordTF.delegate = self
        confirmPasswordTF.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Hide navigation bar
        self.navigationController?.isNavigationBarHidden = true
    }
    
    func configureNavBarUI() {
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name: "Roboto-Medium", size: 20)!]
        self.navigationController?.isNavigationBarHidden = false
        self.title = "Become a Vendor Today!"
        
        let buttonBack = UIButton()
        buttonBack.setImage(UIImage(systemName: "multiply"), for: .normal)
        buttonBack.addTarget(self, action: #selector(buttonBackPressed), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: buttonBack)
    }
    
    @IBAction func checkBoxPressed(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
    }
    
    @objc private func buttonBackPressed() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func signUpButtonDidTapped(_ sender: UIButton) {
        sender.tapAnimation {
            self.signUp()
        }    }
    
    /// Display an alert
    private func alertSignUpError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    private func signUp() {
        guard checkboxButton.isSelected else {
            alertSignUpError(title: "Incomplete!", message: "Please agree to Terms of Services and Privacy Policy.")
            return
        }
        guard let farmName = farmNameTF.text,
              let market = marketTF.text,
              let vendorType = vendorTypeTF.text,
              let emailAddress = emailTF.text,
              let password = passwordTF.text,
              let secondPassword = confirmPasswordTF.text,
              let firstName = firstNameTF.text,
              let lastName = lastNameTF.text,
              let phoneNum = phoneNumTF.text,
              !farmName.isEmpty, !market.isEmpty, !vendorType.isEmpty, !emailAddress.isEmpty, !password.isEmpty, !secondPassword.isEmpty, !firstName.isEmpty, !lastName.isEmpty, password.count >= 6, secondPassword.count >= 6, !phoneNum.isEmpty else {
            alertSignUpError(title: "Incomplete!", message: "Please fill in all fields and make sure password is at least six characters.")
            return
        }
        
        guard emailAddress.isValidEmail() else {
            alertSignUpError(title: "Not a valid email!", message: "Please enter a valid email")
            return
        }
        
        if password != secondPassword {
            alertSignUpError(title: "Passwords do not match!", message: "Please try again")
            return
        }
        
        DatabaseManager.shared.userExists(with: emailAddress, type: "farms") { [weak self] (exists) in
            guard let strongSelf = self else {
                return
            }
            guard !exists else {
                // Customer already exists
                strongSelf.alertSignUpError(title: "Email has been registered!", message: "Please login with password")
                return
            }
            
            // Create user
            Auth.auth().createUser(withEmail: emailAddress, password: password) { [weak self] (result, error) in
                guard let strongSelf = self else {
                    return
                }
                if let error = error {
                    print("Error creating user: \(error)")
                    return
                }
                
                // add user's displayName
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = firstName + " " + lastName
                changeRequest?.commitChanges{ err in
                    if err != nil {
                        print("Fail to update user's display name")
                        return
                    }
                    else{
                        print("displayName updated")
                        return
                    }
                }
                
                // Save farmer to database
                DatabaseManager.shared.insertFarmer(with: Farmer(farmName: farmName, market: market, firstName: firstName, lastName: lastName, email: emailAddress, phoneNum: phoneNum, vendorType: vendorType))
                
                // Push new view controller
                let vc = strongSelf.storyboard?.instantiateViewController(withIdentifier: "VendorCreateStripeAccountViewController") as! VendorCreateStripeAccountViewController
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}

extension VendorApplyViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case farmNameTF:
            marketTF.becomeFirstResponder()
        case marketTF:
            vendorTypeTF.becomeFirstResponder()
        case vendorTypeTF:
            firstNameTF.becomeFirstResponder()
        case firstNameTF:
            lastNameTF.becomeFirstResponder()
        case lastNameTF:
            emailTF.becomeFirstResponder()
        case emailTF:
            passwordTF.becomeFirstResponder()
        case passwordTF:
            confirmPasswordTF.becomeFirstResponder()
        default:
            signUp()
        }
        return true
    }
}
