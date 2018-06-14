//
//  DatabaseAccess.swift
//  MultiTab
//
//  Created by David Brownstone on 18/04/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class DatabaseAccess: NSObject {
    
    var allUsers: [User]!
    
    override init() {
        super.init()
    }
    
    /**
        authorize and log this user in
     */
    public func authorizeThisExistingUser(with email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password, completion: { (user,error) in
            if error != nil {
                print(error ?? "")
                NotificationCenter.default.post(name: .Authorized, object: self, userInfo: ["error": (error?.localizedDescription)!])
                return
            }
        })
    }
    
    /**
     authorize and log this user in with new password
     */
    public func authorizeWithNewPassword(to password: String) {
        
        Auth.auth().currentUser?.updatePassword(to: password) { (error) in
            var theErrorDescription = ""
            if error != nil {
                print(error ?? "")
                theErrorDescription = (error?.localizedDescription)!
            }
            NotificationCenter.default.post(name: .AuthorizeNewPassword, object: self, userInfo: ["error": theErrorDescription])
        }
    }
    
//    public func isUserCurrentlySignedIn(_ email: String) {
//        
//    }
    
    /**
     gets all current users
     */
    public func getAllUsers() {
        let userRef = Database.database().reference().child(Constants.DatabaseChildKeys.Users)
        userRef.observe(.value, with: { snapshot in
            self.allUsers = [User]()
            for aUser in snapshot.children {
                self.allUsers.append(User(snapshot: aUser as! DataSnapshot))
            }
            NotificationCenter.default.post(name: .AllUsers, object: self, userInfo: ["users": self.allUsers])
        })
    }
    
    /**
     gets all current users
     */
    public func getAUser(_ email: String) {
        let userRef = Database.database().reference().child(Constants.DatabaseChildKeys.Users)
        userRef.observe(.value, with: { snapshot in
            for aUser in snapshot.children {
                let member = User(snapshot: aUser as! DataSnapshot)
                if member.email == email {
                    NotificationCenter.default.post(name: .AUser, object: self, userInfo: ["error": "", "user": member])
                    return
                }
            }
            NotificationCenter.default.post(name: .AUser,
                                            object: self,
                                            userInfo: ["error": "User not found"])
        })
    }
    
    public func getAllClasses() {
        let firebase = Database.database().reference()
        firebase.child(Constants.DatabaseChildKeys.Classes).observe(.value, with: { snapshot in
            var classes = [Class]()
            for aUser in snapshot.children {
                classes.append(Class(snapshot: aUser as! DataSnapshot))
            }
            NotificationCenter.default.post(name: .AllClasses, object: self, userInfo: ["classes": classes])
        })
    }
    
    public func addAndUpdateAMessage(_ values: [String: Any]) {        
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        
        childRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if error != nil {
                print(error ?? "Send error")
                return
            }
        })
    }
    
    public func getAllMessages(_ id: String) {
        let firebase = Database.database().reference()
        firebase.child(Constants.DatabaseChildKeys.Messages).observe(.value, with: { snapshot in
            var messages = [Message]()
            for aMsg in snapshot.children {
                let message = Message(snapshot: aMsg as! DataSnapshot)
                if message.toId == id || message.fromId == id {
                    if message.toId == id {
                        message.isReceived = false
                    } else {
                        message.isReceived = true
                    }
                    messages.append(message)
                }
            }
            NotificationCenter.default.post(name: .AllMessages, object: self, userInfo: ["messages": messages])
        })
    }
    
    public func setOnlineState(_ state: Bool) {
        print( "setOnlineState")
        let usersReference = Database.database().reference(withPath: Constants.DatabaseChildKeys.Users)
        let values: [String: Any] = [
            Constants.UserFields.online: state, Constants.UserFields.authorized: true
        ]
        let userRef = usersReference.child(appDelegate.loggedInId)
        userRef.updateChildValues(values, withCompletionBlock: {
            (err, ref) in
            if err != nil {
                print(err?.localizedDescription ?? "")
                return
            }
        })
    }
    
    /**
     adds a new user to the "users" Firestone database
     
     - Parameter uid: new user's udid
     - Parameter values: Dictionary of all the user values - email, name, phone number ...
     */
    
    public func registerUserIntoDatabaseWithUID(uid: String, values: [String: AnyObject]) {
        print(" registerUserIntoDatabaseWithUID")
        let ref = Database.database().reference(fromURL: databaseURL)
        let usersRef = ref.child(Constants.DatabaseChildKeys.Users).child(uid)
        //
        usersRef.updateChildValues(values, withCompletionBlock: {(err, ref) in
            if err != nil {
                print(err?.localizedDescription ?? "")
                return
            }
            NotificationCenter.default.post(name: .RegisterUser, object: nil)
        })
    }
    
    public func updateClassMembersDatabase(_ thisClass: Class) {
        let ref = Database.database().reference(fromURL: databaseURL)
        let classRef = ref.child(Constants.DatabaseChildKeys.Classes).child(thisClass.uid)
        classRef.updateChildValues([Constants.ClassFields.members: thisClass.members])
    }
    
    public func addAClassToTheClassDatabase(_ thisNewClass: Class) {
        let classRef = Database.database().reference().child(Constants.DatabaseChildKeys.Classes).child(thisNewClass.uid)
        classRef.setValue(thisNewClass.toAnyObject())
        NotificationCenter.default.post(name: .ClassDBUpdated, object: nil)
    }
    
    public func addAMessageToTheMessagesDatabase(_ thisNewMsg: Message) {
        let msgRef = Database.database().reference().child(Constants.DatabaseChildKeys.Messages).child(UUID().uuidString)
        msgRef.setValue(thisNewMsg.toAnyObject())
//        NotificationCenter.default.post(name: .MsgDBUpdated, object: nil)
    }
    
    /**
        Sign-in an existing user
    */
    
    public func signIn(_ email: String, password: String) {
        var theError = ""
        Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
            if error != nil {
                theError = (error?.localizedDescription)!
                print(theError)
            }
            NotificationCenter.default.post(name: .SignIn, object: nil, userInfo: ["error": theError])
        })
    }
    
    public func observeIncomingMessages() {
        Database.database().reference().child("messages").observe(.childAdded, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let returnedMessage = Message(dictionary: dictionary, fromDatabase: true)
                NotificationCenter.default.post(name: .NewMessage, object: self, userInfo: ["message": returnedMessage])
            }
        })
    }
}
