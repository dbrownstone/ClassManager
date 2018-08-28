//
//  ChatViewExtensions.swift
//  ChatViewExtensions
//
//  Created by David Brownstone on 26/06/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit
import Firebase

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: -  Getting/Receiving Messages
    
    // Get Messages
    func getChatMessagesFor(_ uid: String) {
        SwiftActivity.show(title: "Loading chat messages", animated: true)
        if groupChat {
            let selectedClassMessageIds = self.selectedClassForChat.chatMessages
            for msgId in selectedClassMessageIds {
                for message in self.allAvailableMessages {
                    if message.uid == msgId {
                        self.getAndAppendTheMessages(message)
                        break
                    }
                }
            }
        } else {
            var selectedUserMessageIds = self.theObjectMember.chatMessages
            selectedUserMessageIds += appDelegate.thisMember!.chatMessages
            for msgId in selectedUserMessageIds {
                for message in self.allAvailableMessages {
                    if message.uid == msgId {
                        if (message.toId == self.theObjectMember.uid ||
                            message.fromId == self.theObjectMember.uid) &&
                            (message.toId == appDelegate.loggedInId ||
                                message.fromId == appDelegate.loggedInId) {
                            self.getAndAppendTheMessages(message)
                            break
                        }
                    }
                }
            }
            SwiftActivity.hide()
        }
        if chatMessages.count == 0 {
            SwiftActivity.hide()
        }
        self.sortMessagesByDate()
        if self.selectedClassForChat != nil {
            DispatchQueue.main.async(execute: {
                self.adjustTheTableView()
                self.theTableView?.reloadData()
            })
        }
    }
    
    func getAndAppendTheMessages(_ message: Message) {
        if self.messageShouldBeVisible(timeStamp:message.timeStamp!) {
            if message.fromId == appDelegate.loggedInId {
                message.authorType = .authorTypeSelf
            } else {
                message.authorType = .authorTypeOther
            }
            for aMember in appDelegate.allTheUsers! {
                if aMember.uid == message.fromId {
                    message.imageUrl = aMember.profileImageUrl
                    break
                }
            }
            if self.chatMessages.contains(message) {
                print("message with id \(String(describing: message.uid)) is duplicated in self.chatMessages")
                return
            }
            
            self.chatMessages.append(message)
        }
    }
    
    func observeNewMessagesFor(_ id: String) {
        //from either theObjectMember or selectedClassForChat
        let ref = Database.database().reference().child(Constants.DatabaseChildKeys.Messages)
        
        ref.queryLimited(toLast: 1).observe(.childAdded, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let message = Message(dictionary: dictionary, fromDatabase: true)
                if message.timeStamp!.doubleValue <= self.mostRecentMsgTimeStamp!.doubleValue {
                    return
                }
                message.uid = snapshot.key
                if message.toId == id && self.messageShouldBeVisible(timeStamp:message.timeStamp!) {
                    if message.fromId == appDelegate.loggedInId {
                        message.authorType = .authorTypeSelf
                    } else {
                        message.authorType = .authorTypeOther
                        for aMember in appDelegate.allTheUsers! {
                            if aMember.uid == message.fromId {
                                if aMember.profileImageUrl == nil {
                                    if self.groupChat == false {
                                        aMember.profileImageUrl = self.theObjectMember.name
                                    } else {
                                        aMember.profileImageUrl = appDelegate.thisMember?.profileImageUrl
                                    }
                                }
                                message.imageUrl = aMember.profileImageUrl
                                break
                            }
                        }
                    }
                }
                self.appendSortAndDispatchMessage(message)
                appDelegate.allAvailableMessages.append(message)
                self.allAvailableMessages = appDelegate.allAvailableMessages
                self.allAvailableMessages.sort(by: {(message1, message2) -> Bool in
                    return (message1.timeStamp?.intValue)! > (message2.timeStamp?.intValue)!
                })
                self.mostRecentMsgTimeStamp = (self.allAvailableMessages[0]).timeStamp
            }
        })
    }

    // MARK: - Sending Messages
    
    
    @IBAction func sendAMessage(_ sender: UIButton) {
        //        self.cancelKeyboard(sender)
        let timeStamp = NSDate().timeIntervalSince1970 as Double
        var value = [String: Any]()
        if self.messageToUid == nil  {
            if groupChat {
                self.messageToUid = selectedClassForChat.uid
            } else {
                self.messageToUid = self.theObjectMember.uid
            }
        }
        if self.messageImageUrlStr == nil || self.messageImageUrlStr.isEmpty {
            value = [
                Constants.MessageFields.fromId : appDelegate.loggedInId as AnyObject,
                Constants.MessageFields.toId: self.messageToUid as AnyObject,
                Constants.MessageFields.textMessage: sendingTextField.text as AnyObject,
                Constants.MessageFields.timeStamp: timeStamp
            ]
        } else {
            value = [
                Constants.MessageFields.fromId : appDelegate.loggedInId as AnyObject,
                Constants.MessageFields.toId: self.messageToUid as AnyObject,
                Constants.MessageFields.photoURL: self.messageImageUrlStr as AnyObject,
                Constants.MessageFields.timeStamp: timeStamp
            ]
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.messageHasBeenAdded(notification:)),
                                               name: .MsgDBUpdated,
                                               object: nil)
        dbAccess.addAndUpdateAMessage(value)
        
        sendingTextField.text = ""
        self.messageImageUrlStr = ""
    }
    
    @objc func messageHasBeenAdded(notification: NSNotification) {
        let messageUid = notification.object as! String
        if groupChat {
            self.selectedClassForChat?.chatMessages.append(messageUid)
            dbAccess.updateClassMessagesDatabase(self.selectedClassForChat!)
        } else {
            let fromUid = notification.userInfo![Constants.MessageFields.fromId] as! String
            if fromUid == appDelegate.thisMember?.uid {
                appDelegate.thisMember?.chatMessages.append(messageUid)
                dbAccess.updateUserWithMessage(appDelegate.thisMember!, messageId: messageUid)
            } else if fromUid == self.theObjectMember?.uid  {
                self.theObjectMember?.chatMessages.append(messageUid)
                dbAccess.updateUserWithMessage(theObjectMember!, messageId: messageUid)
            }
        }
    }
    
    @IBAction func addAnImage(_ sender: UIButton) {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.sendImageMessage(notification:)),
                                               name: .NewChatMessageImage,
                                               object: nil)
        SwiftActivity.show(title: "Connecting to image picker...", animated: true)
        print(" handleSelectMessageImageView")
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        
        picker.delegate = self
        picker.allowsEditing = true
        self.dontShowClassAlert = true
        present(picker, animated: true, completion: {
            SwiftActivity.hide()
        })
    }
    
    @objc func sendImageMessage(notification: NSNotification) {
        let userInfo = notification.userInfo
        NotificationCenter.default.removeObserver(self, name: .NewChatMessageImage, object: nil)
        //        self.dismiss(animated: true, completion: nil)
        self.messageImageUrlStr = userInfo!["url"] as! String
        
        self.sendAMessage(self.newMessageSendButton)
    }

    // MARK: -  Message Handling
    
    func appendSortAndDispatchMessage(_ message: Message) {
        self.chatMessages.append(message)
        self.sortMessagesByDate()
        DispatchQueue.main.async(execute: {
            self.adjustTheTableView()
            self.theTableView?.reloadData()
        })
    }
    
    public func messageShouldBeVisible(timeStamp:NSNumber) -> Bool {
        var visibilityPeriod: String!
        var theDuration:Int
        
        if groupChat {
            visibilityPeriod = standardDefaults.string(forKey: Constants.StdDefaultKeys.ClassChatVisibilityPeriod)
        } else {
            visibilityPeriod = standardDefaults.string(forKey: Constants.StdDefaultKeys.IndividualChatVisibilityPeriod)
        }
        if visibilityPeriod == activeTimes.noLimit.rawValue {
            return true
        }
        
        let timeStampDate = Date(timeIntervalSince1970: timeStamp.doubleValue)
        
        switch visibilityPeriod {
        case activeTimes.oneDay.rawValue:
            theDuration = 1
            break
        case activeTimes.oneWeek.rawValue:
            theDuration = 7
            break
        case activeTimes.twoWeeks.rawValue:
            theDuration = 14
            break
        case activeTimes.fourWeeks.rawValue:
            theDuration = 28
            break
        default:
            theDuration = -1
            break
        }
        
        let dateOfVisibility = Calendar.current.date(byAdding: .day, value: theDuration, to: timeStampDate)
        let today = NSDate()
//        print("Today: \(today) visibilityDate: \(dateOfVisibility!)")
        return today.earlierDate(dateOfVisibility!) == today as Date
    }
    
    func sortMessagesByDate() {
        self.chatMessages.sort(by: {(message1, message2) -> Bool in
            return (message1.timeStamp?.intValue)! > (message2.timeStamp?.intValue)!
        })
    }
   
    func storeMessageImageInDatabase() {
        print(" storeImageViewInDatabase")
        let imagename = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child(Constants.StorageChildKeys.MessageImages).child("\(imagename).png")
        if let msgImage = self.selectedPickerImage, let uploadData = UIImageJPEGRepresentation(msgImage, 0.1) {
            storageRef.putData(uploadData, metadata: nil, completion: {(metadata,error) in
                if error != nil {
                    print(error?.localizedDescription as Any)
                    return
                }
                storageRef.downloadURL { url, error in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    let urlStr = url!.absoluteString
                    NotificationCenter.default.post(name: .NewChatMessageImage, object: nil, userInfo: ["url": urlStr])
                }
            })
        }
    }

    //  MARK: -  Image Handling
    /**
     UIImagePickerControllerDelegate method to cancel image selection
     
     - Parameter picker: the UIImagePickerController
     */
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("cancelled picker")
        dismiss(animated: true, completion: nil)
    }
    
    /**
     UIImagePickerControllerDelegate method to select the picked image
     
     - Parameter picker: the UIImagePickerController
     - Parameter: info: dictionary of image values
     */
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImageFromPicker:UIImage?
        
        if let editedImage = info[UIImagePickerControllerEditedImage] {
            selectedImageFromPicker = editedImage as? UIImage
        } else if let originalImage = info[UIImagePickerControllerOriginalImage] {
            selectedImageFromPicker = originalImage as? UIImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            self.selectedPickerImage = selectedImage
            //ToDo: need to check for an existing image before storing in db
            self.storeMessageImageInDatabase()
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    //  MARK: -  Keyboard handling
    
    @objc func keyboardUp(notification: NSNotification) {
        if ((notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue) != nil {
            keyboardSize = ((notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue)!
            self.view.frame.origin.y = -(keyboardSize!.height)
        }
    }
    
    @objc func keyboardDown(notification: NSNotification) {
        if ((notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue) != nil {
            self.view.frame.origin.y = 0
        }
    }

}
