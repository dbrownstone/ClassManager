//
//  InitialPrep.swift
//  ClassesManager
//
//  Created by David Brownstone on 02/09/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class InitialPrep: NSObject {

    var messagesLoaded = false
    var usersLoaded = false
    var classesLoaded = false
    var alreadyLoggedIn = false
    var loggedOut = false
    
    public func startInitialPreparation() {

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
        
    }
    
    @objc func usersLoaded(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self,
                                                  name: .AllUsers,
                                                  object: nil)
        appDelegate.allTheUsers = notification.userInfo!["users"] as? [User]
        print("all users found")
        self.usersLoaded = true
        if self.messagesLoaded && self.classesLoaded {
            NotificationCenter.default.post(name: .InitialPreparation, object: self)
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
            NotificationCenter.default.post(name: .InitialPreparation, object: self)
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
            NotificationCenter.default.post(name: .InitialPreparation, object: self)
        }
    }
    
    
   
    public func logout() {
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
}
