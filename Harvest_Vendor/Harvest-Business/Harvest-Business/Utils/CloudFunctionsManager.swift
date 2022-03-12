//
//  CloudFunctionsManager.swift
//  Harvest-Business
//
//  Created by Lihan Zhu on 2021/3/28.
//

import Foundation
import Firebase

/// Singleton class for all calls to Firebase Cloud Functions
class CloudFunctionsManager {
    
    static let shared = CloudFunctionsManager()
    
    private var functions = Functions.functions()
    
    /// Retrieves onboarding link. The current user should not have an existing accoun.
    public func retrieveStripeOnboardingLink(completion: @escaping (String) -> Void) {
        guard Auth.auth().currentUser != nil else {
            print("User should be signed in.")
            return
        }
        functions.httpsCallable("retrieveStripeOnboardingLink").call { (result, error) in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let code = FunctionsErrorCode(rawValue: error.code)
                    let message = error.localizedDescription
                    let details = error.userInfo[FunctionsErrorDetailsKey]
                }
                print(error)
                return
            }
            if let url = (result?.data as? [String: Any])?["url"] as? String {
                completion(url)
            }
        }
    }
    
}
