//
//  ChatViewExtensions.swift
//  ClassesManager
//
//  Created by David Brownstone on 26/06/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit
import Firebase
//import SwiftSpinner
//import SwiftActivity

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    /**
     UIImagePickerControllerDelegate method to cancel image selection
     
     - Parameter picker: the UIImagePickerController
     */
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("cancelled picker")
        dismiss(animated: true, completion: nil)
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
            self.selectedPickerImage = selectedImage
            //ToDo: need to check for an existing image before storing in db
            self.storeMessageImageInDatabase()
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func storeMessageImageInDatabase() {
        print(" storeImageViewInDatabase")
        let imagename = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child(Constants.StorageChildKeys.MessageImages).child("\(imagename).png")
        if let msgImage = self.selectedPickerImage, let uploadData = UIImageJPEGRepresentation(msgImage, 0.1) {
            storageRef.putData(uploadData, metadata: nil, completion: {(metadata,error) in
                if error != nil {
                    print(error?.localizedDescription as Any)
                    return
                }
                storageRef.downloadURL { url, error in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    let urlStr = url!.absoluteString
                    NotificationCenter.default.post(name: .NewChatMessageImage, object: nil, userInfo: ["url": urlStr])
                }
            })
        }
    }
}
