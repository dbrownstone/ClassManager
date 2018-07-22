                                                                                                                    //
//  AppDelegate.swift
//  MultiTab
//
//  Created by David Brownstone on 01/04/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit
import Firebase

var appDelegate:AppDelegate = (UIApplication.shared).delegate as! AppDelegate
var standardDefaults = UserDefaults.standard
var databaseURL = Constants.Database.URL
var dbAccess = DatabaseAccess()
var activityIndicator = UIActivityIndicatorView()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var loggedInId = ""
    var backgroundMode = false
    var internetIsAvailable = false
    var loginName: String?
    var thisMember: User?
    var allTheUsers: [User]?

//    var tbControl: UITabBarController!

    override init() {
        super.init()
        if Connectivity.isConnectedToInternet() {
            print("Yes! internet is available.")
            internetIsAvailable = true
            FirebaseApp.configure()
            Database.database().isPersistenceEnabled = true
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.usersLoaded(notification:)),
                                                   name: .AllUsers,
                                                   object: nil)
            dbAccess.getAllUsers()
        } else {
            internetIsAvailable = false
            print("No! internet is not available. Please Try again later.")
            exit(0)
        }
    }
    
    @objc func usersLoaded(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self,
                                                  name: .AllUsers,
                                                  object: nil)
        allTheUsers = notification.userInfo!["users"] as? [User]
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
//        URLCache.shared.removeAllCachedResponses()
        
        let appDefaults = [Constants.StdDefaultKeys.CurrentLoggedInId : "" as Any,
                           Constants.StdDefaultKeys.LoggedInEmail : "" as Any,
                           Constants.StdDefaultKeys.Sisma: "" as Any]
        standardDefaults.register(defaults: appDefaults)
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        dbAccess.setOnlineState(false)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        dbAccess.setOnlineState(false)
    }
    
    
}

