//
//  ChatViewController.swift
//  MultiTab
//
//  Created by David Brownstone on 03/07/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import SwiftSpinner

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, BubbleTableViewCellDelegate, BubbleTableViewCellDataSource{
    
    var selectedClass: String!

    @IBOutlet weak var newMessageSendButton: UIButton!
    @IBOutlet weak var camera: UIButton!
    @IBOutlet weak var classMembership: UICollectionView!
    
    var classes: [Class]!
    var groupChat = true
    var chatClassMembers: [User]!
    var classTeacher: User!
    var classSelectionCancelled = false
    
    var selectedClassForChat: Class!
    {
        didSet {
            if selectedClassForChat == nil && !(selectedClass.isEmpty) {
                for aClass in self.classes {
                    if aClass.name == self.selectedClass {
                        selectedClassForChat = aClass
                        break
                    }
                }
            }
            navigationItem.title = selectedClassForChat.name + " Chat"
            
            groupChat = true
            
            observeMessagesInSelectedGroup()
        }
    }
    
    var chatMessages = [Message]()
    var selectedPickerImage: UIImage!
    var cells = [BubbleTableViewCell]()
    var messageImageUrlStr: String!
    var dontShowClassAlert = false
    
    var theObjectMember: User!
    var messageToUid: String!
    var keyboardSize:CGRect? = nil
    
    @IBOutlet weak var chatName: UILabel!
    @IBOutlet weak var sendingTextField: UITextField!
    
    @IBOutlet weak var theTableView: UITableView!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var msgBar: UIView!
    
    var originalTableViewHeight: CGFloat!
    var originalTableViewWidth: CGFloat!
    var originalTableViewOriginY: CGFloat!
    
    var fromMember: User!
    var loggedInUsers: [User]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        defaultStyle()
        self.theTableView.delegate = self
        self.theTableView.dataSource = self
        self.classMembership.delegate = self as? UICollectionViewDelegate
        self.classMembership.dataSource = self
        
        self.originalTableViewOriginY = UIApplication.shared.statusBarFrame.size.height +
            (self.navigationController?.navigationBar.frame.height ?? 0.0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardUp), name:.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardDown), name: .UIKeyboardWillHide, object: nil)
    }
    
    @IBAction func cancelKeyboard(_ sender: Any) {
        sendingTextField.resignFirstResponder()
    }
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if dontShowClassAlert {
            redisplayTableViewDataSorted()
            dontShowClassAlert = false
            if theObjectMember == nil {
                for aClass in classes {
                    if aClass.uid == self.messageToUid {
                        self.selectedClassForChat = aClass
                        break
                    }
                }
            }
            return
        }
        self.title = "Chat"
        if theObjectMember != nil {
            addBackButton()
            let name = theObjectMember.name
            self.title = "Chat: \(name!)"
            self.messageToUid = theObjectMember.uid
            observeMessagesForIndividualChat()
        } else if selectedClassForChat != nil {
            observeMessagesInSelectedGroup()
            let name = selectedClassForChat.name
            self.messageToUid = selectedClassForChat.uid
            self.title = "Chat: \(name)"
            groupChat = true
            self.loggedInUsers = [User]()
            for aMember in appDelegate.allTheUsers! {
                if aMember.uid == selectedClassForChat.teacherUid {
                    self.classTeacher = aMember
                    self.chatClassMembers.append(self.classTeacher)
                    break
                }
            }
            
        } else if !self.classSelectionCancelled {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.classesLoaded(notification:)),
                                                   name: .AllClasses,
                                                   object: nil)
            dbAccess.getAllClasses()
        }
        redisplayTableViewDataSorted()
    }

    func appendSortAndDispatchMessage(_ message: Message, makeSmaller: Bool) {
        self.chatMessages.append(message)
        self.sortMessagesByDate()
        DispatchQueue.main.async(execute: {
            self.adjustTheTableView(makeSmaller)
            self.theTableView?.reloadData()
        })
    }
    
    func observeMessagesInSelectedGroup() {
        self.chatMessages = [Message]()
        Database.database().reference().child("messages").observe(.childAdded, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let message = Message(dictionary: dictionary, fromDatabase: true)
                if message.toId == self.selectedClassForChat.uid  {//&& self.messageShouldBeVisible(timeStamp:message.timeStamp!) {
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
                    self.appendSortAndDispatchMessage(message, makeSmaller: true)
                }
            }
        })
    }
    
    func observeMessagesForIndividualChat() {
        self.chatMessages = [Message]()
        Database.database().reference().child("messages").observe(.childAdded, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let message = Message(dictionary: dictionary, fromDatabase: true)
                if (message.toId == self.theObjectMember.uid && message.fromId == appDelegate.loggedInId) ||
                    (message.toId == appDelegate.loggedInId && message.fromId == self.theObjectMember.uid) {
                    if message.fromId == appDelegate.loggedInId {
                        message.authorType = .authorTypeSelf
                    } else {
                        message.authorType = .authorTypeOther
                        message.imageUrl = self.theObjectMember.profileImageUrl
                        
                    }
                    self.appendSortAndDispatchMessage(message, makeSmaller: false)
                }
            }
        })
    }
    
    func sortMessagesByDate() {
        self.chatMessages.sort(by: {(message1, message2) -> Bool in
            return (message1.timeStamp?.intValue)! > (message2.timeStamp?.intValue)!
        })
    }
    
    @objc func classesLoaded(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self,
                                                  name: .AllClasses,
                                                  object: nil)
        let existingClasses = (notification.userInfo!["classes"] as? [Class])!
        // display only the classes of which this user is a member
        classes = [Class]()
        for aClass in existingClasses {
            if aClass.teacher ==  appDelegate.loginName {
                classes.append(aClass)
                continue
            } else {
                if aClass.members.contains(appDelegate.loggedInId) {
                    classes.append(aClass)
                }
            }
        }
        if classes.count > 1 {
            self.performSegue(withIdentifier: Constants.Segues.ShowClassAlert, sender: nil)
        } else {
            self.selectedClassForChat = classes[0]
            self.selectedClass = self.selectedClassForChat.name
//            self.adjustTheTableView()
            self.chatClassMembers = [User]()
            for aMember in appDelegate.allTheUsers! {
                if aMember.uid == selectedClassForChat.teacherUid {
                    self.classTeacher = aMember                    
                } else {
                    if self.selectedClassForChat.members.contains(aMember.uid!) {
                        self.chatClassMembers.append(aMember)
                    }
                }
            }
            self.chatClassMembers.append(self.classTeacher)
            self.classMembership.reloadData()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        var makeSmaller = true
        if selectedClassForChat == nil {
            makeSmaller = false
        }
        self.adjustTheTableView(makeSmaller)
    }
    
    func addBackButton() {
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(named: "back"), for: .normal)
        backButton.addTarget(self, action: #selector(self.backAction(_:)), for: .touchUpInside)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        self.performSegue(withIdentifier: "returnFromChat", sender: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .UserStateChanged, object: nil)
//        self.theTableView.frame = CGRect(x: 0, y: 64.0, width: self.originalTableViewWidth!, height: self.originalTableViewHeight!)
    }
    
    func defaultStyle() {
        newMessageSendButton.tintColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
        reloadInputViews()
    }
    
    func redisplayTableViewDataSorted() {
        sortMessagesByDate()
        self.theTableView.reloadData()
    }
    
    @objc func addToLoggedInList(notification: NSNotification) {
        let email = notification.userInfo!["email"] as! String
        if email.isEmpty {
            return
        }
        for aUser in self.chatClassMembers {
            if aUser.email == email {
                self.loggedInUsers.append(aUser)
                self.classMembership.reloadData()
                break
            }
        }
    }
    
    @IBAction func sendAMessage(_ sender: UIButton) {
        let timeStamp = NSDate().timeIntervalSince1970 as Double
        var value = [String: Any]()
        if self.messageToUid == nil {
            self.messageToUid = selectedClassForChat.uid
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
        dbAccess.addAndUpdateAMessage(value)
        sendingTextField.text = ""
        self.messageImageUrlStr = ""
    }
    
    @IBAction func addAnImage(_ sender: UIButton) {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.sendImageMessage(notification:)),
                                               name: .NewChatMessageImage,
                                               object: nil)
        SwiftSpinner.show("Connecting to image picker...")
        SwiftSpinner.sharedInstance.backgroundColor = .clear
        print(" handleSelectMessageImageView")
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerControllerSourceType.photoLibrary

        picker.delegate = self
        picker.allowsEditing = true
        self.dontShowClassAlert = true
        present(picker, animated: true, completion: {
            SwiftSpinner.hide()
        })
    }
    
    @objc func sendImageMessage(notification: NSNotification) {
        let userInfo = notification.userInfo
        NotificationCenter.default.removeObserver(self, name: .NewChatMessageImage, object: nil)
//        self.dismiss(animated: true, completion: nil)
        self.messageImageUrlStr = userInfo!["url"] as! String
        
        self.sendAMessage(self.newMessageSendButton)
    }
    
    // MARK: - UITableViewDelegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatMessages.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let message = self.chatMessages[indexPath.row]
        var image: UIImage!
        var max = tableView.frame.size.width * 0.55
        if message.messageType == .imageMessageType {
            if let URL = URL(string: message.pictureUrl!),
                let data = try? Data(contentsOf: URL) {
                image = UIImage(data: data)
                if (image?.size.width)! < max {
                    max = (image?.size.width)!
                }
            }
        }
        var size = CGSize(width: max, height: max)

        if message.authorType == .authorTypeSelf {
            if message.messageType == .textMessageType {
                size = (message.textMessage?.boundingRect(
                    with: CGSize(width: tableView.frame.size.width * 0.55,
                                 height: CGFloat.greatestFiniteMagnitude),
                    options: .usesLineFragmentOrigin,
                    attributes: [.font: UIFont.systemFont(ofSize: 14.0)],
                    context:nil).size)!
            }
        } else {
            if message.messageType == .textMessageType {
                size = (message.textMessage?.boundingRect(
                    with: CGSize(width: tableView.frame.size.width * 0.55,
                                 height: CGFloat.greatestFiniteMagnitude),
                    options: .usesLineFragmentOrigin,
                    attributes: [.font: UIFont.systemFont(ofSize: 14.0)],
                    context:nil).size)!
            }
        }

        if message.messageType == .imageMessageType {
            let imageHeight = size.width * (image.size.height / image.size.width)
            if message.authorType == .authorTypeOther {
                return imageHeight + AuthorImageSize + BubbleHeightOffset
            }
            return imageHeight + BubbleHeightOffset + AuthorImageSize
        }
        
        if message.authorType == .authorTypeOther {
            return size.height + AuthorImageSize + BubbleHeightOffset
        }
        return size.height + BubbleHeightOffset + AuthorImageSize
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let thisMessage = chatMessages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.CellIdentifiers.BubbleCell, for: indexPath) as! BubbleTableViewCell
        if thisMessage.messageType == .textMessageType {
            cell.messageType = .textMessageType
            cell.msgTextLabel?.text = thisMessage.textMessage
        } else {
            cell.messageType = .imageMessageType
        }
        
        cell.authorType = thisMessage.authorType!
        cell.indexPath = indexPath
        cell.dataSource = self
        cell.delegate = self
        
        if thisMessage.messageType == .textMessageType {
            cell.msgTextLabel?.font = UIFont.systemFont(ofSize: 14.0);
        } else {
            cell.messageImageUrl = thisMessage.pictureUrl
        }
        
        if thisMessage.authorType == .authorTypeOther {
            cell.userImageUrl = thisMessage.imageUrl
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E MMM d, HH:mm"
        dateFormatter.timeZone = NSTimeZone.local
        let myTimeInterval = TimeInterval(truncating: thisMessage.timeStamp!)
        let time = NSDate(timeIntervalSince1970: TimeInterval(myTimeInterval))
        cell.timeStamp = dateFormatter.string(from:time as Date )
        
        cell.prepare()

        cells.append(cell)
        
        return cell
    }
    
    func configureSentMsgCell(cell: UITableViewCell, message: Message) {
        print("configureSentMsgCell")
//        let bubble = cell.viewWithTag(100) as! UIImageView
        let dateLabel = cell.viewWithTag(125) as! UILabel
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E MMM d, HH:mm"
        dateFormatter.timeZone = NSTimeZone.local
        let myTimeInterval = TimeInterval(truncating: message.timeStamp!)
        let time = NSDate(timeIntervalSince1970: TimeInterval(myTimeInterval))
        dateLabel.text = dateFormatter.string(from:time as Date )
    }
    
    
    @objc func chatClassSelected(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self, name: .ChatClassSelected, object: nil)
    }

    @IBAction func selectTheClassForTheChat() {
        self.performSegue(withIdentifier: Constants.Segues.ShowClassAlert, sender: nil)
    }
    
    func adjustTheTableView(_ makeSmaller: Bool = true) { // to show the member images
        let mainScreenHeight = self.view.screenHeight
        let navBarHeight = (self.navigationController?.navigationBar.intrinsicContentSize.height)!
            + UIApplication.shared.statusBarFrame.height
        let tabBarHeight = self.tabBarController?.tabBar.frame.height
        
        var currentY: CGFloat!
        var currentHeight: CGFloat!
        
        if makeSmaller {
            currentY = navBarHeight +  self.classMembership.frame.size.height//self.originalTableViewOriginY +  self.classMembership.frame.size.height
            currentHeight = mainScreenHeight - navBarHeight - self.classMembership.frame.size.height - self.msgBar.frame.size.height - tabBarHeight!
        } else {
            currentY = navBarHeight//self.originalTableViewOriginY
            currentHeight = mainScreenHeight - navBarHeight - self.msgBar.frame.size.height
        }
        self.theTableView.frame.origin.y = currentY
        self.theTableView.frame.size.height = currentHeight
    }
    
    // MARK: - Navigation
    
    /***
     Unwind Segues
     */
    @IBAction func cancelBackToChatViewController(_ segue: UIStoryboardSegue) {
        self.selectedClass = ""
//        self.selectedClassForChat = nil
        self.chatName.text = ""
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        self.navigationItem.rightBarButtonItem?.title = "Select A Class"
        self.classSelectionCancelled = true
        self.view.setNeedsLayout()
    }
    
    @IBAction func returnToChatViewController(_ segue: UIStoryboardSegue)
    {
        let controller = segue.source as! SelectClassAlertViewController
        self.chatName.text = controller.selectedClass! + " Class"
        self.chatClassMembers = [User]()
        self.selectedClassForChat = controller.selectedClassForChat
        self.chatClassMembers = controller.chatClassMembers
        self.classMembership.reloadData()
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        self.navigationItem.rightBarButtonItem?.title = ""
        self.classSelectionCancelled = false
        self.view.setNeedsLayout()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.Segues.ShowClassAlert {
            // clear the existing table
            self.theTableView.reloadData()
            
            let nav = segue.destination as! UINavigationController
            let controller = nav.topViewController as! SelectClassAlertViewController
            controller.classes = self.classes
        }
    }
}

extension ChatViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if selectedClassForChat == nil {
            return 0
        }
        let memberCount = self.chatClassMembers.count
        return memberCount //teacher will be displayed in last position
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height: CGFloat = 60
        let width: CGFloat = 50 //UIScreen.main.bounds.width
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.CellIdentifiers.MemberImage, for: indexPath) as! MemberCollectionCell
        
        var theName = ""
        let thisMember = self.chatClassMembers[indexPath.row]
        let (fName, _) = parseName(thisMember.name!)
        theName = fName
        if indexPath.row == self.chatClassMembers.count - 1 {
            theName += "-T"
        }
//        if dbAccess.isUserCurrentlySignedIn(thisMember.email!) {
        if thisMember.isOnline! {
            theName += "*"
        }
        cell.name.text = theName
        
        if let URL = URL(string: self.chatClassMembers[indexPath.row].profileImageUrl!),
            let data = try? Data(contentsOf: URL) {
            let image = UIImage(data: data)
            cell.imageView.image = image
        } else {
            cell.imageView.image = UIImage(named: "unknown_image")
        }
    
        cell.imageView.layer.cornerRadius = cell.imageView.frame.height/2
        cell.imageView.clipsToBounds = true
        
        return cell
    }
    
    func parseName(_ fullName: String) -> (String, String) {
        let components = fullName.components(separatedBy: " ")
        return (components.first ?? "", components.count > 1 ? components.last! :  "")
    }
    
}
