//
//  Class
//  MultiTab
//
//  Created by David Brownstone on 3/04/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import Foundation
import Firebase

struct Class {
    let uid: String
    let location: String
    let name: String
    let dayAndTime: String
    let teacher: String
    let teacherUid: String
    var members: [String]
    var chatMessages: [String]
    
    init(name: String, location: String, day_time: String, teacher: String, teacherUid: String, thisMember: String) {
        self.uid = UUID().uuidString
        self.name = name
        self.location = location
        self.dayAndTime = day_time
        self.teacher = teacher
        self.teacherUid = teacherUid
        self.members = [String]()
        self.chatMessages = [String]()
    }
    
    init(snapshot: DataSnapshot) {
        uid = snapshot.key
        let snapshotValue = snapshot.value as! [String: AnyObject]
        name = snapshotValue[Constants.ClassFields.name] as! String
        location = snapshotValue[Constants.ClassFields.location] as! String
        dayAndTime = snapshotValue[Constants.ClassFields.day_time] as! String
        teacher = snapshotValue[Constants.ClassFields.teacher] as! String
        teacherUid = snapshotValue[Constants.ClassFields.teacherUid] as! String
        if snapshotValue[Constants.ClassFields.members] != nil  {
            members = (snapshot.value as! [String: AnyObject])[Constants.ClassFields.members] as! [String]
        } else {
            members = [String]()
        }
        if snapshotValue[Constants.ClassFields.messages] != nil  {
            chatMessages = (snapshot.value as! [String: AnyObject])[Constants.ClassFields.messages] as! [String]
        } else {
            chatMessages = [String]()
        }
    }
    
    func toAnyObject() -> Any {
        return [
            Constants.ClassFields.name: name,
            Constants.ClassFields.location: location,
            Constants.ClassFields.day_time: dayAndTime,
            Constants.ClassFields.teacher: teacher,
            Constants.ClassFields.teacherUid: teacherUid,
            Constants.ClassFields.members: members,
            Constants.ClassFields.messages: chatMessages
        ]
    }
    
    func numberOfUsers() -> Int {
        return self.members.count
    }
    
    mutating func addAMember(id:String) {
        self.members.append(id)
    }
    
    
    mutating func addAMessage(id:String) {
        self.chatMessages.append(id)
    }
    
    mutating func indexOf(_ id: String) -> Int {
        var index = -1
        for memberId in self.members {
            if memberId == id {
                break
            } else {
                index += 1
            }
        }
        return index
    }
    
    mutating func removeAMember(index: Int) {
        self.members.remove(at: index)
    }
}
