//
//  DriverApplyViewController.swift
//  Harvest-Business
//
//  Created by Lihan Zhu on 2021/2/9.
//  Modified by Zixuan Li on 2021/3/17.

import UIKit
import Foundation
import Firebase

class DriverApplyViewController: UIViewController {
    
    @IBOutlet weak var firstNameTF: UITextField!
    @IBOutlet weak var lastNameTF: UITextField!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var phoneNumTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var cityTF: UITextField!
    @IBOutlet weak var checkboxButton: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureNavBarUI()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        passwordTF.isSecureTextEntry = true
        
        firstNameTF.delegate = self
        lastNameTF.delegate = self
        emailTF.delegate = self
        passwordTF.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Hide navigation bar
        self.navigationController?.isNavigationBarHidden = true
    }
    
    func configureNavBarUI() {
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name: "Roboto-Medium", size: 20)!]
        self.navigationController?.isNavigationBarHidden = false
        self.title = "Become a Driver Today!"
        
        let buttonBack = UIButton()
        buttonBack.setImage(UIImage(systemName: "multiply"), for: .normal)
        buttonBack.addTarget(self, action: #selector(buttonBackPressed), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: buttonBack)
    }
    
    @objc private func buttonBackPressed() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func checkBoxPressed(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
    }
    
    @IBAction func signUpButtonDidTapped(_ sender: UIButton) {
        sender.tapAnimation {
            self.signUp()
        }
    }
    
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
        guard let emailAddress = emailTF.text,
              let password = passwordTF.text,
              let firstName = firstNameTF.text,
              let lastName = lastNameTF.text,
              let phoneNum = phoneNumTF.text,
              !emailAddress.isEmpty, !password.isEmpty,  !firstName.isEmpty, !lastName.isEmpty, password.count >= 6, !phoneNum.isEmpty else {
            alertSignUpError(title: "Incomplete!", message: "Please fill in all fields and make sure password is at least six characters.")
            return
        }
        
        guard emailAddress.isValidEmail() else {
            alertSignUpError(title: "Not a valid email!", message: "Please enter a valid email")
            return
        }
        
        DatabaseManager.shared.userExists(with: emailAddress, type: "drivers") { [weak self] (exists) in
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
                DatabaseManager.shared.insertDriver(with: Driver(firstName: firstName, lastName: lastName, email: emailAddress, phoneNum: phoneNum))
                
                // Push new view controller
                let vc = strongSelf.storyboard?.instantiateViewController(withIdentifier: "ApplyCompleteViewController") as! ApplyCompleteViewController
                vc.type = "drivers"
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}

extension DriverApplyViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case firstNameTF:
            lastNameTF.becomeFirstResponder()
        case lastNameTF:
            emailTF.becomeFirstResponder()
        case emailTF:
            phoneNumTF.becomeFirstResponder()
        case phoneNumTF:
            passwordTF.becomeFirstResponder()
        case passwordTF:
            cityTF.becomeFirstResponder()
        default:
            signUp()
        }
        return true
    }
}
