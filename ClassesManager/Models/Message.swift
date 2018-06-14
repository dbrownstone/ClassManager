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
    var fromId:String?
    var toId:String?
    var textMessage: String?
    var timeStamp:NSNumber?
    var bubble: UIView?
    var bubbleSize: CGSize?
    var isReceived = false
    var textLabel: UILabel?
    
    var imageUrl: String?
    var imageWidth: NSNumber?
    var imageHeight: NSNumber?
    
    var videoUrl: String?
    
    init(dictionary: [String: AnyObject], fromDatabase: Bool = false) {
        super.init()
        
        fromId = dictionary["fromId"] as? String
        toId = dictionary["toId"] as? String
        textMessage = dictionary["text"] as? String
        timeStamp = dictionary["timeStamp"] as? NSNumber
        
        
//        videoUrl = dictionary["videoUrl"]  as? String

        if !fromDatabase {
            textLabel = dictionary["textLabel"] as? UILabel
            imageUrl = dictionary["imageURL"] as? String
            imageWidth = dictionary["imageWidth"] as? NSNumber
            imageHeight = dictionary["imageHeight"] as? NSNumber
            isReceived = (dictionary["isReceived"] as? Bool)!
            bubble = dictionary["bubble"] as? UIView
            bubbleSize = dictionary["bubbleSize"] as? CGSize
        }
    }
    
    init(snapshot: DataSnapshot) {
        let snapshotValue = snapshot.value as! [String: AnyObject]
        fromId = snapshotValue[Constants.MessageFields.fromId] as? String
        toId = snapshotValue[Constants.MessageFields.toId] as? String
        textMessage = snapshotValue[Constants.MessageFields.textMessage] as? String
        timeStamp = snapshotValue[Constants.MessageFields.timeStamp] as? NSNumber
    }
    
    func isAReceivedMsg() -> Bool {
        return isReceived
    }
    
    func toAnyObject() -> Any {
        return [
            Constants.MessageFields.fromId: fromId as Any,
            Constants.MessageFields.toId: toId as Any,
            Constants.MessageFields.textMessage: textMessage as Any,
            Constants.MessageFields.timeStamp: timeStamp as Any,
            Constants.MessageFields.imageURL: imageUrl as Any
        ]
    }
}
