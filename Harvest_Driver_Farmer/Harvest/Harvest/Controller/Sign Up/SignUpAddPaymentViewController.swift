//
//  SignInAddPaymentViewController.swift
//  Harvest
//  Modified by Lihan Zhu on 2021/3/14.
//

import Foundation
import UIKit
import Stripe

class SignUpAddPaymentViewController: UIViewController {
    
    @IBOutlet weak var cardTF: STPPaymentCardTextField!
    
    var setupIntentClientSecret: String?
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.listenToSetupIntentClientSecret()
    }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        sender.tapAnimation {
            self.addPayment()
        }
    }
    
    private func addPayment() {
        guard let setupIntentClientSecret = setupIntentClientSecret else {
            return;
        }
        
        // Collect card details
        let cardParams = cardTF.cardParams
        
        // Collect billing details
        let billingDetails = STPPaymentMethodBillingDetails()
        
        // Create SetupIntent confirm parameters with the above
        let paymentMethodParams = STPPaymentMethodParams(card: cardParams, billingDetails: billingDetails, metadata: nil)
        let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: setupIntentClientSecret)
        setupIntentParams.paymentMethodParams = paymentMethodParams
        
        // Complete the setup
        let paymentHandler = STPPaymentHandler.shared()
        paymentHandler.confirmSetupIntent(setupIntentParams, with: self) { status, setupIntent, error in
            switch (status) {
            case .failed:
                self.displayAlert(title: "Setup failed", message: error?.localizedDescription ?? "")
                break
            case .canceled:
                self.displayAlert(title: "Setup canceled", message: error?.localizedDescription ?? "")
                break
            case .succeeded:
                // Save payment method id to firestore
                guard let paymentMethodID = setupIntent?.paymentMethodID else {
                    self.displayAlert(title: "Setup failed", message: "Unable to retrieve setup intent id")
                    break
                }
                DatabaseManager.shared.insertPaymentMethod(id: paymentMethodID)
                
                // Redirect to market page
                let vc = self.storyboard?.instantiateViewController(identifier: "MarketsNavigationController") as! UINavigationController
                self.navigationController?.showDetailViewController(vc, sender: nil)
            @unknown default:
                fatalError()
                break
            }
        }
    }
    
    private func listenToSetupIntentClientSecret() {
        DatabaseManager.shared.listenToCustomerUpdates { [weak self] (data) in
            guard let strongSelf = self else {
                return
            }
            guard let newSetupSecret = data["stripe_setup_secret"] as? String else {
                return
            }
            strongSelf.setupIntentClientSecret = newSetupSecret
        }
    }
    
    private func displayAlert(title: String, message: String) {
        // TODO: might change to label display
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension SignUpAddPaymentViewController: STPAuthenticationContext {
    
    func authenticationPresentingViewController() -> UIViewController {
        return self
    }
    
}
