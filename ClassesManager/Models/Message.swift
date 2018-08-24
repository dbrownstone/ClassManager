//
//  Message.swift
//  MultiTab
//
//  Created by David Brownstone on 21/04/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit
import Firebase

class Message: NSObject {
    var uid: String?
    var fromId: String?
    var toId: String?
    var textMessage: String?
    var timeStamp:NSNumber?
    var authorType: AuthorType?
    var messageType: MessageType?
    
    var imageUrl: String?
    var profileImage: UIImage?
    var imageWidth: NSNumber?
    var imageHeight: NSNumber?
    
    var videoUrl: String?
    var pictureUrl: String?
    var pictureImage = UIImage()
    
    init(dictionary: [String: AnyObject], fromDatabase: Bool = false) {
        super.init()
        fromId = dictionary["fromId"] as? String
        if fromId == appDelegate.loggedInId {
            authorType = .authorTypeSelf
        } else {
            authorType = .authorTypeOther
        }
        toId = dictionary["toId"] as? String
        if dictionary["text"] != nil {
            textMessage = dictionary["text"] as? String
            messageType = .textMessageType
        } else {
            pictureUrl = dictionary["photoURL"] as? String
            messageType = .imageMessageType
            if let URL = URL(string: pictureUrl!),
                let data = try? Data(contentsOf: URL) {
                pictureImage = UIImage(data: data)!
            }
        }
        if !fromDatabase {
            imageUrl = dictionary["imageURL"] as? String
            if let URL = URL(string: imageUrl!),
                let data = try? Data(contentsOf: URL) {
                profileImage = UIImage(data: data)!
            }
        }
        timeStamp = dictionary["timeStamp"] as? NSNumber
        
        
//        videoUrl = dictionary["videoUrl"]  as? String

//        if !fromDatabase {
//            if dictionary["textLabel"] != nil {
//                textLabel = dictionary["textLabel"] as? UILabel
//            } else {
//                msgImageView = dictionary["photoImageView"] as? UIImageView
//            }
//            imageUrl = dictionary["imageURL"] as? String
//            imageWidth = dictionary["imageWidth"] as? NSNumber
//            imageHeight = dictionary["imageHeight"] as? NSNumber
//            isReceived = (dictionary["isReceived"] as? Bool)!
//            bubble = dictionary["bubble"] as? UIView
//            bubbleSize = dictionary["bubbleSize"] as? CGSize
//        }
    }
    
    init(snapshot: DataSnapshot) {
        uid = snapshot.key
        let snapshotValue = snapshot.value as! [String: AnyObject]
        fromId = snapshotValue[Constants.MessageFields.fromId] as? String
        toId = snapshotValue[Constants.MessageFields.toId] as? String
        if fromId == appDelegate.loggedInId {
            authorType = .authorTypeSelf
        } else {
            authorType = .authorTypeOther
        }
        textMessage = snapshotValue[Constants.MessageFields.textMessage] as? String
        if textMessage == nil {
            messageType = .imageMessageType
            pictureUrl = snapshotValue[Constants.MessageFields.photoURL] as? String
            if let URL = URL(string: pictureUrl!),
                let data = try? Data(contentsOf: URL) {
                pictureImage = UIImage(data: data)!
            }
        } else {
            messageType = .textMessageType
        }
        timeStamp = snapshotValue[Constants.MessageFields.timeStamp] as? NSNumber
        
    }
    
    func toAnyObject() -> Any {
        return [
            Constants.MessageFields.fromId: fromId as Any,
            Constants.MessageFields.toId: toId as Any,
            Constants.MessageFields.textMessage: textMessage as Any,
            Constants.MessageFields.timeStamp: timeStamp as Any,
            Constants.MessageFields.imageURL: pictureUrl as Any
        ]
    }
}
