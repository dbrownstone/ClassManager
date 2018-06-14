//
//  ChatViewController.swift
//  MultiTab
//
//  Created by David Brownstone on 01/04/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var newMessageSendButton: UIButton!
    @IBOutlet weak var camera: UIButton!
    @IBOutlet weak var classMembership: UICollectionView!
    
    var messages: [Message]!
    var classes: [Class]!
    var selectedClassForChat: Class!
    var chatClassMembers: [User]!
    var classTeacher: User!
    var selectedClass: String!
    var classSelectionCancelled = false
    
    var theObjectMember: User!
    
    @IBOutlet weak var chatName: UILabel!
    @IBOutlet weak var sendingTextField: UITextField!
    
    var bubbleHeight: CGFloat!
    var bubbleView: BubbleView!
    var messageTextLabel: UILabel!
    var messageToUid: String!
    
    @IBOutlet weak var theTableView: UITableView!
    @IBOutlet weak var navBar: UINavigationBar!
    
    var fromMember: User!
    var loggedInUsers: [User]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        defaultStyle()
        self.messages = [Message]()
        self.theTableView.delegate = self
        self.theTableView.dataSource = self
        self.classMembership.delegate = self as? UICollectionViewDelegate
        self.classMembership.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.title = "Chat"
        if theObjectMember != nil {
            addBackButton()
//            self.navigationItem.rightBarButtonItem = nil
            let name = theObjectMember.name
//            self.chatName.text = name!
            self.title = "Chat: \(name!)"
            self.messageToUid = theObjectMember.uid
//            dbAccess.getAllMessages(theObjectMember.uid!)
            observeMessages()
        } else if selectedClassForChat != nil {
//            self.navigationItem.rightBarButtonItem = nil
            let name = selectedClassForChat.name
//            self.chatName.text = name
            self.title = "Chat: \(name)"
            self.loggedInUsers = [User]()
//            NotificationCenter.default.addObserver(self,
//                                                   selector: #selector(self.addToLoggedInList(notification:)),
//                                                   name: .UserStateChanged,
//                                                   object: nil
//            )
//            for thisMember in self.chatClassMembers {
//                dbAccess.isUserCurrentlySignedIn(thisMember.email!)
//            }
            for aMember in appDelegate.allTheUsers! {
                if aMember.uid == selectedClassForChat.teacherUid {
                    self.classTeacher = aMember
                    self.chatClassMembers.append(self.classTeacher)
//                    dbAccess.isUserCurrentlySignedIn(aMember.email!)
                    break
                }
                
            }
            self.messageToUid = selectedClassForChat.uid
//            dbAccess.getAllMessages(selectedClassForChat.uid)
            observeMessages()
        } else if !self.classSelectionCancelled {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.classesLoaded(notification:)),
                                                   name: .AllClasses,
                                                   object: nil)
            dbAccess.getAllClasses()

        } else {
            redisplayTableViewDataSorted()
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
        self.theObjectMember = nil
        self.title = "Chat"
        self.selectedClassForChat = nil
        self.chatName.text = ""
        var indexPaths = [IndexPath]()
        if self.chatClassMembers != nil && self.chatClassMembers.count > 0 {
            for row in 0..<self.chatClassMembers.count {
                indexPaths.append(IndexPath(row: row, section: 0))
            }
            classMembership.deleteItems(at: indexPaths)
            self.chatClassMembers = [User]()
        }
        self.messages = [Message]()
        NotificationCenter.default.removeObserver(self, name: .UserStateChanged, object: nil)
        self.loggedInUsers = [User]()
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
        self.performSegue(withIdentifier: Constants.Segues.ShowClassAlert, sender: nil)
    }
    
    @IBAction func sendAMessage(_ sender: UIButton) {
        let timeStamp = NSDate().timeIntervalSince1970 as Double
        dbAccess.addAndUpdateAMessage([
            Constants.MessageFields.fromId : appDelegate.loggedInId as AnyObject,
            Constants.MessageFields.toId: self.messageToUid as AnyObject,
            Constants.MessageFields.textMessage: sendingTextField.text as AnyObject,
            Constants.MessageFields.timeStamp: timeStamp
        ])
        sendingTextField.text = ""
    }
    
    func prepareMessageBubble(_ messageText: String, incoming: Bool = false) {
        let label =  UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14)
        if incoming {
            label.textColor = .black
        } else {
            label.textColor = .white
        }
        label.text = messageText
        
        let constraintRect = CGSize(width: 0.66 * view.frame.width,
                                    height: .greatestFiniteMagnitude)
        let boundingBox = label.text?.boundingRect(with: constraintRect,
                                            options: .usesLineFragmentOrigin,
                                            attributes: [.font: label.font],
                                            context: nil)
        label.frame.size = CGSize(width: ceil((boundingBox?.width)!),
                                  height: ceil((boundingBox?.height)!))
        
        self.bubbleView = BubbleView.init(incoming)
        self.messageTextLabel = label
        
    }
    
    @IBAction func addAnImage(_ sender: UIButton) {
    }

    func shouldThisMessageBeDisplayed(_ message: Message, toId: String) -> [String: Any] {
        var url: String!
        if message.toId == toId {
            for member in appDelegate.allTheUsers! {
                if member.uid == message.fromId {
                    url = member.profileImageUrl
                    if member.uid == appDelegate.loggedInId {
                        message.isReceived = false
                    } else {
                        message.isReceived = true
                    }
                    if !self.messageShouldBeVisible(message.timeStamp!, chatMode: (self.selectedClassForChat != nil)) {
                        return ["displayTheMessage": false]
                    }
                    return ["displayTheMessage": true, "theMessage": message, "URL": url]
                }
            }
        }
        return ["displayTheMessage": false]
    }
    
    func messageShouldBeVisible(_ timeStamp:NSNumber, chatMode: Bool = true ) -> Bool {
        var theDuration:Int;
        let timeStampDate = Date(timeIntervalSince1970: timeStamp.doubleValue)
        let classChat = chatMode
        if classChat {
            theDuration = 3//standardDefaults.integer(forKey: "Class Chat Message Period")
        } else {
            theDuration = 7//standardDefaults.integer(forKey: "One-on-one Chat Message Period")
        }
        if theDuration == -1 {
            return true
        }
        let dateOfVisibility = Calendar.current.date(byAdding: .day, value: theDuration, to: timeStampDate)
        let today = NSDate()
        if today.compare(dateOfVisibility!) == ComparisonResult.orderedAscending {
            //Do what you want
            return true
        }
        return false;
    }
    
    func observeMessages() {
        Database.database().reference().child("messages").observe(.childAdded, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let message = Message(dictionary: dictionary, fromDatabase: true)
                var toId: String?
                if self.theObjectMember != nil {
                    toId = self.theObjectMember.uid
                } else {
                    toId = self.selectedClassForChat.uid
                }
                let values = self.shouldThisMessageBeDisplayed(message, toId: toId!)
                if ((values["displayTheMessage"] as! Bool) == false)  {
                    return
                }
                let theMessage = values["theMessage"] as! Message
                let url = values["URL"] as! String
                self.prepareMessageBubble(message.textMessage!, incoming: message.isReceived)
                let bubbleSize = CGSize(width: self.messageTextLabel.frame.width + 21,
                                        height: self.messageTextLabel.frame.height + 8)
                self.bubbleView.frame.size = bubbleSize
                
                let thisMessage = Message(dictionary: [
                    "bubble": self.bubbleView,
                    "bubbleSize": bubbleSize as AnyObject,
                    Constants.MessageFields.fromId : theMessage.fromId! as AnyObject,
                    Constants.MessageFields.toId : toId as AnyObject,
                    Constants.MessageFields.textMessage: theMessage.textMessage as AnyObject,
                    Constants.MessageFields.textLabel: self.messageTextLabel as UILabel,
                    Constants.MessageFields.isReceived: theMessage.isReceived as AnyObject,
                    Constants.MessageFields.imageURL: url as AnyObject,
                    "imageWidth": 30 as AnyObject,
                    "imageHeight": 30 as AnyObject,
                    Constants.MessageFields.timeStamp: theMessage.timeStamp as AnyObject
                    ])
                if self.theObjectMember != nil {
                    self.observeMemberMessage(thisMessage)
                } else {
                    self.observeGroupMessage(thisMessage)
                }
            }
        })
    }
    
    func observeGroupMessage(_ message: Message) {
        if message.toId == self.selectedClassForChat.uid {
            message.bubble = self.bubbleView
            self.messages.append(message)
            redisplayTableViewDataSorted()
        }
    }
    func sortMessagesByDate() {
        self.messages = self.messages.sorted { ($1.timeStamp as! Double) < ($0.timeStamp as! Double) }

    }
    
    func observeMemberMessage(_ message: Message) {
        if message.fromId == theObjectMember.uid ||
            message.toId == theObjectMember.uid {
            message.bubble = self.bubbleView
            self.messages.append(message)
            redisplayTableViewDataSorted()
        }
    }
    
    // MARK: UITableViewDelegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (self.messages[indexPath.row].bubble!).frame.size.height + CGFloat(38)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = Constants.CellIdentifiers.ChatMessage
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        for view in cell.contentView.subviews{
            view.removeFromSuperview()
        }
        configureCell(cell: cell, forRowAt: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let thisMessage = self.messages[indexPath.row]
        let thisBubble = thisMessage.bubble
        var position: CGRect?
        if thisMessage.isAReceivedMsg() {
            position = CGRect(x: 38, //cell.frame.size.width - ((thisBubble?.frame.size.width)! + 38),
                              y: 8,
                              width: (thisBubble?.frame.size.width)!,
                              height: (thisBubble?.frame.size.height)!)
        } else {
            position = CGRect(x:cell.frame.size.width - ((thisBubble?.frame.size.width)! + 8),
                   y: 8,
                   width: (thisBubble?.frame.size.width)!,
                   height: (thisBubble?.frame.size.height)!)
        }
        thisBubble?.frame = position!
        thisMessage.textLabel?.center = thisBubble!.center
        thisMessage.bubble?.backgroundColor = UIColor.clear
        cell.contentView.addSubview(thisMessage.bubble!)
        cell.contentView.addSubview(thisMessage.textLabel!)
        
        let imageView = UIImageView()
        if thisMessage.isReceived {
            print("fromId: \(thisMessage.fromId ?? "") - URL: \(thisMessage.imageUrl ?? "")")
            imageView.loadImageUsingCacheWithUrlString(urlString: thisMessage.imageUrl!)
            imageView.frame = CGRect(x: 8, y: thisBubble!.frame.size.height, width: 30, height: 30 )
            imageView.layer.cornerRadius = imageView.frame.height/2
            imageView.clipsToBounds = true
            cell.contentView.addSubview(imageView)
        }
        addMessageDate(cell, msg: thisMessage, bubble: thisBubble as! ChatViewController.BubbleView)
    }
    
    func addMessageDate(_ cell: UITableViewCell, msg: Message, bubble: UIView) {
        var dateLabel: UILabel!
        if msg.isAReceivedMsg() {
            dateLabel = UILabel(frame: CGRect(x: 38, y: bubble.frame.size.height + 8, width: bubble.frame.size.width, height: 21))
        } else {
            dateLabel = UILabel(frame: CGRect(x: cell.frame.size.width - (bubble.frame.size.width + 8), y: bubble.frame.size.height + 8, width: bubble.frame.size.width, height: 21))
        }
        
        dateLabel.textAlignment = .center
        dateLabel.font = UIFont(name: "TrebuchetMS-italic", size: 12)
        dateLabel.textColor = .lightGray
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E MMM d, HH:mm"
        dateFormatter.timeZone = NSTimeZone.local
        let myTimeInterval = TimeInterval(truncating: msg.timeStamp!)
        let time = NSDate(timeIntervalSince1970: TimeInterval(myTimeInterval))
        dateLabel.text = dateFormatter.string(from:time as Date )
        cell.contentView.addSubview(dateLabel)
    }
    
    @objc func chatClassSelected(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self, name: .ChatClassSelected, object: nil)
    }

    @IBAction func selectTheClassForTheChat() {
        self.performSegue(withIdentifier: Constants.Segues.ShowClassAlert, sender: nil)
    }
    
    func adjustTheTableView(_ makeSmaller: Bool = true) { // to show the member images
        var currentHeight = self.theTableView.frame.size.height
        let currentWidth = self.theTableView.frame.size.width
        var currentY = self.theTableView.frame.origin.y
        let heightSizeAdjustment = self.classMembership.frame.size.height
        if makeSmaller {
            currentY += heightSizeAdjustment
            currentHeight -= heightSizeAdjustment
        } else {
            currentY -= heightSizeAdjustment
            currentHeight += heightSizeAdjustment
        }
        self.theTableView.frame = CGRect(x: 0, y: currentY, width: currentWidth, height: currentHeight)
    }

    class BubbleView: UIView {
        
        var isIncoming = false
        
        var incomingColor = UIColor(white: 0.9, alpha: 1)
        var outgoingColor = UIColor(red: 74/255, green: 179/255, blue: 150/255, alpha: 1)
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
        init(_ incoming: Bool) {
            super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            isIncoming = incoming
        }
        
        override func draw(_ rect: CGRect) {
            let width = rect.width
            let height = rect.height
            
            let bezierPath = UIBezierPath()
            
            if isIncoming {
                bezierPath.move(to: CGPoint(x: 22, y: height))
                bezierPath.addLine(to: CGPoint(x: width - 17, y: height))
                bezierPath.addCurve(to: CGPoint(x: width, y: height - 17), controlPoint1: CGPoint(x: width - 7.61, y: height), controlPoint2: CGPoint(x: width, y: height - 7.61))
                bezierPath.addLine(to: CGPoint(x: width, y: 17))
                bezierPath.addCurve(to: CGPoint(x: width - 17, y: 0), controlPoint1: CGPoint(x: width, y: 7.61), controlPoint2: CGPoint(x: width - 7.61, y: 0))
                bezierPath.addLine(to: CGPoint(x: 21, y: 0))
                bezierPath.addCurve(to: CGPoint(x: 4, y: 17), controlPoint1: CGPoint(x: 11.61, y: 0), controlPoint2: CGPoint(x: 4, y: 7.61))
                bezierPath.addLine(to: CGPoint(x: 4, y: height - 11))
                bezierPath.addCurve(to: CGPoint(x: 0, y: height), controlPoint1: CGPoint(x: 4, y: height - 1), controlPoint2: CGPoint(x: 0, y: height))
                bezierPath.addLine(to: CGPoint(x: -0.05, y: height - 0.01))
                bezierPath.addCurve(to: CGPoint(x: 11.04, y: height - 4.04), controlPoint1: CGPoint(x: 4.07, y: height + 0.43), controlPoint2: CGPoint(x: 8.16, y: height - 1.06))
                bezierPath.addCurve(to: CGPoint(x: 22, y: height), controlPoint1: CGPoint(x: 16, y: height), controlPoint2: CGPoint(x: 19, y: height))
                
                incomingColor.setFill()
                
            } else {
                bezierPath.move(to: CGPoint(x: width - 22, y: height))
                bezierPath.addLine(to: CGPoint(x: 17, y: height))
                bezierPath.addCurve(to: CGPoint(x: 0, y: height - 17), controlPoint1: CGPoint(x: 7.61, y: height), controlPoint2: CGPoint(x: 0, y: height - 7.61))
                bezierPath.addLine(to: CGPoint(x: 0, y: 17))
                bezierPath.addCurve(to: CGPoint(x: 17, y: 0), controlPoint1: CGPoint(x: 0, y: 7.61), controlPoint2: CGPoint(x: 7.61, y: 0))
                bezierPath.addLine(to: CGPoint(x: width - 21, y: 0))
                bezierPath.addCurve(to: CGPoint(x: width - 4, y: 17), controlPoint1: CGPoint(x: width - 11.61, y: 0), controlPoint2: CGPoint(x: width - 4, y: 7.61))
                bezierPath.addLine(to: CGPoint(x: width - 4, y: height - 11))
                bezierPath.addCurve(to: CGPoint(x: width, y: height), controlPoint1: CGPoint(x: width - 4, y: height - 1), controlPoint2: CGPoint(x: width, y: height))
                bezierPath.addLine(to: CGPoint(x: width + 0.05, y: height - 0.01))
                bezierPath.addCurve(to: CGPoint(x: width - 11.04, y: height - 4.04), controlPoint1: CGPoint(x: width - 4.07, y: height + 0.43), controlPoint2: CGPoint(x: width - 8.16, y: height - 1.06))
                bezierPath.addCurve(to: CGPoint(x: width - 22, y: height), controlPoint1: CGPoint(x: width - 16, y: height), controlPoint2: CGPoint(x: width - 19, y: height))
                
                outgoingColor.setFill()
            }
            bezierPath.close()
            bezierPath.fill()
        }
    }
    
    // MARK: - Navigation
    
    /***
     Unwind Segues
     */
    @IBAction func cancelBackToChatViewController(_ segue: UIStoryboardSegue) {
        self.selectedClass = ""
        self.selectedClassForChat = nil
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
//        NotificationCenter.default.post(name: .ChatClassSelected, object: nil)
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        self.navigationItem.rightBarButtonItem?.title = ""
        self.classSelectionCancelled = false
        self.view.setNeedsLayout()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.Segues.ShowClassAlert {
            // clear the existing table
            self.messages = [Message]()
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
        
        if (self.chatClassMembers[indexPath.row].profileImageUrl?.isEmpty)! {
            cell.image.image = UIImage(named: "unknown_image")
            cell.image.layer.cornerRadius = cell.image.frame.height/2
            cell.image.clipsToBounds = true
            return cell
        }
        cell.image.loadImageUsingCacheWithUrlString(urlString: self.chatClassMembers[indexPath.row].profileImageUrl!)
        cell.image.layer.cornerRadius = cell.image.frame.height/2
        cell.image.clipsToBounds = true
        return cell
    }
    
    func parseName(_ fullName: String) -> (String, String) {
        let components = fullName.components(separatedBy: " ")
        return (components.first ?? "", components.count > 1 ? components.last! :  "")
    }
    
}
