                                                                                                                    //
//  AppDelegate.swift
//  MultiTab
//
//  Created by David Brownstone on 01/04/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit

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
    var allAvailableMessages = [Message]()
    var allClasses = [Class]()
    var msgCount = 0
    var splashScreen: UIImageView?
    
//    var tbControl: UITabBarController!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        URLCache.shared.removeAllCachedResponses()
        SettingsBundleHelper.initializeSettings()
        
        var config : SwiftActivity.Config = SwiftActivity.Config()
        config.size = 150
        config.spinnerColor = .magenta
        config.spinnerLineWidth = 3
        SwiftActivity.setConfig(config: config)

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
        self.showSplash()
    }
    
    func showSplash() {
        self.splashScreen = UIImageView(image: UIImage(named: "Nia"))
        self.window?.addSubview(splashScreen!)
        self.window?.bringSubview(toFront: splashScreen!)
        self.window?.makeKeyAndVisible()
    }
    
    func hideSplash() {
        UIView.animate(withDuration: 4.2, delay: 0.5, options: .curveEaseOut, animations: {
            self.splashScreen?.alpha = 0.0
        }, completion: { finished in
            self.splashScreen?.removeFromSuperview()
            print("end splash");
        })
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//        SettingsBundleHelper.checkAndExecuteSettings()
        SettingsBundleHelper.setVersionAndBuildNumber()
        self.hideSplash()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        dbAccess.setOnlineState(false)
    }
}

