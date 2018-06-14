//
//  AddClassesViewController.swift
//  MultiTab
//
//  Created by David Brownstone on 09/04/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit

class AddClassesViewController: UIViewController,
    UIToolbarDelegate,
    UIPickerViewDelegate, UIPickerViewDataSource,
    UIGestureRecognizerDelegate  {
    
    var existingClassesToAdd = [Class]()
    var existingClasses: [Class]!
    var tap: UITapGestureRecognizer!
    
    @IBOutlet weak var addNewClass: UIView!
    @IBOutlet weak var classPicker: UIPickerView!
    @IBOutlet weak var theTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tap = UITapGestureRecognizer(target: self,
                                     action: #selector(pickerTapped))
        tap.delegate = self
        self.classPicker.addGestureRecognizer(tap)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func pickerTapped(tapRecognizer: UITapGestureRecognizer) {
        if tapRecognizer.state == .ended {
            let rowHeight = self.classPicker.rowSize(forComponent: 0).height
            let selectedRowFrame = self.classPicker.bounds.insetBy(dx: 0, dy: (self.classPicker.frame.height - rowHeight) / 2)
            let userTappedOnSelectedRow = selectedRowFrame.contains(tapRecognizer.location(in: self.classPicker))
            if userTappedOnSelectedRow {
                let selectedRow = self.classPicker.selectedRow(inComponent: 0)
                pickerView(self.classPicker, didSelectRow: selectedRow, inComponent: 0)
            }
        }
    }
    
    @IBAction func add(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func returnBack(notification: NSNotification) {
//        if notification.userInfo
        NotificationCenter.default.removeObserver(self,
                                                  name: .UserDBUpdated,
                                                  object: nil)
    }
    
    // MARK: - UIPickerDelegate
    
    func numberOfComponents(in: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.existingClasses.count + 1
    }
    
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row == self.existingClasses.count {
            return "Create a New Class"
        }
        return self.existingClasses[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row == self.existingClasses.count {
            self.performSegue(withIdentifier: Constants.Segues.AddANewClass, sender: nil)
            return
        }
        self.theTableView.isHidden = false
        var theClass = self.existingClasses[row]
        theClass.addAMember(id: appDelegate.loggedInId)
        existingClassesToAdd.append(theClass)
        self.theTableView.reloadData()
    }
    
    // MARK: - UIGestureRecognizer
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: - Navigation

    @IBAction func cancelToAddClassesViewController(_ segue: UIStoryboardSegue) {
    }
    
    @IBAction func includeInAddClassesViewController(_ segue: UIStoryboardSegue) {
    }
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        let addNewVC = segue.destinationViewController as! AddNewClassViewController
    }

}

// MARK:- Data Source
extension AddClassesViewController:UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return existingClassesToAdd.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "selectedClass", for: indexPath)
        
        cell.textLabel?.text = existingClassesToAdd[indexPath.row].name
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.returnBack(notification:)),
                                               name: .UserDBUpdated,
                                               object: nil)
        
        dbAccess.updateClassMembersDatabase(existingClassesToAdd[indexPath.row])
        
        return cell
    }
}

// MARK:- Table View Delegate
extension AddClassesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            var thisClass = existingClassesToAdd[indexPath.row]
            self.existingClassesToAdd.remove(at: indexPath.row)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.returnBack(notification:)),
                                                   name: .UserDBUpdated,
                                                   object: nil)
            let index = thisClass.indexOf(appDelegate.loggedInId)
            thisClass.members.remove(at: index)
            tableView.deleteRows(at: [indexPath], with: .fade)

            dbAccess.updateClassMembersDatabase(thisClass)
        }
    }
}
