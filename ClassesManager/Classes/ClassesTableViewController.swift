//
//  ClassesTableViewController.swift
//  MultiTab
//
//  Created by David Brownstone on 01/04/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit
import Firebase

class ClassesTableViewController: UITableViewController,
                                    UITabBarControllerDelegate {
    
    var countOfClasses = 0
    var existingClasses = [Class]()
    var classes = [Class]()
    var chatSubject: User!
    var heightForSelectedRow = 60
    var selectedRow = -1
    var rowHeights = [Int]()
    
    @IBOutlet weak var showHideBtn: CustomButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = appDelegate.loginName
        self.tabBarItem.title = "Classes"
        self.tabBarController?.delegate = self
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let tabBarIndex = tabBarController.selectedIndex
        if tabBarIndex == 1 {
            let chatViewController = (viewController as! UINavigationController).topViewController as! ChatViewController
            let visibleMessages = chatViewController.chatMessages
            if visibleMessages.count > 0 {
                let msgToBeChecked = visibleMessages[visibleMessages.count - 1]
                if !chatViewController.messageShouldBeVisible(timeStamp: msgToBeChecked.timeStamp!) {
                    chatViewController.clearTableView()
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.classesLoaded(notification:)),
                                                   name: .AllClasses,
                                                   object: nil)
        dbAccess.getAllClasses()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.chatSubject != nil {
            let chatVC = ChatViewController()
//            let chatNav = self.tabBarController?.selectedViewController as! UINavigationController
//            let chat = chatNav.topViewController as! ChatViewController
            chatVC.theObjectMember = self.chatSubject
            self.chatSubject = nil // allows returning back to this view
            self.tabBarController?.selectedIndex = 1
        }
    }
    
    @objc func classesLoaded(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self,
                                                  name: .AllClasses,
                                                  object: nil)
        existingClasses = (notification.userInfo!["classes"] as? [Class])!
        classes = [Class]()
        // display only the classes of which this user is a member
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
        if self.classes.count == 0  {
            self.performSegue(withIdentifier: Constants.Segues.AddAClass, sender: self)
        } else {
            for _ in classes {
                rowHeights.append(60)
            }
            self.tableView.reloadData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func showAllOrPart(_ sender: CustomButton) {
        if rowHeights[(sender.indexPath?.row)!] == 60 {
           sender.name = "All"
            rowHeights[(sender.indexPath?.row)!] = 120
        } else {
            sender.name = "Limited"
            rowHeights[(sender.indexPath?.row)!] = 60
        }
        self.tableView.reloadRows(at: [sender.indexPath!], with: .none)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if classes.count == 0 { return 1 }
        return classes.count + 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == classes.count {
            return 44
        }
        
        return CGFloat(rowHeights[indexPath.row])
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        
        if indexPath.row == classes.count {
            cell = tableView.dequeueReusableCell(withIdentifier: Constants.CellIdentifiers.addMessage, for: indexPath)
            return cell
        }
        
        // Configure the cell...
        cell = tableView.dequeueReusableCell(withIdentifier: Constants.CellIdentifiers.addClass, for: indexPath)
        configureThisCell(cell, row: indexPath.row)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //remove class by teacher only
            let selectedClass = classes[indexPath.row]
            if selectedClass.teacherUid == appDelegate.loggedInId {
                showApprovalRequestAlert(selectedClass, indexPath: indexPath)
            } else {
                let alertController = UIAlertController(title: "Class Not Removed", message: "Class may only be removed  by the class teacher!", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel) { (_) in }
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true){ }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < classes.count {
            self.performSegue(withIdentifier: Constants.Segues.ListAllMembers, sender: classes[indexPath.row])
        } else {
            self.performSegue(withIdentifier: Constants.Segues.AddAClass, sender: self)
        }
    }
    
    func configureThisCell(_ cell: UITableViewCell, row: NSInteger) {
        let theBtn = cell.viewWithTag(15) as! CustomButton
        if theBtn.name.count == 0 {
            theBtn.name = "Limited"
        }
        theBtn.indexPath = IndexPath(row: row, section: 0)
        let textLabel = cell.viewWithTag(10) as! UILabel
        textLabel.text = classes[row].name
        let textLabel2 = cell.viewWithTag(11) as! UILabel
        textLabel2.text = classes[row].location
        let textLabel3 = cell.viewWithTag(12) as! UILabel
        textLabel3.text = ""
        let textLabel4 = cell.viewWithTag(13) as! UILabel
        textLabel4.text = ""
        let textLabel5 = cell.viewWithTag(14) as! UILabel
        textLabel5.text = ""
        if rowHeights[row] == 120 {
            textLabel4.text = "Members: \(classes[row].members.count + 1)"
            textLabel3.text = classes[row].dayAndTime
            if classes[row].teacherUid != appDelegate.loggedInId {
                textLabel5.text = classes[row].teacher
            }
        }
    }
    
    func showApprovalRequestAlert(_ selectedClass: Class, indexPath: IndexPath) {
        let message = "Are you sure you want to delete the \(selectedClass.name) Class from the database?"
        let alertController = UIAlertController(title: "Delete This Class", message: message, preferredStyle: .alert)
        let approvedAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { (_) in
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.completeClassRemoval(notification:)),
                                                   name: .ClassRemoved,
                                                   object: nil)
            dbAccess.deleteAClass(selectedClass, index: indexPath.row)
        }
        alertController.addAction(approvedAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { (_) in }
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true){ }
    }
    
    @objc func completeClassRemoval(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self,
                                                  name: .ClassRemoved,
                                                  object: nil)
        let indexPath = IndexPath(row: notification.userInfo!["indexOfClass"] as! Int, section: 0)
        classes.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
    }
        
    
    // MARK: - UITabBarControllerDelegate
    
    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool {
        return true
    }
    
    // MARK: - Navigation
    /***
        Unwind Segues
    */
    @IBAction func cancelToClassesViewController(_ segue: UIStoryboardSegue) {
        
        if segue.source is ListMembersTableViewController {
            let theSendingController = segue.source as! ListMembersTableViewController
            self.chatSubject = theSendingController.selectedMember
        }
    }
    
    @IBAction func addToClassesViewController(_ segue: UIStoryboardSegue) {
        var addClassesVC: AddClassesViewController!
        
        if segue.source is AddNewClassViewController {
            addClassesVC = segue.source as! AddClassesViewController
            classes += addClassesVC.existingClassesToAdd
        }
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.Segues.ListAllMembers {
            let navcontroller = segue.destination as! UINavigationController
            let controller = navcontroller.topViewController as! ListMembersTableViewController
            controller.theClass = sender as! Class
        } else if segue.identifier == Constants.Segues.AddAClass {
            let addClassesVC = segue.destination as! AddClassesViewController
            for aClass in classes {
                var index = 0
                for addClass in self.existingClasses {
                    if addClass.name == aClass.name {
                        // we wand to select only classes that are not included in the current list
                        self.existingClasses.remove(at: index)
                        continue
                    }
                    index += 1
                }
            }
            addClassesVC.existingClasses = self.existingClasses
        }
    }
    
}

