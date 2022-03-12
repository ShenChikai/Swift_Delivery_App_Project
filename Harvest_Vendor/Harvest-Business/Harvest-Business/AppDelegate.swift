//
//  AppDelegate.swift
//  Harvest-Business
//
//  Created by Lihan Zhu on 2021/2/8.
//

import UIKit
import UserNotifications
import Firebase
import Stripe

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        StripeAPI.defaultPublishableKey = "pk_test_51IV22wJEWYdffhQpitt0sKlc47KqeI3YbN3JbTu80QEEdClALMLgZ5skmCofHA0gTB4byYNHZzSMlp6mMbgEjnu800Id0p4Z9P"
        
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.sound,.alert]
        center.requestAuthorization(options: options) { (granted, error) in
            if error != nil {
                print(error)
            }
        }
        center.delegate = self
        
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


}

