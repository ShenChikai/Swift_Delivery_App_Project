//
//  VendorCreateStripeAccountViewController.swift
//  Harvest-Business
//
//  Created by Lihan Zhu on 2021/3/28.
//

import UIKit
import Firebase
import SafariServices

class VendorCreateStripeAccountViewController: UIViewController {
    
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var onboardingButton: RoundButton!
    
    var url: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        errorLabel.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DatabaseManager.shared.stripeAccountExists { [weak self] (exists, error) in
            guard let strongSelf = self else {
                return
            }
            if exists {
                DispatchQueue.main.async {
                    strongSelf.errorLabel.isHidden = true
                }
            } else if let error = error {
                DispatchQueue.main.async {
                    strongSelf.errorLabel.text = error
                    strongSelf.errorLabel.isHidden = false
                }
            }
        }
    }
    
    @IBAction func onboardingButtonPressed(_ sender: UIButton) {
        sender.tapAnimation {
            self.displayPopup()
        }
    }
    
    func displayPopup() {
        guard let currentUser = Auth.auth().currentUser else {
            print("User should be signed in.")
            return
        }
        // Retrieve url from cloud functions
        CloudFunctionsManager.shared.retrieveStripeOnboardingLink { [weak self] (urlString) in
            guard let strongSelf = self else {
                return
            }
            guard let url = URL(string: urlString) else {
                return
            }
            let safariViewController = SFSafariViewController(url: url)
            safariViewController.delegate = strongSelf
            DispatchQueue.main.async {
                strongSelf.present(safariViewController, animated: true, completion: nil)
            }
        }
    }
    
    private func finishApply() {
        // Push new view controller
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ApplyCompleteViewController") as! ApplyCompleteViewController
        vc.type = "farms"
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func disableOnboardingButton() {
        DispatchQueue.main.async {
            self.onboardingButton.isEnabled = false
            self.onboardingButton.alpha = 0.5
        }
    }
    
    private func enableOnboardingButton() {
        DispatchQueue.main.async {
            self.onboardingButton.isEnabled = true
            self.onboardingButton.alpha = 1.0
        }
    }
    
}

extension VendorCreateStripeAccountViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        // the user may have closed the SFSafariViewController instance before a redirect
        // occurred. Sync with your backend to confirm the correct state
    }
}
