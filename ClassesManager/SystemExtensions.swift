//
//  SystemExtensions.swift
//  MultTab
//
//  Created by David Brownstone on 3/04/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit

extension UIView {
    
    /** This is the function to get subViews of a view of a particular type
     */
    func subViews<T : UIView>(type : T.Type) -> [T]{
        var all = [T]()
        for view in self.subviews {
            if let aView = view as? T{
                all.append(aView)
            }
        }
        return all
    }
    
    
    /** This is a function to get subViews of a particular type from view recursively. It would look recursively in all subviews and return back the subviews of the type T */
    func allSubViewsOf<T : UIView>(type : T.Type) -> [T]{
        var all = [T]()
        func getSubview(view: UIView) {
            if let aView = view as? T{
                all.append(aView)
            }
            guard view.subviews.count>0 else { return }
            view.subviews.forEach{ getSubview(view: $0) }
        }
        getSubview(view: self)
        return all
    }
}

extension UIColor {
    
    /**
     allows a color request without the addition of division by 255
     */
    convenience init(r: CGFloat, g: CGFloat, b:CGFloat, a:CGFloat) {
        self.init(red: r/255, green: g/255, blue: b/255, alpha: a)
    }
    
    static var themeGreenColor: UIColor {
        return UIColor(r:0, g:104, b:181, a: 1)
    }
    
    static var themeRedColor: UIColor {
        return UIColor(r: 197, g: 51, b: 42, a: 0.25)
    }
    
    static var themeBubbleGreenColor: UIColor {
        return UIColor(r:184, g:246, b:148, a: 1)
    }
    
    static var themeBubbleBlueColor: UIColor {
        return UIColor(r: 50, g: 150, b: 252, a: 1)
    }
}

let imageCache = NSCache<AnyObject, AnyObject>()

extension UIImageView {
    
    /**
     loads an image from cache if it already exists there
     - Parameter urlString: Firebase URL for this image
     */
    func loadImageUsingCacheWithUrlString(urlString: String, memberImage: Bool = true) {
        
        self.image = nil
        // first check cache for image
        if let cachedImage = imageCache.object(forKey: urlString as AnyObject) {
            self.image = cachedImage as? UIImage
            if  memberImage {
                NotificationCenter.default.post(name: .LoadImage, object: self)
            } else {
                NotificationCenter.default.post(name: .LoadMessageImage, object: self)
            }
            return
        }
        let url = NSURL(string:urlString)
        let urlRequest = URLRequest(url: url! as URL)
        URLSession.shared.dataTask(with: urlRequest as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                print(error ?? "incorrect URL request" )
                return
            }
            DispatchQueue.main.sync {
                
                if let downloadedImage = UIImage(data: data!) {
                    imageCache.setObject(downloadedImage, forKey: urlString as AnyObject)
                    self.image = downloadedImage
                    if  memberImage {
                        NotificationCenter.default.post(name: .LoadImage, object: self, userInfo: ["image": downloadedImage as Any, "URL": urlString as Any])
                    } else {
                        NotificationCenter.default.post(name: .LoadMessageImage, object: self, userInfo: ["image": downloadedImage as Any, "URL": urlString as Any])
                    }
                } else {
                    print("downloadedImage = nil")
                }
            }
        }).resume()
    }
}

extension UIFont {
    var bold: UIFont {
        return with(traits: .traitBold)
    } // bold
    
    var italic: UIFont {
        return with(traits: .traitItalic)
    } // italic
    
    var boldItalic: UIFont {
        return with(traits: [.traitBold, .traitItalic])
    } // boldItalic
    
    
    func with(traits: UIFontDescriptorSymbolicTraits) -> UIFont {
        guard let descriptor = self.fontDescriptor.withSymbolicTraits(traits) else {
            return self
        } // guard
        
        return UIFont(descriptor: descriptor, size: 0)
    } // with(traits:)
} // extension

extension UIViewController {
    class func displaySpinner(onView : UIView) -> UIView {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(activityIndicatorStyle: .whiteLarge)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
        return spinnerView
    }
    
    class func removeSpinner(spinner :UIView) {
        DispatchQueue.main.async {
            spinner.removeFromSuperview()
        }
    }
}

extension UIFont {
    func sizeOfString (string: String, constrainedToWidth width: Double) -> CGSize {
        return NSString(string: string).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: self], context: nil).size
    }
}

extension Notification.Name {
    static let Authorized = Notification.Name(rawValue: "Authorized")
    static let SignIn = Notification.Name(rawValue: "SignIn")
    static let ClassDBUpdated = Notification.Name(
        rawValue: "ClassDBUpdated")
    static let UserDBUpdated = Notification.Name(
        rawValue: "UserDBUpdated")
    static let RegisterUser = Notification.Name(
        rawValue: "RegisterUser")
    static let AuthorizeNewPassword = Notification.Name(
        rawValue: "authorizeNewPassword")
    static let AUser = Notification.Name(
        rawValue: "AUser")
    static let AllUsers = Notification.Name(
        rawValue: "AllUsers")
    static let AllClasses = Notification.Name(
        rawValue: "AllClasses")
    static let AllMessages = Notification.Name(
        rawValue: "AllMessages")
    static let NewMessage = Notification.Name(
        rawValue: "NewMessage")
    static let MsgDBUpdated = Notification.Name(
        rawValue: "MsgDBUpdated")
    static let ChatClassSelected = Notification.Name(
        rawValue: "ChatClassSelected")
    static let UserStateChanged = Notification.Name(
        rawValue: "UserStateChanged")
    static let ClassMemberRemoved = Notification.Name(
        rawValue: "ClassMemberRemoved")
    static let ClassRemoved = Notification.Name(
        rawValue: "ClassRemoved")
    static let LoadImage = Notification.Name(
        rawValue: "LoadImage")
    static let LoadMessageImage = Notification.Name(
        rawValue: "LoadMessageImage")
    static let NewChatMessageImage = Notification.Name(
        rawValue: "NewChatMessageImage")
    static let ResetTableView = Notification.Name(
        rawValue: "ResetTableView")
}
