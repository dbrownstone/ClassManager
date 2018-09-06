//
//  User.swift
//  ClassesManager
//
//  Created by David Brownstone on 03/04/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.


import UIKit
import Firebase
import FirebaseDatabase

class User: NSObject {
    
    var uid:String?
    var name:String?
    var phoneNo: String?
    var email:String?
    var authorized = false
    var profileImageUrl:String?
    var isOnline: Bool?    
    var chatMessages = [String]()
    
    override init() {
        super.init()
    }
    
    init(name: String, phoneNo: String, email: String, profileImageUrl: String) {
        self.name = name
        self.phoneNo = phoneNo
        self.email = email
        self.profileImageUrl = profileImageUrl
        self.isOnline = false
    }
    
    init(snapshot: DataSnapshot) {
        uid = snapshot.key
        let snapshotValue = snapshot.value as! [String: AnyObject]
        name = snapshotValue[Constants.UserFields.name] as? String
        self.phoneNo = snapshotValue[Constants.UserFields.phoneNo] as? String
        self.email = snapshotValue[Constants.UserFields.email] as? String
        if snapshotValue[Constants.UserFields.authorized] != nil {
            self.authorized = snapshotValue[Constants.UserFields.authorized] as! Bool
        }
        if snapshotValue[Constants.UserFields.messages] != nil && (snapshotValue[Constants.UserFields.messages]?.count)! > 0 {
            chatMessages = ((snapshot.value as! [String: AnyObject])[Constants.UserFields.messages] as? [String])!
        } else {
            chatMessages = [String]()
        }
        self.profileImageUrl = snapshotValue[Constants.UserFields.imageUrl] as? String
        self.isOnline = snapshotValue[Constants.UserFields.online] as? Bool
    }
    
    func toAnyObject() -> Any {
        return [
            Constants.UserFields.name: name as Any,
            Constants.UserFields.phoneNo: phoneNo as Any,
            Constants.UserFields.email: email as Any,
            Constants.UserFields.authorized:authorized as Any,
            Constants.UserFields.online: isOnline as Any,
            Constants.UserFields.imageUrl: profileImageUrl as Any,
            Constants.UserFields.messages: chatMessages as Any
        ]
    }
    
}
