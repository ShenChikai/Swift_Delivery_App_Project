//
//  AppDelegate.swift
//  Harvest
//
//

import UIKit
import UserNotifications
import Firebase
import GoogleSignIn
import Stripe

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, GIDSignInDelegate  {
    
    private var isMFAEnabled = false
    
    /// for google sign in
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print("Google sign in error: \(error)")
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        //let tabbarVC = storyboard.instantiateViewController(withIdentifier: "TabbarIdentifier") as! UITabBarController
        let MarketsCollectionViewController = storyboard.instantiateViewController(withIdentifier: "MarketsCollectionViewController") as! MarketsCollectionViewController
        UIApplication.shared.windows.first?.rootViewController = MarketsCollectionViewController
        //self.window?.rootViewController?.present(tabbarVC, animated:true, completion: nil)
        
        guard let authentication = user.authentication else { return }
        
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if let error = error {
                let authError = error as NSError
                if (self.isMFAEnabled && authError.code == AuthErrorCode.secondFactorRequired.rawValue) {
                    let resolver = authError.userInfo[AuthErrorUserInfoMultiFactorResolverKey] as! MultiFactorResolver
                    var displayNameString = ""
                    for tmpFactorInfo in (resolver.hints) {
                        displayNameString += tmpFactorInfo.displayName ?? ""
                        displayNameString += " "
                    }
                    self.showTextInputPrompt(withMessage: "Select factor to sign in\n\(displayNameString)", completionBlock: { userPressedOK, displayName in
                        var selectedHint: PhoneMultiFactorInfo?
                        for tmpFactorInfo in resolver.hints {
                            if (displayName == tmpFactorInfo.displayName) {
                                selectedHint = tmpFactorInfo as? PhoneMultiFactorInfo
                            }
                        }
                        PhoneAuthProvider.provider().verifyPhoneNumber(with: selectedHint!,uiDelegate: nil, multiFactorSession: resolver.session) { verificationID, error in
                            if error != nil {
                                print("Multi factor start sign in failed. Error: \(error.debugDescription)")
                            } else {
                                self.showTextInputPrompt(withMessage: "Verification code for \(selectedHint?.displayName ?? "")", completionBlock: { userPressedOK, verificationCode in
                                    let credential: PhoneAuthCredential? = PhoneAuthProvider.provider().credential(withVerificationID: verificationID!, verificationCode: verificationCode)
                                    let assertion: MultiFactorAssertion? = PhoneMultiFactorGenerator.assertion(with: credential!)
                                    resolver.resolveSignIn(with: assertion!) {
                                        authResult, error in
                                        if error != nil {
                                            print("Multi factor finanlize sign in failed. Error: \(error.debugDescription)")
                                        } else {
                                        }
                                    }
                                })
                            }
                        }
                    })
                } else { //self.showMessagePrompt(error.localizedDescription)
                    return
                }
                return
            }
            // User is signed in
            // ...
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.sound,.alert]
        center.requestAuthorization(options: options) { (granted, error) in
            if error != nil {
                print(error)
            }
        }
        center.delegate = self
        
        StripeAPI.defaultPublishableKey = "pk_test_51IV22wJEWYdffhQpitt0sKlc47KqeI3YbN3JbTu80QEEdClALMLgZ5skmCofHA0gTB4byYNHZzSMlp6mMbgEjnu800Id0p4Z9P"
        
//        configureLocalEmulator()
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    @objc func processNotification(notification: Notification){
        print("I got it!!! object: \(notification.object) user info \(notification.userInfo) Name: \(notification.name)")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound,])
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any])
    -> Bool {
        return GIDSignIn.sharedInstance().handle(url)
    }
    
    func showTextInputPrompt(withMessage: String, completionBlock: ((Bool, String) -> ())){
        
    }
    
    private func configureLocalEmulator() {
        let settings = Firestore.firestore().settings
        settings.host = "localhost:8080"
        settings.isPersistenceEnabled = false
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings
        
        Functions.functions().useFunctionsEmulator(origin: "http://localhost:5001")
    }
}

