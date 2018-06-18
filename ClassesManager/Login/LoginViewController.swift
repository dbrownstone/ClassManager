//
//  LoginViewController.swift
//  
//
//  Created by David Brownstone on 02/04/2018.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    var keyboardSize:CGRect? = nil
    
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var phoneNoTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    var uid:String?
    var email: String?
    var authorized: Bool?
    var password: String?
    var name: String?
    var phone: String?
    var thisMember: User? = nil
    var profileImageUrl: String?
    var profileImageSelected = false
    var loginAgain = false
    
    var spinnerView: UIView?
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var returnToLoginBtn: UIButton!
    
    var bottomLayoutGuideConstraint: NSLayoutConstraint?
    
    var loggingIn = true
    var thereIsAnImage = false
    var currentUserId: String?
    var observing = false
    
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    
    var classesTVController: ClassesTableViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardUp), name:.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardDown), name: .UIKeyboardWillHide, object: nil)
        emailTextField?.becomeFirstResponder()
        emailTextField?.delegate = self
        passwordTextField?.delegate = self

        self.email = standardDefaults.string(forKey: Constants.StdDefaultKeys.LoggedInEmail)

        if !(self.email?.isEmpty)! {
            self.passwordTextField.becomeFirstResponder()
            NotificationCenter.default.addObserver(self, selector: #selector(self.getCurrentUser(notification:)), name: .AUser, object: nil)
            self.spinnerView = UIViewController.displaySpinner(onView: self.view)

            dbAccess.getAUser(self.email!)
        } else {
            appDelegate.loggedInId = ""
            self.emailTextField.becomeFirstResponder()
            self.profileImageView.addGestureRecognizer(tapGestureRecognizer!)
        }
    }
    
    @objc func getCurrentUser(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self, name: .AUser, object: nil)
        self.thisMember = notification.userInfo?["user"] as? User
        self.emailTextField.text = self.thisMember?.email
        let profileImageUrl = self.thisMember?.profileImageUrl
        self.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl!)
        self.currentUserId = self.thisMember?.uid
        appDelegate.loggedInId = self.currentUserId!
        appDelegate.thisMember = self.thisMember
        self.passwordTextField.text = standardDefaults.string(forKey:  Constants.StdDefaultKeys.Sisma)
        returnToLoginBtn.isHidden = false
        returnToLoginBtn.setTitle(Constants.ButtonTitles.changePasswordTitle, for: .normal)
        UIViewController.removeSpinner(spinner: self.spinnerView!)
    }
    
    func checkForKnownUserEmail(_ emailAddr : String) -> AnyObject {
        var result = "" as AnyObject
        for aUser in appDelegate.allTheUsers! {
            if aUser.email == emailAddr {
                result = aUser as AnyObject
            }
        }
        
        return result
    }
    
    func checkForImage() {
        
        var ref: DatabaseReference!
        
        self.spinnerView = UIViewController.displaySpinner(onView: self.view)
        
        ref = Database.database().reference().child(Constants.DatabaseChildKeys.Users)
        ref.observe(.value, with: { snapshot in
            self.observing = true

            
            self.email = self.emailTextField.text
            for aUser in snapshot.children {
                self.thisMember = User(snapshot: aUser as! DataSnapshot)
                self.authorized = self.thisMember?.authorized
                if self.email == self.thisMember?.email {
                    if self.authorized! {
                        self.profileImageUrl = self.thisMember?.profileImageUrl
                        self.profileImageView.loadImageUsingCacheWithUrlString(urlString: self.profileImageUrl!)
                        self.loggingIn = true
                        standardDefaults.set(self.thisMember?.uid, forKey:Constants.StdDefaultKeys.CurrentLoggedInId)
                        standardDefaults.set(self.thisMember?.email, forKey:Constants.StdDefaultKeys.LoggedInEmail)
                        standardDefaults.synchronize()
                        UIViewController.removeSpinner(spinner: self.spinnerView!)
                        appDelegate.loginName = self.thisMember?.name
                        appDelegate.thisMember = self.thisMember
                    } else {
                        self.prepareToRegister()
                    }
                    break
                }
            }
            UIViewController.removeSpinner(spinner: self.spinnerView!)
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: View Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fullNameTextField.isHidden = loggingIn
        phoneNoTextField.isHidden = loggingIn
        if !loggingIn {
            loginBtn.setTitle(Constants.ButtonTitles.registerTitle, for: .normal)
            self.profileImageView.addGestureRecognizer(tapGestureRecognizer!)
        } else {
            loginBtn.setTitle(Constants.ButtonTitles.loginTitle, for: .normal)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.loginAgain {
            self.loginAgain = false
            self.showAlert("Please enter your new password and login again.", theTitle: "Password Changed")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    
    @IBAction func selectProfileImageView(_ sender: UITapGestureRecognizer) {
        print("single tap called")
        self.spinnerView = UIViewController.displaySpinner(onView: self.view)
        
        self.handleSelectProfileImageView()
        self.thereIsAnImage = true
        UIViewController.removeSpinner(spinner: self.spinnerView!)
    }
    
    @objc func keyboardUp(notification: NSNotification) {
        if ((notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue) != nil {
            keyboardSize = ((notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue)!
            self.view.frame.origin.y = -((keyboardSize!.height) * 0.70)
        }
    }
    
    @objc func keyboardDown(notification: NSNotification) {
        if ((notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue) != nil {
            self.view.frame.origin.y = 0
        }
    }
    
    @objc func prepareToLogThisUserIn(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self, name: .AUser, object: nil)
        self.thisMember = notification.userInfo?["user"] as? User
        if (thisMember?.authorized)! {
            if (self.thisMember?.profileImageUrl?.isEmpty)! {
                self.showAlert("Please select an image first.", theTitle: "Warning")
            } else {
                self.profileImageView.loadImageUsingCacheWithUrlString(
                    urlString: (self.thisMember?.profileImageUrl)!)
            }
        } else {
            self.prepareToRegister()
        }
    }
    
    @IBAction func login(_ sender: UIButton) {
        if sender.titleLabel?.text == Constants.ButtonTitles.registerTitle {
            self.handleRegister()
        } else {
            self.handleLogin()
        }
    }
    
    func prepareToRegister() {
        self.observing = false
        self.loginBtn.setTitle(Constants.ButtonTitles.registerTitle, for: .normal)
        self.fullNameTextField.isHidden = false
        self.fullNameTextField.text = self.thisMember?.name
        self.phoneNoTextField.isHidden = false
        self.phoneNoTextField.text = self.thisMember?.phoneNo
        if (self.fullNameTextField.text?.isEmpty)! {
            self.fullNameTextField.becomeFirstResponder()
        } else {
            self.passwordTextField.becomeFirstResponder()
        }
        
        self.returnToLoginBtn.isHidden = false
        self.loggingIn = false
        self.profileImageView.isHidden = false
//        self.profileImageView.addGestureRecognizer(tapGestureRecognizer!)
        
    }
    
    @IBAction func returnToLoginScreen(_ sender: UIButton) {
        if sender.titleLabel?.text == Constants.ButtonTitles.changePasswordTitle {
            self.changePassword()
            return
        }
        self.loginBtn.setTitle(Constants.ButtonTitles.loginTitle, for: .normal)
        self.fullNameTextField.isHidden = true
        self.phoneNoTextField.isHidden = true
        self.returnToLoginBtn.isHidden = true
        self.emailTextField.text = ""
        self.emailTextField.becomeFirstResponder()
    }
    
    func changePassword() {
        print("Moving to ChangePasswordScreen")
        self.performSegue(withIdentifier: Constants.Segues.ChangePassword, sender: self)
    }
    
    // MARK: - Navigation
    
    @IBAction func logout(_ segue: UIStoryboardSegue) {
        do {
            try Auth.auth().signOut()
            self.fullNameTextField?.text = ""
            self.phoneNoTextField?.text = ""
            self.email = ""
            self.password = ""
            self.emailTextField?.text = ""
            self.emailTextField?.becomeFirstResponder()
            self.passwordTextField?.text = ""
            thereIsAnImage = false
            self.profileImageView.image = UIImage(named:"unknown_image")
            standardDefaults.set("", forKey: Constants.StdDefaultKeys.CurrentLoggedInId)
            standardDefaults.set("", forKey: Constants.StdDefaultKeys.LoggedInEmail)
            standardDefaults.synchronize()
            dbAccess.setOnlineState(false)
            dismiss(animated: true, completion: nil)
        } catch {
            print("Unable to logout")
        }
    }
    
    @IBAction func cancelChangedPassword(_ segue: UIStoryboardSegue) {
    }
    
    @IBAction func returnFromChangedPassword(_ segue: UIStoryboardSegue) {
        returnToLoginBtn.isHidden = true
        self.passwordTextField.text = ""
        self.passwordTextField.becomeFirstResponder()
        self.loginAgain = true
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.Segues.ChangePassword {
            let controller =  segue.destination as! ChangePasswordViewController
            controller.source = self
            controller.thisMember =  self.thisMember
            controller.password = self.passwordTextField?.text
        } else {
//            appDelegate.tbControl = segue.destination as! UITabBarController
        }
    }
    
}

extension LoginViewController: UITextFieldDelegate {
    // UITextFieldDelegate
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            self.profileImageView.image = UIImage(named: "unknown_image")
        }
        return true
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField.text?.isEmpty)! {
            return false
        }
        textField.resignFirstResponder()
        
        switch textField {
        case fullNameTextField:
            phoneNoTextField?.becomeFirstResponder()
            break
        case phoneNoTextField:
            emailTextField?.becomeFirstResponder()
            break
        case emailTextField:
            let response = self.checkForKnownUserEmail(emailTextField.text!)
            if response is String  { // i.e. ""
                self.prepareToRegister()
            } else {
                self.thisMember = response as? User
                if (self.thisMember?.authorized)! {
                    if !(thisMember?.profileImageUrl?.isEmpty)! {
                        self.profileImageView.loadImageUsingCacheWithUrlString(urlString: (thisMember?.profileImageUrl!)!)
                    }

//                    NotificationCenter.default.addObserver(self, selector: #selector(self.prepareToLogThisUserIn(notification:)), name: .AUser, object: nil)
//                    dbAccess.getAUser(emailTextField.text!)
                    passwordTextField?.becomeFirstResponder()
                } else {
                    self.prepareToRegister()
                }
            }
            break
        default: //passwordTextField
            passwordTextField.resignFirstResponder()
            if fullNameTextField.isHidden == false {
                self.handleRegister()
            } else {
                self.handleLogin()
            }
            break;
        }
        return true
    }

    
}


