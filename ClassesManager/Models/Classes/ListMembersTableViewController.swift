//
//  ListMembersTableViewController.swift
//  ClassesManager
//
//  Created by David Brownstone on 09/04/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit
import Firebase

class ListMembersTableViewController: UITableViewController {

    var theClass: Class!
    var allRegisteredUsers = [User]()
    var users = [User]()
    var selectedMember: User!
    var chatVC = ChatViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = theClass?.name
        let doneBtn = UIBarButtonItem(title: "< Class List", style: .plain, target: self, action: #selector(self.done))
        self.navigationItem.leftBarButtonItem = doneBtn
        self.users = [User]()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.gotUsers(notification:)),
                                               name: .AllUsers,
                                               object: nil)
        dbAccess.getAllUsers()
    }
    
    func setListOfUsersNotInTheClass() {
        var remainingUsers = self.users
        for aUser in allRegisteredUsers {
            if aUser.name != theClass.teacher && !(theClass.members.contains(aUser.uid!)) {
                remainingUsers.append(aUser)
            }
        }
        self.users = remainingUsers
    }
    
    @objc func gotUsers(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self,
                                                  name: .AllUsers,
                                                  object: nil)
        allRegisteredUsers = notification.userInfo!["users"] as! [User]
        setListOfUsersNotInTheClass()
        self.tableView.reloadData()
    }
    
    @objc func done(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return theClass.members.count + 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.CellIdentifiers.Member, for: indexPath)

        // Configure the cell...
        let uid: String!
        var member: User!
        if indexPath.row > 0 {
            uid = theClass.members[indexPath.row - 1] //first name is always the class teacher
            member = getUserForId(uid)
        } else {
            for aUser in appDelegate.allTheUsers! {
                if aUser.name == theClass.teacher {
                    member = aUser
                    break
                }
            }
        }
        if member.name == appDelegate.loginName {
            cell.accessoryType = .none
//            cell.selectionStyle = .none
        }
        cell.textLabel?.text = member.name
        cell.detailTextLabel?.text = member.phoneNo
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //remove from database users
            var memberId = ""
            let cell = tableView.cellForRow(at: indexPath)
            let memberName = cell?.textLabel?.text
            for aUser in appDelegate.allTheUsers! {
                if aUser.name == memberName {
                    memberId = aUser.uid!
                    break
                }
            }
            
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.completeMemberRemoval(notification:)),
                                                   name: .ClassMemberRemoved,
                                                   object: nil)
            dbAccess.removeAMemberFromClassMembers(theClass, memberId: memberId)
        }
    }
    
    @objc func completeMemberRemoval(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self,
                                                  name: .ClassMemberRemoved,
                                                  object: nil)
        theClass = notification.userInfo!["resultantClass"] as! Class
        let indexPath = IndexPath(row: (notification.userInfo!["indexOfRemovedMember"] as! Int ) + 1, section: 0)
        tableView.deleteRows(at: [indexPath], with: .fade)
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let cell = tableView.cellForRow(at: indexPath)
//        if cell?.selectionStyle == .none {
        if cell?.textLabel?.text == appDelegate.loginName {
            // add a message here to suggest selecting somebody else
            return nil
        }
        
        SwiftActivity.show(title: "Getting Chat Messages...", animated: true)
        
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 { //selected the class teacher}
            self.selectedMember = self.getUserForId(self.theClass.teacherUid)
        } else {
            let cell = tableView.cellForRow(at: indexPath)
            let memberName = cell?.textLabel?.text
            for aMember in allRegisteredUsers {
                if aMember.name == memberName {
                    self.selectedMember = aMember
                    break
                }
            }
        }
        
        self.performSegue(withIdentifier: Constants.Segues.IndividualChat, sender: nil)
    }

    public func getUserForId(_ id: String) -> User {
        var theUser: User? = nil
        if allRegisteredUsers.count == 0 {
            allRegisteredUsers = appDelegate.allTheUsers!
        }
        for aUser in allRegisteredUsers {
            if aUser.uid == id {
                theUser = aUser
                break
            }
        }
        return theUser!
    }

    // MARK: - Navigation
    
    // MARK: Unwind Segues
    @IBAction func respondToNewMembers(_ segue: UIStoryboardSegue) {
        self.users = [User]()
        if let sourceViewController = segue.source as? AddMemberViewController {
            self.theClass = sourceViewController.thisClass
        }
    }
    
    @IBAction func returnFromChat(_ segue: UIStoryboardSegue) {
    }
    
    // MARK: Segues Out
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.Segues.AddAMember {
            let controller = segue.destination as! AddMemberViewController
            if self.users.count == 0 {
                setListOfUsersNotInTheClass()
            }
            controller.allUsers = self.users
            controller.thisClass = self.theClass
            controller.source = self
        } else if segue.identifier == Constants.CellIdentifiers.ReturnToClasses {
            let controller = segue.destination as! ClassesTableViewController
            controller.chatSubject = self.selectedMember
        } else if segue.identifier == "individualChat" {
            let navController = segue.destination as! UINavigationController
            let controller = navController.topViewController as! ChatViewController
            controller.theObjectMember = self.selectedMember
//            SwiftActivity.show(title: "Loading Class Messages...", animated: true)

        }
    }

}
