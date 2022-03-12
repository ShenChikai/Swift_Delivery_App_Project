//
//  AddPaymentViewController.swift
//  Harvest
//
//  Created by Lihan Zhu on 2021/4/1.
//

import UIKit
import Stripe

class AddPaymentViewController: UIViewController {

    @IBOutlet weak var cardTF: STPPaymentCardTextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    var setupIntentClientSecret: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        clearError()
        listenToSetupIntentClientSecret()
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        clearError()
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func saveButtonPressed(_ sender: RoundButton) {
        sender.tapAnimation {
            self.savePayment()
        }
    }
    
    private func savePayment() {
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
                self.displayError(message: error?.localizedDescription ?? "Failed to add payment.")
                break
            case .canceled:
                self.displayError(message: error?.localizedDescription ?? "Canceled.")
                break
            case .succeeded:
                // Save payment method id to firestore
                guard let paymentMethodID = setupIntent?.paymentMethodID else {
                    self.displayError(message: "Failed to add payment due to internal error.")
                    break
                }
                DatabaseManager.shared.insertPaymentMethod(id: paymentMethodID)
                
                // Pop view controller
                self.navigationController?.popViewController(animated: true)
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
    
    private func displayError(message: String) {
        DispatchQueue.main.async {
            self.errorLabel.text = message
            self.errorLabel.alpha = 1
        }
    }
    
    private func clearError() {
        DispatchQueue.main.async {
            self.errorLabel.alpha = 0
        }
    }
    
}

extension AddPaymentViewController: STPAuthenticationContext {
    
    func authenticationPresentingViewController() -> UIViewController {
        return self
    }
    
}
