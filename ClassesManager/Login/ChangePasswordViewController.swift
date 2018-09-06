//
//  ChangePasswordViewController.swift
//  ClassesManager
//
//  Created by David Brownstone on 07/05/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit

class ChangePasswordViewController: UIViewController {

    @IBOutlet weak var originalTextField: UITextField!
    @IBOutlet weak var newTextField: UITextField!
    @IBOutlet weak var duplicateTextField: UITextField!
    
    var source: LoginViewController!
    var thisMember: User!
    var password: String!
    
    var loggedIn = false
    var errorNotification = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        handleLogin()
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func updatePassword(_ sender: AnyObject) {
        NotificationCenter.default.addObserver(self, selector: #selector(authorizeResult(notification:)), name: .AuthorizeNewPassword, object: nil)
        dbAccess.authorizeWithNewPassword(to: newTextField.text!)
    }
    
    @objc func authorizeResult(notification: NSNotification) {
        self.performSegue(withIdentifier: Constants.Segues.ReturnFromChangedPassword, sender: self)
    }
    
    /**
     logs in an already existing user and follows with ability to reset the password
     it ends by logging the current user out to allow logging in with the new password
     */
    @objc func handleLogin() {
        NotificationCenter.default.addObserver(self, selector: #selector(signInResult(notification:)), name: .SignIn, object: nil)
        dbAccess.signIn((thisMember?.email!)!, password: password)
    }
    
    @objc func signInResult(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self, name: .SignIn, object: nil)
        self.loggedIn = true
        if ((notification.userInfo!["error"] as? String)?.isEmpty)! {
            appDelegate.thisMember = thisMember
            appDelegate.loginName = thisMember?.name
//            appDelegate.loggedInId = (thisMember?.uid)!
            standardDefaults.set(thisMember?.uid, forKey: Constants.StdDefaultKeys.CurrentLoggedInId)
            standardDefaults.set(thisMember?.email, forKey: Constants.StdDefaultKeys.LoggedInEmail)
            standardDefaults.set(self.password, forKey: Constants.StdDefaultKeys.Sisma)
            standardDefaults.synchronize()
            self.originalTextField.text = self.password
            self.showAlert("Please enter a new password in both text fields" )
            self.newTextField.becomeFirstResponder()
        } else {
            self.errorNotification = (notification.userInfo!["error"] as? String)!
            self.showAlert(errorNotification, theTitle: "Error")
        }
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

extension ChangePasswordViewController: UITextFieldDelegate {

    // UITextFieldDelegate
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField.text?.isEmpty)! {
            return false
        }
        textField.resignFirstResponder()
        
        if textField == duplicateTextField && textField.text != newTextField.text {
            self.showAlert("Duplicate password does not match the new password entry", theTitle: "Mismatch Error")
            newTextField.text = ""
            duplicateTextField.text = ""
            newTextField.becomeFirstResponder()
        }
        
        return true
    }
    
    func showAlert(_ message:String, theTitle: String = "Change Password") {
        let alertController = UIAlertController(title: "Change Password", message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel) { (_) in }
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true){ }
    }
}
