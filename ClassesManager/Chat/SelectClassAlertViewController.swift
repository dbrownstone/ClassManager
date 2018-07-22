//
//  SelectClassAlertViewController.swift
//  MultiTab
//
//  Created by David Brownstone on 21/05/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit

class SelectClassAlertViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    var dbAccess = DatabaseAccess()

    var classes: [Class]!
    var selectedClassForChat: Class!
    var selectedClass: String!
    var allUsers: [User]!
    
    var chatClassMembers: [User]!
    
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var chatName: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.selectedClassForChat = self.classes[0]
        self.selectedClass = selectedClassForChat.name
        self.chatName.text = selectedClass
        allUsers = appDelegate.allTheUsers!
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.performSegue(withIdentifier: Constants.Segues.CancelAlertView, sender: self)
    }
    
    @IBAction func done(_ sender: Any) {
        self.chatName.text = self.selectedClass! + " Class"
        self.chatClassMembers = [User]()
        
        for id in self.selectedClassForChat.members {
            for user in self.allUsers {
                if user.uid == id {
                    self.chatClassMembers.append(user)
                    break
                }
            }
        }
        self.performSegue(withIdentifier: Constants.Segues.ReturnToChatView, sender: self)
        
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

    // MARK: PickerView
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
//        NotificationCenter.default.addObserver(self, selector: #selector(self.chatClassSelected(notification:)), name: .ChatClassSelected, object: nil)
        
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.classes.count
    }
    
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.classes[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedClassForChat = self.classes[row]
        selectedClass = selectedClassForChat.name
        self.chatName.text = selectedClass
    }
}
