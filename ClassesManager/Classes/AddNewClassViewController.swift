//
//  AddNewClassViewController.swift
//  MultiTab
//
//  Created by David Brownstone on 09/04/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit
import Firebase

class AddNewClassViewController: UITableViewController, UIToolbarDelegate {
    
    @IBOutlet weak var nameOfTeacher: UILabel!
    var teacherUid: String!
    @IBOutlet weak var className: UITextField!
    @IBOutlet weak var classCity: UITextField!
    @IBOutlet weak var doneBtn: UIBarButtonItem!
    
    var newClasses = [Class]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        nameOfTeacher.text = appDelegate.loginName
        teacherUid = appDelegate.loggedInId
        className.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func add(_ sender: Any) {
        let thisNewClass = Class(name: className.text!, location: classCity.text!, teacher: nameOfTeacher.text!, teacherUid: self.teacherUid, thisMember: "")
        newClasses.append(thisNewClass)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.done(notification:)),
                                               name: .ClassDBUpdated,
                                               object: nil)
//        let dbAccess = DatabaseAccess()
        dbAccess.addAClassToTheClassDatabase(thisNewClass)
    }
    
    @objc func done(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self,
                                                  name: .ClassDBUpdated,
                                                  object: nil)
        self.dismiss(animated: true, completion: nil)
    }
}

