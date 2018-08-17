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
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 45, height: 45)
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardUp), name:.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardDown), name: .UIKeyboardWillHide, object: nil)
        emailTextField?.becomeFirstResponder()
        emailTextField?.delegate = self
        passwordTextField?.delegate = self
        
        self.email = standardDefaults.string(forKey: Constants.StdDefaultKeys.LoggedInEmail)
        self.password = standardDefaults.string(forKey: Constants.StdDefaultKeys.Sisma)
        if (standardDefaults.bool(forKey: Constants.StdDefaultKeys.LoginMode) == false || self.email == nil || self.password == nil) {
            if email == nil || (email?.isEmpty)! {
                appDelegate.loggedInId = ""
                self.emailTextField.becomeFirstResponder()
                self.profileImageView.addGestureRecognizer(tapGestureRecognizer!)
            } else {
                self.passwordTextField.becomeFirstResponder()
                NotificationCenter.default.addObserver(self, selector: #selector(self.getCurrentUser(notification:)), name: .AUser, object: nil)
                dbAccess.getAUser(self.email!)
                return
            }
        }
        self.handleLogin()
    }
    
    @objc func getCurrentUser(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self, name: .AUser, object: nil)
        self.thisMember = notification.userInfo?["user"] as? User
        let profileImageUrl = self.thisMember?.profileImageUrl
        if let URL = URL(string: profileImageUrl!), let data = try? Data(contentsOf: URL) {
            let image = UIImage(data: data)
            self.profileImageView.image = image
            self.profileImageView.frame.origin.y = 64.0
        }
        self.currentUserId = self.thisMember?.uid
        
        self.emailTextField.text = self.thisMember?.email
        self.passwordTextField.text = standardDefaults.string(forKey:  Constants.StdDefaultKeys.Sisma)
        
        appDelegate.loggedInId = self.currentUserId!
        appDelegate.thisMember = self.thisMember
        returnToLoginBtn.isHidden = false
        returnToLoginBtn.setTitle(Constants.ButtonTitles.changePasswordTitle, for: .normal)
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
                        self.loggingIn = true
                        standardDefaults.set(self.thisMember?.uid, forKey:Constants.StdDefaultKeys.CurrentLoggedInId)
                        standardDefaults.set(self.thisMember?.email, forKey:Constants.StdDefaultKeys.LoggedInEmail)
                        standardDefaults.synchronize()
                        appDelegate.loginName = self.thisMember?.name
                        appDelegate.thisMember = self.thisMember
                    } else {
                        self.prepareToRegister()
                    }
                    break
                }
            }
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
        
        self.handleSelectProfileImageView()
        self.thereIsAnImage = true
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
            } 
        } else {
            self.prepareToRegister()
        }
    }
    
    @IBAction func login(_ sender: Any) {
        let button = sender as! UIButton
        if button.titleLabel?.text == Constants.ButtonTitles.registerTitle {
            self.handleRegister()
        }
        self.handleLogin()
    }
    
    func prepareToRegister() {
        self.observing = false
        self.loginBtn.setTitle(Constants.ButtonTitles.registerTitle, for: .normal)
        self.fullNameTextField.isHidden = false
        self.fullNameTextField.text = ""//self.thisMember?.name
        self.phoneNoTextField.isHidden = false
        self.phoneNoTextField.text = ""//self.thisMember?.phoneNo
        if (self.fullNameTextField.text?.isEmpty)! {
            self.fullNameTextField.becomeFirstResponder()
        } else {
            self.passwordTextField.becomeFirstResponder()
        }
        
        self.returnToLoginBtn.setTitle(Constants.ButtonTitles.returnToLoginTitle, for: .normal)
        self.returnToLoginBtn.isHidden = false
        self.loggingIn = false
        self.profileImageView.frame.origin.y = 0
        self.profileImageView.isHidden = false
//        self.profileImageView.addGestureRecognizer(tapGestureRecognizer!)
        
    }
    
    @IBAction func returnToLoginScreen(_ sender: UIButton) {
        self.profileImageView.frame.origin.y = 64.0
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
            self.profileImageView.frame.origin.y = 64.0
            self.passwordTextField.text = ""
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
                self.email = textField.text
                self.thisMember = response as? User
                if (self.thisMember?.authorized)! {
                    if let URL = URL(string: (thisMember?.profileImageUrl)!), let data = try? Data(contentsOf: URL) {
                        let image = UIImage(data: data)
                        self.profileImageView.image = image
                        self.profileImageView.frame.origin.y = 64.0
                    }
                    self.passwordTextField.becomeFirstResponder()
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
                self.password = textField.text
                self.handleLogin()
            }
            break;
        }
        return true
    }

    
}


