//
//  LoginViewController+handlers.swift
//  MultiTab
//
//  Created by David Brownstone on 03/04/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.


import UIKit
import Firebase

/**
 Handles profile image access, registering a new user and logging in an existing user
 */
extension LoginViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    /**
     creates and logs in a new user
     */
    func handleRegister() {
        print(" handleRegister")
        email = emailTextField.text
        password = passwordTextField.text
        name = self.fullNameTextField.text
        phone = self.phoneNoTextField.text
        
        if self.email!.isEmpty ||
            self.password!.isEmpty ||
            self.name!.isEmpty ||
            self.phone!.isEmpty {
            return
        }
        NotificationCenter.default.addObserver(self,selector: #selector(self.identifyThisUser(notification:)), name: .AUser, object: nil)
        dbAccess.getAUser(self.email!)
    }
    
    @objc func identifyThisUser(notification: NSNotification) {
        print(" identifyThisUser")
        NotificationCenter.default.removeObserver(self, name: .AUser, object: nil)
        if (notification.userInfo!["error"] as! String).isEmpty {
            NotificationCenter.default.addObserver(self, selector: #selector(self.performResultOfAuthorization(notification:)), name: .Authorized, object: nil)
            
            NotificationCenter.default.addObserver(forName: NSNotification.Name.AuthStateDidChange, object: Auth.auth(), queue: nil) { _ in
                let authorizedUser = Auth.auth().currentUser
                appDelegate.loggedInId = authorizedUser!.uid

                print(" \(String(describing: (authorizedUser?.email)!)) authorized.")
                
                if self.thisMember?.uid !=  appDelegate.loggedInId {//self.uid {
                    self.replaceCurrent((self.thisMember?.uid!)!, toId: appDelegate.loggedInId, authorized: true, online: true)
                    self.thisMember?.uid = authorizedUser?.uid
                    var theMembers = [User]()
                    for aMember in appDelegate.allTheUsers! {
                        if aMember.email == self.thisMember?.email {
                            theMembers.append(self.thisMember!)
                        } else {
                            theMembers.append(aMember)
                        }
                    }
                    appDelegate.allTheUsers = theMembers
                    NotificationCenter.default.post(name: .Authorized, object: self, userInfo: ["error": "", "email": (authorizedUser?.email)! as Any])
                } else {
                    NotificationCenter.default.post(name: .Authorized, object: self, userInfo: ["error": "", "email": (authorizedUser?.email)! as Any])
                }
            }
            dbAccess.authorizeThisExistingUser(with: (self.email)!, password: self.password!)
        } else {
            //display an alert telling the user to have the teacher add the user to a class first
            print("add the user to a class first")
            self.showAlert("This user should first be added to a class!", theTitle: notification.userInfo!["error"] as! String)
        }
    }
    
    @objc func performResultOfAuthorization(notification: NSNotification) {
        print(" performResultOfAuthorization.")
        NotificationCenter.default.removeObserver(self, name: .Authorized, object: nil)
        
        if !(notification.userInfo!["error"] as! String).isEmpty {
            let localizedDescr = notification.userInfo!["error"] as! String
            self.showAlert(localizedDescr, theTitle: "Password Changed")
            return
        }
        
        self.email = notification.userInfo?["email"] as? String
        prepareTheLogin(self.email!)
    }
    
    func prepareTheLogin(_ email:String) {
        for member in appDelegate.allTheUsers! {//snapshot.children {
            if member.email == self.email {
                thisMember =  member
                dbAccess.setOnlineState(true)
                if (self.thisMember?.profileImageUrl?.isEmpty)! {
                    self.handleSelectProfileImageView()
                }
                
                //               vc rf self.performSegue(withIdentifier: Constants.Segues.LoggedIn, sender: self)
                //                break
                //            }
            }
        }
    }
    
    // successfully authenticated user
    func storeImageViewInDatabase() {
        print(" storeImageViewInDatabase")
        let imagename = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child(Constants.StorageChildKeys.ProfileImages).child("\(imagename).png")
        if let profileImage = self.profileImageView.image, let uploadData = UIImageJPEGRepresentation(profileImage, 0.1) {
            storageRef.putData(uploadData, metadata: nil, completion: {(metadata,error) in
                if error != nil {
                    print(error ?? "Unable to load image into Firebase Storage")
                    self.showAlert((error?.localizedDescription)!, theTitle: "Error")
                    return
                }
                storageRef.downloadURL { url, error in
//                    self.dismiss(animated: true, completion: nil)
                    if let error = error {
                        print("Unable to get image URL from Firebase Storage")
                        self.showAlert((error.localizedDescription), theTitle: "Error")
                        return
                    } else {
                        self.profileImageUrl = url?.absoluteString
                        self.thisMember?.profileImageUrl = self.profileImageUrl
                        dbAccess.updateUserWithImageUrl(self.thisMember!, imageURL: self.profileImageUrl!)
                        self.thisMember?.isOnline = true
                        dbAccess.setOnlineState(true)

//                        if (self.thisMember?.isOnline)! {
//                        appDelegate.loggedInId = (self.thisMember?.uid!)!
                            self.performSegue(withIdentifier: Constants.Segues.LoggedIn, sender: self)
//                        }
                    }
                }
            })
        }
    }
    
    /**
     displays the system Image Picker
     */
    @objc func handleSelectProfileImageView() {
        SwiftSpinner.show("Opening your image picker...")
        print(" handleSelectProfileImageView")
        let picker = UIImagePickerController()
        
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
        SwiftSpinner.hide()
    }
    
    /**
     UIImagePickerControllerDelegate method to select the picked image
     
     - Parameter picker: the UIImagePickerController
     - Parameter: info: dictionary of image values
     */
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImageFromPicker:UIImage?
        
        if let editedImage = info[UIImagePickerControllerEditedImage] {
            selectedImageFromPicker = editedImage as? UIImage
        } else if let originalImage = info[UIImagePickerControllerOriginalImage] {
            selectedImageFromPicker = originalImage as? UIImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            profileImageView.image = selectedImage
            //ToDo: need to check for an existing image before storing in db
            self.storeImageViewInDatabase()
        }
        
        dismiss(animated: true, completion: nil)
//        self.fullNameTextField.becomeFirstResponder()
    }
    
    /**
     UIImagePickerControllerDelegate method to cancel image selection
     
     - Parameter picker: the UIImagePickerController
     */
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("cancelled picker")
        dismiss(animated: true, completion: nil)
    }
    
    /**
     logs in an already existing user and displays the matching  profile image
     */
    @objc func handleLogin() {
        print("  handleLogin")
        self.classesTVController?.navigationItem.titleView = nil
        
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            print("Invalid login parameters!")
            self.showAlert("Incomplete text fields!", theTitle: "Error")
            return
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(signInResult(notification:)), name: .SignIn, object: nil)
        dbAccess.signIn(email, password: password)
    }
    
    @objc func signInResult(notification: NSNotification) {
        print("  signInResult")
        NotificationCenter.default.removeObserver(self, name: .SignIn, object: nil)
        if ((notification.userInfo!["error"] as? String)?.isEmpty)! {
            for thisMember in appDelegate.allTheUsers! {
                if thisMember.email == emailTextField.text {
                    appDelegate.thisMember = thisMember
                    appDelegate.loginName = thisMember.name
                    appDelegate.loggedInId = (thisMember.uid)!
                    standardDefaults.set(thisMember.uid, forKey: Constants.StdDefaultKeys.CurrentLoggedInId)
                    standardDefaults.set(thisMember.email, forKey: Constants.StdDefaultKeys.LoggedInEmail)
                    standardDefaults.set(self.passwordTextField.text, forKey: Constants.StdDefaultKeys.Sisma)
                    standardDefaults.synchronize()
                    if (thisMember.profileImageUrl?.isEmpty)! {
                        self.handleSelectProfileImageView()
                        break
                    }
                    self.profileImageUrl = thisMember.profileImageUrl
                    dismiss(animated: true, completion: nil)
                    self.performSegue(withIdentifier: Constants.Segues.LoggedIn, sender: self)
                    break
                }
            }            
        } else {
            showAlert((notification.userInfo!["error"] as? String)!, theTitle: "Error")
        }
    }
    
    /**
     replaces the app-generated UDID (at the time of registering, by the Firebase-generated UDID - replaced in the members array for each class in the classes database and the user in the users database
     */
    func replaceCurrent(_ fromId: String, toId: String, authorized: Bool, online: Bool) {
        print(" replaceCurrent(id from: \(fromId) to: \(toId) ")
        let firebase = Database.database().reference()
//        appDelegate.loggedInId = toId

        firebase.child(Constants.DatabaseChildKeys.Classes).observe(.value, with: { snapshot in
            for aClass in snapshot.children {
                var theClass = Class(snapshot: aClass as! DataSnapshot)
                if theClass.members.contains(fromId) {
                    let index = theClass.members.index(of: fromId)
                    theClass.members.remove(at: index!)
                    theClass.members.insert(toId, at: index!)
                    var allUsers = [User]()
                    for aMember in appDelegate.allTheUsers! {
                        if aMember.uid == fromId {
                            aMember.uid = toId
                        }
                        aMember.isOnline = true
                        allUsers.append(aMember)
                    }
                    appDelegate.allTheUsers = allUsers
                    Database.database().reference().root
                        .child(Constants.DatabaseChildKeys.Classes)
                        .child(theClass.uid)
                        .updateChildValues([Constants.ClassFields.members: theClass.members])
                    
                }
                var member:User?
                firebase.child(Constants.DatabaseChildKeys.Users).observe(.value, with: { snapshot in
                    for aMember in snapshot.children {
                        let thisMember = User(snapshot: aMember as! DataSnapshot)
                        if thisMember.uid == fromId {
                            member = thisMember
                            member?.authorized = authorized
                            member?.isOnline = online
//                            member?.profileImageUrl = imageURL
                            appDelegate.loginName = member?.name
                            firebase.child(Constants.DatabaseChildKeys.Users)
                                .child(fromId)
                                .removeValue { (error, ref) in
                                if error != nil {
                                    print(error ?? "unable to remove uid")
                                }
                                if member != nil {
                                    firebase.child(Constants.DatabaseChildKeys.Users)
                                        .child(toId)
                                        .setValue((member!).toAnyObject())
                                }
//                                self.handleSelectProfileImageView()

                            }
                            break
                        }
                    }
                })
            }
        })
    }
    
    /**
     general alert view for error messages
     
     - Parameter message: the message string to be displayed in the alert
     */
    public func showAlert(_ message:String, theTitle: String, addButton: Bool = false) {
        let alertController = UIAlertController(title: theTitle, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel) { (_) in }
        alertController.addAction(cancelAction)
        if addButton {
            let addRegisterAction = UIAlertAction(title: "Register", style: .default, handler:  { (alert: UIAlertAction!) in
                print("Registering")
                self.prepareToRegister()
            })
           alertController.addAction(addRegisterAction)
        }
        self.present(alertController, animated: true){ }
    }
}
