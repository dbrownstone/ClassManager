////
//  ChatViewController.swift
//  MultiTab
//
//  Created by David Brownstone on 03/07/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

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
            
            self.getChatMessagesFor(selectedClassForChat.uid)
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
    @IBOutlet weak var changeClassButton: UIBarButtonItem!
    
    var mainScreenHeight: CGFloat!
    var navBarHeight: CGFloat!
    var tabBarHeight: CGFloat!
    
    var originalTableViewHeight: CGFloat!
    var originalTableViewWidth: CGFloat!
    var originalTableViewOriginY: CGFloat!
    
    var fromMember: User!
    var loggedInUsers: [User]!
    var allAvailableMessages = [Message]()
    var msgCount = 0
    var mostRecentMsgTimeStamp: NSNumber?
    
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        defaultStyle()
        self.theTableView.delegate = self
        self.theTableView.dataSource = self
        self.classMembership.delegate = self as? UICollectionViewDelegate
        self.classMembership.dataSource = self
        
        mainScreenHeight = self.view.screenHeight
        navBarHeight = UIApplication.shared.statusBarFrame.height +
            self.navigationController!.navigationBar.frame.height
        tabBarHeight = self.tabBarController?.tabBar.frame.height
        
        self.originalTableViewOriginY = UIApplication.shared.statusBarFrame.size.height +
            (self.navigationController?.navigationBar.frame.height ?? 0.0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardUp), name:.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardDown), name: .UIKeyboardWillHide, object: nil)
        self.msgCount = appDelegate.msgCount
        self.allAvailableMessages = appDelegate.allAvailableMessages
        if self.allAvailableMessages.count > 0 {
            self.allAvailableMessages.sort(by: {(message1, message2) -> Bool in
                return (message1.timeStamp?.intValue)! > (message2.timeStamp?.intValue)!
            })
            self.mostRecentMsgTimeStamp = (self.allAvailableMessages[0]).timeStamp
        } else {
            self.mostRecentMsgTimeStamp = 0
        }
    }
    
//    @IBAction func cancelKeyboard(_ sender: Any) {
//        sendingTextField.resignFirstResponder()
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if dontShowClassAlert {
            if theObjectMember == nil && self.selectedClassForChat == nil {
                redisplayTableViewDataSorted()
                dontShowClassAlert = false
            }
            return
        }
        self.title = "Chat"
        if theObjectMember != nil {
            addBackButton()
            let name = theObjectMember.name
            self.title = "Chat: \(name!)"
            self.navigationItem.rightBarButtonItem?.isEnabled = false
            self.messageToUid = theObjectMember.uid
            self.groupChat = false
            getChatMessagesFor(theObjectMember.uid!)
            observeNewMessagesFor(theObjectMember.uid!)
        } else if selectedClassForChat != nil {
            let name = selectedClassForChat.name
            self.messageToUid = selectedClassForChat.uid
            self.title = "Chat: \(name)"
            groupChat = true
            self.loggedInUsers = [User]()
            addTheTeacherToTheListOfMembers()
            navigationItem.rightBarButtonItem?.isEnabled = true
        } else if !self.classSelectionCancelled {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.classesLoaded(notification:)),
                                                   name: .AllClasses,
                                                   object: nil)
            dbAccess.getAllClasses()
        }
        redisplayTableViewDataSorted()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.adjustTheTableView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .UserStateChanged, object: nil)
    }
    
    func addBackButton() {
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(named: "back"), for: .normal)
        backButton.addTarget(self, action: #selector(self.backAction(_:)), for: .touchUpInside)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        self.performSegue(withIdentifier: Constants.Segues.ReturnFromChat, sender: nil)
    }
    
    func defaultStyle() {
        newMessageSendButton.tintColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
        reloadInputViews()
    }

    // MARK: - View Class Chat
    
    // adds the teacher to the selected class member list
    func addTheTeacherToTheListOfMembers() {
        for aMember in appDelegate.allTheUsers! {
            if aMember.uid == selectedClassForChat.teacherUid {
                self.classTeacher = aMember
                self.chatClassMembers.append(self.classTeacher)
                break
            }
        }
    }
    func selectedData(_ theData: [String: Any]) {
        if self.chatMessages.count > 0 {
            self.clearAllTheViews()
        }
        self.chatName.text = "\(theData["title"]!) Class"
        self.selectedClassForChat = theData["selectedClass"] as! Class
        self.selectedClass = self.selectedClassForChat.name
        self.messageToUid = self.selectedClassForChat.uid
        SwiftActivity.show(title: "Loading \(self.selectedClass!) Messages...", animated: true)
        self.chatClassMembers = theData["Class Members"] as! [User]

        addTheTeacherToTheListOfMembers()

        observeNewMessagesFor(self.selectedClassForChat.uid)
        
        self.classMembership.reloadData()
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        self.classSelectionCancelled = false
    }
    
    @objc func changeSelectedClass(notification: NSNotification) {
        self.performSegue(withIdentifier: Constants.Segues.ShowClassAlert, sender: nil)
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
    
    // MARK: - Handling table view
    
    
    func redisplayTableViewDataSorted() {
        sortMessagesByDate()
        self.theTableView.reloadData()
    }

    public func clearTableView() {
        let numberOfRows = theTableView.numberOfRows(inSection: 0)
        var indexPathArray = [IndexPath]()
        for index in 0..<numberOfRows {
            let indexPath = IndexPath(item: index, section: 0)
            indexPathArray.append(indexPath)
        }
        self.chatMessages = [Message]()
        theTableView.deleteRows(at: indexPathArray, with: .fade)
    }
    
    func clearAllTheViews() {
        clearTableView()
        
        // clear membershipView
        var indexPathArray = [IndexPath]()
        for i in 0..<self.chatClassMembers.count {
            let indexPath = IndexPath(item: i, section: 0)
            if indexPath.row < self.classMembership.numberOfItems(inSection: indexPath.section) {
                indexPathArray.append(indexPath)
            }
        }
        self.chatClassMembers = [User]()
        self.classMembership.deleteItems(at: indexPathArray)
    }
    
    func adjustTheTableView() { // to show the member images
        
        var currentY: CGFloat!
        var currentHeight: CGFloat!
        
        if self.selectedClassForChat != nil {
            currentY = self.navBarHeight +  self.classMembership.frame.size.height
            currentHeight = self.mainScreenHeight - self.navBarHeight - self.classMembership.frame.size.height - self.msgBar.frame.size.height - tabBarHeight!
        } else {
            currentY = navBarHeight
            currentHeight = mainScreenHeight - navBarHeight - self.msgBar.frame.size.height
        }
        self.theTableView.frame.origin.y = currentY
        self.theTableView.frame.size.height = currentHeight
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
            image = message.pictureImage
            if (image?.size.width)! < max {
                max = (image?.size.width)!
            }
        }
        var size = CGSize(width: max, height: max)
        var finalSize: CGFloat!
        
        if message.authorType == .authorTypeSelf {
            if message.messageType == .textMessageType {
                size = (message.textMessage?.boundingRect(
                    with: CGSize(width: tableView.frame.size.width * 0.55,
                                 height: CGFloat.greatestFiniteMagnitude),
                    options: .usesLineFragmentOrigin,
                    attributes: [.font: UIFont.systemFont(ofSize: 14.0)],
                    context:nil).size)!
                finalSize = size.height + AuthorImageSize + BubbleHeightOffset
            } else { //message.messageType = .imageMessageType
                let imageHeight = size.width * (image.size.height / image.size.width)
                finalSize = imageHeight + AuthorImageSize + BubbleHeightOffset
            }
        } else { //authorType = .authorTypeOther
            if message.messageType == .textMessageType {
                size = (message.textMessage?.boundingRect(
                    with: CGSize(width: tableView.frame.size.width * 0.55,
                                 height: CGFloat.greatestFiniteMagnitude),
                    options: .usesLineFragmentOrigin,
                    attributes: [.font: UIFont.systemFont(ofSize: 14.0)],
                    context:nil).size)!
                finalSize = size.height + AuthorImageSize + BubbleHeightOffset
            } else { //message.messageType = .imageMessageType
                let imageHeight = size.width * (image.size.height / image.size.width)
                finalSize = imageHeight + AuthorImageSize + BubbleHeightOffset
            }
        }
        return finalSize
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == chatMessages.count - 1 {
            SwiftActivity.hide()
        }
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
            cell.messageImage = thisMessage.pictureImage
        }
        
        if thisMessage.authorType == .authorTypeOther {
            cell.userImageUrl = thisMessage.imageUrl //theObjectMember.profileImageUrl
        } else {
            cell.userImageUrl = ""
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E MMM d, HH:mm"
        dateFormatter.timeZone = NSTimeZone.local
        let myTimeInterval = TimeInterval(truncating: thisMessage.timeStamp!)
        let time = NSDate(timeIntervalSince1970: TimeInterval(myTimeInterval))
        cell.timeStamp = dateFormatter.string(from:time as Date )
        
        cell.prepare()

        cells.append(cell)
        
        if indexPath.row == chatMessages.count - 1 {
            SwiftActivity.hide()
        }
        return cell
    }
    
    func configureSentMsgCell(cell: UITableViewCell, message: Message) {
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

    @IBAction func selectClassForTheChat(_ sender: Any) {
        self.performSegue(withIdentifier: Constants.Segues.ShowClassAlert, sender: nil)
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
        self.classSelectionCancelled = true
        self.view.setNeedsLayout()
    }
    
    @IBAction func returnToChatViewController(_ segue: UIStoryboardSegue)
    {
        let controller = segue.source as! SelectClassAlertViewController
        self.msgCount = controller.messageCountHold
        self.chatName.text = controller.selectedClass! + " Class"
        self.chatClassMembers = [User]()
        self.selectedClassForChat = controller.selectedClassForChat
        self.chatClassMembers = controller.chatClassMembers
        self.classMembership.reloadData()
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        self.classSelectionCancelled = false
//        self.view.setNeedsLayout()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.Segues.ShowClassAlert {
            // clear the existing table
//            self.theTableView.reloadData()
            self.dontShowClassAlert = true
            let nav = segue.destination as! UINavigationController
            let controller = nav.topViewController as! SelectClassAlertViewController
            controller.classes = self.classes
            controller.messageCountHold = self.msgCount
            controller.sourceController = self
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
        cell.imageView.layer.borderWidth = 3
        cell.imageView.layer.borderColor = UIColor.white.cgColor
        
        return cell
    }
    
    func parseName(_ fullName: String) -> (String, String) {
        let components = fullName.components(separatedBy: " ")
        return (components.first ?? "", components.count > 1 ? components.last! :  "")
    }
    
}
