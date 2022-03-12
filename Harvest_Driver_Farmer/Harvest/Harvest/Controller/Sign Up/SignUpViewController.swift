//
//  SignUpViewController.swift
//  Harvest
//
//  Modified by Lihan Zhu on 2021/3/18.

import UIKit
import Foundation
import Firebase
import GoogleSignIn

class SignUpViewController: UIViewController {
    
    // TextFields
    @IBOutlet weak var firstNameTF: UITextField!
    @IBOutlet weak var lastNameTF: UITextField!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var confirmPasswordTF: UITextField!
    @IBOutlet weak var phoneNumTF: UITextField!
    
    // Error labels
    @IBOutlet weak var firstNameErrorLabel: UILabel!
    @IBOutlet weak var lastNameErrorLabel: UILabel!
    @IBOutlet weak var emailErrorLabel: UILabel!
    @IBOutlet weak var passwordErrorLabel: UILabel!
    @IBOutlet weak var confirmPasswordErrorLabel: UILabel!
    @IBOutlet weak var termErrorLabel: UILabel!
    @IBOutlet weak var phoneNumErrorLabel: UILabel!
    
    @IBOutlet weak var checkboxButton: UIButton!
    @IBOutlet weak var signUpButton: RoundButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        signUpButton.isEnabled = false
        signUpButton.alpha = 0.5
        
        setupTextFields()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("load")
        GIDSignIn.sharedInstance()?.presentingViewController = self
//        GIDSignIn.sharedInstance().signIn()
    }
    
    private func setupTextFields() {
        passwordTF.isSecureTextEntry = true
        confirmPasswordTF.isSecureTextEntry = true
        
        firstNameTF.delegate = self
        lastNameTF.delegate = self
        emailTF.delegate = self
        passwordTF.delegate = self
        confirmPasswordTF.delegate = self
        phoneNumTF.delegate = self
        
        firstNameTF.applyShadow(cornerRadius: 20)
        lastNameTF.applyShadow(cornerRadius: 20)
        emailTF.applyShadow(cornerRadius: 20)
        passwordTF.applyShadow(cornerRadius: 20)
        confirmPasswordTF.applyShadow(cornerRadius: 20)
        phoneNumTF.applyShadow(cornerRadius: 20)
        
        clearErrors()
    }
    
    @IBAction func signUpButtonDidTapped(_ sender: RoundButton) {
        sender.tapAnimation {
            self.signUp()
        }
    }
    
    @IBAction func backgroundTapped(_ sender: UITapGestureRecognizer) {
        firstNameTF.resignFirstResponder()
        lastNameTF.resignFirstResponder()
        emailTF.resignFirstResponder()
        passwordTF.resignFirstResponder()
        confirmPasswordTF.resignFirstResponder()
    }
    
    @IBAction func checkBoxPressed(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
    }
    
    @IBAction func buttonBackPressed(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    /// Display error on label and textField
    private func displayError(label: UILabel, textField: UITextField?, message: String) {
        DispatchQueue.main.async {
            if let textField = textField {
                textField.setShadowColor(color: UIColor.red)
            }
            label.alpha = 1
            label.text = message
        }
    }
    
    /// Clear all errors on labels and textFields
    private func clearErrors() {
        DispatchQueue.main.async {
            self.firstNameErrorLabel.alpha = 0
            self.lastNameErrorLabel.alpha = 0
            self.emailErrorLabel.alpha = 0
            self.passwordErrorLabel.alpha = 0
            self.confirmPasswordErrorLabel.alpha = 0
            self.termErrorLabel.alpha = 0
            self.phoneNumErrorLabel.alpha = 0
            
            self.firstNameTF.setShadowColor(color: UIColor.gray)
            self.lastNameTF.setShadowColor(color: UIColor.gray)
            self.emailTF.setShadowColor(color: UIColor.gray)
            self.passwordTF.setShadowColor(color: UIColor.gray)
            self.confirmPasswordTF.setShadowColor(color: UIColor.gray)
            self.phoneNumTF.setShadowColor(color: UIColor.gray)
        }
    }
    
    private func signUp() {
        clearErrors()
        
        guard let emailAddress = emailTF.text, let password = passwordTF.text, let secondPassword = confirmPasswordTF.text, let firstName = firstNameTF.text, let lastName = firstNameTF.text, let phoneNum = phoneNumTF.text, !emailAddress.isEmpty, !password.isEmpty, !secondPassword.isEmpty, !firstName.isEmpty, !lastName.isEmpty else {
            displayError(label: firstNameErrorLabel, textField: nil, message: "Please fill in all fields")
            return
        }
        guard password.count >= 6 else {
            displayError(label: passwordErrorLabel, textField: passwordTF, message: "Password should contain at least 6 characters")
            return
        }
        
        guard secondPassword.count >= 6 else {
            displayError(label: confirmPasswordErrorLabel, textField: confirmPasswordTF, message: "Password should contain at least 6 characters")
            return
        }
        guard checkboxButton.isSelected else {
            displayError(label: termErrorLabel, textField: nil, message: "Please agree to our Terms of Services and Privacy Policy")
            return
        }
        
        guard emailAddress.isValidEmail() else {
            displayError(label: emailErrorLabel, textField: emailTF, message: "Please enter a valid email address")
            return
        }

        guard phoneNum.count == 10 else {
            displayError(label: phoneNumErrorLabel, textField: phoneNumTF, message: "Not a valid phone number")
            return
        }
        
        if password != secondPassword {
            displayError(label: confirmPasswordErrorLabel, textField: confirmPasswordTF, message: "Passwords need to match")
            return
        }
        
        DatabaseManager.shared.customerExists(with: emailAddress) { [weak self] (exists) in
            guard let strongSelf = self else {
                return
            }
            guard !exists else {
                // Customer already exists
                strongSelf.displayError(label: strongSelf.emailErrorLabel, textField: strongSelf.emailTF, message: "This email has been signed up")
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
                
                // Save customer to database
                DatabaseManager.shared.insertCustomer(with: Customer(firstName: firstName, lastName: lastName, email: emailAddress, phoneNum: phoneNum))
                // Push new view controller
                let signUpAddLocationViewController = strongSelf.storyboard?.instantiateViewController(withIdentifier: "SignUpAddLocationViewController") as! SignUpAddLocationViewController
                strongSelf.navigationController?.pushViewController(signUpAddLocationViewController, animated: true)
            }
        }
    }
}

extension SignUpViewController: UITextFieldDelegate {
    
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
            confirmPasswordTF.becomeFirstResponder()
        case confirmPasswordTF:
            confirmPasswordTF.resignFirstResponder()
        default:
            print("Unknown textfield")
        }
        return true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        guard let emailAddress = emailTF.text, let password = passwordTF.text, let secondPassword = confirmPasswordTF.text, let firstName = firstNameTF.text, let lastName = lastNameTF.text, let phone = phoneNumTF.text, !emailAddress.isEmpty, !password.isEmpty, !secondPassword.isEmpty, !firstName.isEmpty, !lastName.isEmpty, !phone.isEmpty else {
            signUpButton.isEnabled = false
            signUpButton.alpha = 0.5
            return
        }
        signUpButton.isEnabled = true
        signUpButton.alpha = 1
    }
    
}
