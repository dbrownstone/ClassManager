//
//  AddMemberViewController.swift
//  MultiTab
//
//  Created by David Brownstone on 14/04/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit
import Firebase

class AddMemberViewController: UIViewController, UINavigationControllerDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource,
    UIGestureRecognizerDelegate {

    var thisClass: Class!
    var allUsers: [User]!
    
    @IBOutlet weak var theTableView: UITableView!
    @IBOutlet weak var registerView: UIView!
    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var fullnameText: UITextField!
    @IBOutlet weak var phoneNoText: UITextField!
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    var registering = false
    var selectedMembers = [User]()
    var source: ListMembersTableViewController!
    var tap: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = thisClass.name
        self.picker.delegate = self
        self.picker.dataSource = self
        self.registerView.isHidden = true
        
        tap = UITapGestureRecognizer(target: self, action: #selector(pickerTapped))
        tap.delegate = self
        self.picker.addGestureRecognizer(tap)
        
        self.segmentedControl.addTarget(self, action: #selector(AddMemberViewController.addRegisterMember(_:)), for: UIControlEvents.valueChanged)
        self.segmentedControl.setEnabled(false, forSegmentAt: 0)
        self.segmentedControl.setEnabled(false, forSegmentAt: 1)
        
        //remove teacher from list of users
        var teacherId: String!
        let userlist = self.allUsers
        self.allUsers = [User]()
        for aUser in userlist! {
            if aUser.uid != teacherId {
                self.allUsers.append(aUser)
            } else {
                teacherId = aUser.uid
            }
        }
        if self.allUsers.count == 0 {
            pickerView(self.picker, didSelectRow: 0, inComponent: 0)
        }
    }

    @objc func pickerTapped(tapRecognizer: UITapGestureRecognizer) {
        if tapRecognizer.state == .ended {
            let rowHeight = self.picker.rowSize(forComponent: 0).height
            let selectedRowFrame = self.picker.bounds.insetBy(dx: 0, dy: (self.picker.frame.height - rowHeight) / 2)
            let userTappedOnSelectedRow = selectedRowFrame.contains(tapRecognizer.location(in: self.picker))
            if userTappedOnSelectedRow {
                let selectedRow = self.picker.selectedRow(inComponent: 0)
                pickerView(self.picker, didSelectRow: selectedRow, inComponent: 0)
            }
        }
    }
    
    @IBAction func addRegisterMember(_ sender: Any) {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.addUser(notification:)),
                                               name: .RegisterUser,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.returnToMemberList(notification:)),
                                               name: .UserDBUpdated,
                                               object: nil)
        if (sender as! UISegmentedControl).selectedSegmentIndex == 1 {
            // create new member
            let newMember = User(name: fullnameText.text!, phoneNo: phoneNoText.text!, email: emailText.text!, profileImageUrl: "")
            newMember.uid = NSUUID().uuidString
            if thisClass.members.count == 0 {
                thisClass.members = [String]()
            }
            thisClass.members.append(newMember.uid!)
            let values = [Constants.UserFields.name : newMember.name as AnyObject,
                          Constants.UserFields.phoneNo: newMember.phoneNo as AnyObject,
                          Constants.UserFields.email : newMember.email as AnyObject,
                          Constants.UserFields.authorized : false,
                          Constants.UserFields.online : false,
                          Constants.UserFields.imageUrl: "" as AnyObject] as [String : AnyObject]
            
            dbAccess.registerUserIntoDatabaseWithUID(uid: newMember.uid!, values:values as [String : AnyObject])
        } else {
            for member in selectedMembers {
                self.thisClass.members.append(member.uid!)
            }
            dbAccess.updateClassMembersDatabase(self.thisClass)
        }
    }
    
    @objc func returnToMemberList(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self,
                                                  name: .UserDBUpdated,
                                                  object: nil)
        self.performSegue(withIdentifier: Constants.Segues.ReturnToMemberList, sender: self)
    }
    
    @objc func addUser(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self,
                                                  name: .RegisterUser,
                                                  object: nil)
        dbAccess.updateClassMembersDatabase(thisClass)
        self.performSegue(withIdentifier: Constants.Segues.ReturnToMemberList, sender: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - TextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField.text?.isEmpty)! {
            return false
        }
        textField.resignFirstResponder()
        if fullnameText.hasText && phoneNoText.hasText && emailText.hasText {
            self.segmentedControl.setEnabled(true, forSegmentAt: 1)
        }
        switch textField {
            
        case fullnameText:
            self.phoneNoText.becomeFirstResponder()
            break
        case phoneNoText:
            self.emailText.becomeFirstResponder()
            break
        default:
            break
        }
        return true
    }
    
    // MARK: - UIPicker
    
    var noOfSelections = 0
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if self.thisClass.members.count == 0 {
            pickerView.removeGestureRecognizer(tap)
        }
        return self.allUsers.count + 1
    }
    
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if row == self.allUsers.count {
            return "Register a New User"
        }
        let thisUser = self.allUsers[row]
        return thisUser.name
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // need to add check for duplication
        if row == self.allUsers.count {
//            self.segmentedControl.setEnabled(true, forSegmentAt: 1)
            self.picker.isHidden = true
            self.theTableView.isHidden = true
            self.registerView.isHidden = false
            self.registering = true
            self.fullnameText.delegate = self
            self.phoneNoText.delegate = self
            self.emailText.delegate = self
            self.fullnameText.becomeFirstResponder()
            return
        }
        self.theTableView.isHidden = false
        self.segmentedControl.setEnabled(true, forSegmentAt: 0)
        selectedMembers.append(self.allUsers[row])
        self.theTableView.reloadData()
    }
    
    // MARK: - UIGestureRecognizer
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK:- Data Source
extension AddMemberViewController:UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedMembers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.CellIdentifiers.SelectedUser, for: indexPath)
        cell.textLabel?.text = selectedMembers[indexPath.row].name
        return cell
    }    
}

// MARK:- Table View Delegate
extension AddMemberViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.selectedMembers.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
