//
//  InitialViewController.swift
//  ClassesManager
//
//  Created by David Brownstone on 02/09/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class InitialViewController: UIViewController {

    @IBOutlet weak var splashScreen: UIImageView!
    @IBOutlet weak var cover: UIView!
    
    var messagesLoaded = false
    var usersLoaded = false
    var classesLoaded = false
    var alreadyLoggedIn = false
    var loggedOut = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if Connectivity.isConnectedToInternet() {
            print("Yes! internet is available.")
            appDelegate.internetIsAvailable = true
            FirebaseApp.configure()
            Database.database().isPersistenceEnabled = true
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.usersLoaded(notification:)),
                                                   name: .AllUsers,
                                                   object: nil)
            dbAccess.getAllUsers()
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.messagesLoaded(notification:)),
                                                   name: .AllMessages,
                                                   object: nil)
            dbAccess.getAllMessages()
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.classesLoaded(notification:)),
                                                   name: .AllClasses,
                                                   object: nil)
            dbAccess.getAllClasses()
        } else {
            appDelegate.internetIsAvailable = false
            print("No! internet is not available. Please Try again later.")
        }
    }
    
    @objc func usersLoaded(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self,
                                                  name: .AllUsers,
                                                  object: nil)
        appDelegate.allTheUsers = notification.userInfo!["users"] as? [User]
        print("all users found")
        self.usersLoaded = true
        if self.messagesLoaded && self.classesLoaded {
            self.performSegue(withIdentifier: Constants.Segues.GoToLoginScreen, sender: self)
        }
    }
    
    @objc func messagesLoaded(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self,
                                                  name: .AllMessages,
                                                  object: nil)
        appDelegate.allAvailableMessages = (notification.userInfo!["messages"] as? [Message])!
        appDelegate.msgCount = appDelegate.allAvailableMessages.count
        print("Message Count: \(appDelegate.msgCount)")
        self.messagesLoaded = true
        if self.usersLoaded && self.classesLoaded {
            self.performSegue(withIdentifier: Constants.Segues.GoToLoginScreen, sender: self)
        }
    }
    
    @objc func classesLoaded(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self,
                                                  name: .AllClasses,
                                                  object: nil)
        let existingClasses = (notification.userInfo!["classes"] as? [Class])!
        self.classesLoaded = true
        appDelegate.allClasses = existingClasses
        if self.usersLoaded && self.messagesLoaded {
            self.performSegue(withIdentifier: Constants.Segues.GoToLoginScreen, sender: self)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.alreadyLoggedIn || self.loggedOut {
            self.splashScreen.alpha = 0
            self.cover.isHidden = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.alreadyLoggedIn {
            self.alreadyLoggedIn = false
            self.loggedOut = false
            self.performSegue(withIdentifier: Constants.Segues.LoggedIn, sender: self)
        } else if self.loggedOut {
            self.performSegue(withIdentifier: Constants.Segues.GoToLoginScreen, sender: self)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.cover.isHidden = true
        self.splashScreen.alpha = 1.0
        self.loggedOut = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
   
    @IBAction func logout(_ segue: UIStoryboardSegue) {
        do {
            try Auth.auth().signOut()
            standardDefaults.set("", forKey: Constants.StdDefaultKeys.CurrentLoggedInId)
            standardDefaults.set("", forKey: Constants.StdDefaultKeys.LoggedInEmail)
            standardDefaults.synchronize()
            dbAccess.setOnlineState(false)
            self.loggedOut = true
        } catch {
            print("Unable to logout")
        }
    }
    
    // MARK: - Navigation

    @IBAction func doneLoggingIn(_ segue: UIStoryboardSegue) {
        self.alreadyLoggedIn = true
//        self.view.alpha = 0.85
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
//        }
        
//    }
   

}
