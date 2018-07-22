//
//  BubbleTableViewCell.swift
//  ClassesManager
//
//  Created by David Brownstone on 05/07/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit
import QuartzCore

@objc protocol BubbleTableViewCellDataSource {
    
    @objc optional func minInsetForCell(cell: BubbleTableViewCell, atIndexPath indexPath: IndexPath) -> CGFloat
}

@objc protocol BubbleTableViewCellDelegate {
    @objc optional func tappedImageOfCell(cell: BubbleTableViewCell, atIndexPath indexPath: IndexPath)
}

let BubbleWidthOffset = CGFloat(30.0)
let BubbleHeightOffset = CGFloat(36.0)
let BubbleImageSize = CGFloat(50.0)
let AuthorImageSize = CGFloat(30.0)

enum AuthorType {
    case authorTypeSelf //logged in
    case authorTypeOther
}

enum MessageType {
    case textMessageType
    case imageMessageType
}

enum BubbleColor: Int {
    case bubbleColorGreen
    case bubbleColorGray
    case bubbleColorAqua
    case bubbleColorOrange
    case bubbleColorPink
    case bubbleColorPurple
    case bubbleColorRed
    case bubbleColorYellow
}

class BubbleTableViewCell: UITableViewCell {

    var bubbleColor: BubbleColor?
    var selectedBubbleColor: BubbleColor?
    var canCopyContents: Bool?
    var selectionAdjustsColor: Bool?
    var indexPath: IndexPath?
    
    var dataSource: BubbleTableViewCellDataSource?
    var delegate: BubbleTableViewCellDelegate?
    var bubbleView: UIImageView?
    var authorType: AuthorType?
    var messageType: MessageType?
    var messageImageUrl: String?
    var messageImage: UIImageView?
    var userImageUrl: String?
    var userImage: UIImageView?
    var msgTextLabel: UILabel?
    var timeStamp: String?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.messageType = .textMessageType  //default value
        self.msgTextLabel = UILabel(frame: CGRect.zero)
    }
    
    func prepare() {
        selectionStyle = .none
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bubbleView = UIImageView.init(frame: CGRect.zero)
        bubbleView?.isUserInteractionEnabled = true
        contentView.addSubview(bubbleView!)
        
        if messageType == .textMessageType {
            self.msgTextLabel?.backgroundColor = .clear
            self.msgTextLabel?.numberOfLines = 0
            self.msgTextLabel?.lineBreakMode = .byWordWrapping
            self.msgTextLabel?.textColor = .black
            self.msgTextLabel?.font.withSize(14.0)
            self.addSubview(self.msgTextLabel!)
            self.bringSubview(toFront: self.msgTextLabel!)
            self.msgTextLabel?.center = (self.bubbleView?.center)!
        } else {
            if let URL = URL(string: messageImageUrl!),
                let data = try? Data(contentsOf: URL) {
                let image = UIImage(data: data)
                
                self.messageImage = UIImageView()
                let max = (contentView.frame.size.width) * 0.55
                self.messageImage?.frame = CGRect(x: 0, y: 5, width: max, height: max/((image?.size.width)! / (image?.size.height)!))
                self.messageImage?.contentMode = .scaleAspectFit
                self.messageImage?.image = image
                self.addSubview(self.messageImage!)
                self.bringSubview(toFront: self.messageImage!)
                self.messageImage?.center = (self.bubbleView?.center)!
            }
        }
        
        if authorType == .authorTypeOther {
            if let URL = URL(string: userImageUrl!),
                let data = try? Data(contentsOf: URL) {
                let image = UIImage(data: data)
                self.userImage = UIImageView(frame: CGRect(x: 0, y: 0, width: AuthorImageSize, height: AuthorImageSize))
                self.userImage?.image = image
                self.userImage?.isUserInteractionEnabled = true
                
//                let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress))
//                bubbleView?.addGestureRecognizer(longPressRecognizer)
//                let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tap))
//                self.userImage?.addGestureRecognizer(tapRecognizer)
            }
        }
        
        // Defaults
        selectedBubbleColor = BubbleColor.bubbleColorAqua;
        canCopyContents = true;
        selectionAdjustsColor = true
    }
    
    func updateFramesForAuthorType(_ type: AuthorType) {
        if type == .authorTypeSelf {
            bubbleColor = .bubbleColorGreen;
        } else {
            bubbleColor = .bubbleColorGray;
        }
        self.setImageForBubbleColor(bubbleColor!)
//        let minInset: CGFloat = ((dataSource as AnyObject).minInsetForCell!(cell: self, atIndexPath: self.indexPath!))
        var size: CGSize?
        if (self.userImage != nil) {
            self.addSubview(self.userImage!)
            if self.messageType == .textMessageType {
                size = self.msgTextLabel?.text?.boundingRect(
                    with: CGSize(width: (self.superview?.frame.size.width)! * 0.6, height: CGFloat.greatestFiniteMagnitude),
                    options: .usesLineFragmentOrigin,
                    attributes: [.font: self.msgTextLabel?.font as Any],
                    context: nil).size
            } else {
                size = self.messageImage?.frame.size
            }
        } else {
            if self.messageType == .textMessageType {
                size = self.msgTextLabel?.text?.boundingRect(
                    with: CGSize(width: (self.superview?.frame.size.width)! * 0.6, height: CGFloat.greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                attributes: [.font: self.msgTextLabel?.font as Any],
                context: nil).size
            } else {
                size = self.messageImage?.frame.size
            }
        }
//        var theDate = UILabel(frame: CGRect.zero)
        
        if type == .authorTypeSelf { // logged in - no sender image
            self.bubbleView?.frame = CGRect(x: self.frame.size.width - ((size?.width)! + BubbleWidthOffset), y: 8.0, width: (size?.width)! + BubbleWidthOffset, height: (size?.height)! + 25.0)
            self.imageView?.frame = CGRect.zero
            if self.messageType == .textMessageType {
                self.msgTextLabel?.frame = CGRect(x: self.frame.size.width - ((size?.width)! + BubbleWidthOffset - 10.0), y: 14.0, width: (size?.width)! + BubbleWidthOffset - 23.0, height: (size?.height)!)
                self.msgTextLabel?.autoresizingMask = .flexibleLeftMargin
            } else {
                self.messageImage?.center = (self.bubbleView?.center)!
            }
            self.bubbleView?.autoresizingMask = .flexibleLeftMargin
            self.bubbleView?.transform = .identity;
            let dateWidth = ((self.bubbleView?.frame.size.width)! - 16.0) / 2
            let theDate = UILabel(frame: CGRect(
                    x: self.frame.size.width - ((self.bubbleView?.frame.size.width)! + dateWidth + 8.0),
                    y: (self.bubbleView?.frame.origin.y)! - 18.0 + (self.bubbleView?.frame.size.height)! / 2,
                    width: dateWidth,
                    height: 36
                )
            )
            theDate.font = UIFont.systemFont(ofSize: 12.0);
            theDate.font = theDate.font.italic
            theDate.text = timeStamp
            theDate.textColor = .gray
            theDate.numberOfLines = 0
            theDate.lineBreakMode = .byWordWrapping
            self.addSubview(theDate)
        } else {
            self.bubbleView?.frame = CGRect(x: 35.0, y: 8.0, width: (size?.width)! + BubbleWidthOffset, height: (size?.height)! + 30.0)
            self.userImage?.frame = CGRect(x: 5.0, y: (self.bubbleView?.frame.size.height)!, width: 30, height: 30)
            self.userImage?.layer.cornerRadius = (self.userImage?.frame.height)!/2
            self.userImage?.clipsToBounds = true
            if self.messageType == .textMessageType {
                self.msgTextLabel?.frame = CGRect(x: BubbleImageSize, y: 14.0, width: (size?.width)! + BubbleWidthOffset - 23.0, height: (size?.height)!)
                
                self.msgTextLabel?.autoresizingMask = .flexibleRightMargin;
            } else {
                self.messageImage?.center = (self.bubbleView?.center)!
            }
            self.bubbleView?.autoresizingMask = .flexibleRightMargin;
            self.bubbleView?.transform = .identity
            self.bubbleView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            let theDate = UILabel(frame: CGRect(x: (self.bubbleView?.frame.size.width)! + BubbleWidthOffset + 9.0,
                                                y: (self.bubbleView?.frame.origin.y)! - 18.0 + (self.bubbleView?.frame.size.height)! / 2,
                                                width: (self.bubbleView?.frame.size.width)! - 16.0,
                                                height: 36
                )
            )
            
            theDate.font = UIFont.systemFont(ofSize: 12.0);
            theDate.font = theDate.font.italic
            theDate.text = timeStamp
            theDate.textColor = .gray
            theDate.lineBreakMode = .byWordWrapping
            theDate.numberOfLines = 2
            self.addSubview(theDate)
        }
    }
    
    func setImageForBubbleColor(_ bubbleColor: BubbleColor) {
        let imageName = String(format:"Bubble-%lu", bubbleColor.rawValue )
        var myImage = UIImage(named: imageName)!
        let myInsets : UIEdgeInsets = UIEdgeInsetsMake(12.0, 15.0, 16.0, 18.0)
        myImage = myImage.resizableImage(withCapInsets: myInsets)
        self.bubbleView?.image = myImage
    }
    
    override func layoutSubviews() {
        self.updateFramesForAuthorType(authorType!)
    }
    
    func tableView() -> UITableView {
        let tableView: UIView = self.superview!

        if tableView.isKind(of:UITableView.self) {
            return tableView as! UITableView
        }
            
        return tableView.superview! as! UITableView
    }
    
    // MARK: - Setters
    
    func setAuthorType(type: AuthorType) {
        authorType = type;
        self.updateFramesForAuthorType(authorType!)
    }
    
    func setBubbleColor(color: BubbleColor) {
        bubbleColor = color;
        self.setImageForBubbleColor(bubbleColor!)
    }
    
    // MARK: - UIGestureRecognizer methods
    
    @objc func longPress(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            if self.canCopyContents! {
                let menuController = UIMenuController.shared
                self.becomeFirstResponder()
                menuController.setTargetRect((self.bubbleView?.frame)!, in: self)
                menuController.setMenuVisible(true, animated: true)
                if self.selectionAdjustsColor! {
                    self.setImageForBubbleColor(self.selectedBubbleColor!)
                }
                NotificationCenter.default.addObserver(self, selector: #selector(self.willHideMenuController), name: .UIMenuControllerWillHideMenu, object: nil)
            }
        }
    }
    
    @objc func tap(gestureRecognizer: UITapGestureRecognizer) {
        (delegate as AnyObject).tappedImageOfCell?(cell: self, atIndexPath: (self.tableView().indexPath(for: self))!)
    }
    
    
    // MARK: - UIMenuController methods

    func canPerformAction( selector: Selector, withSender: Any) -> Bool {
        if selector == #selector(self.copy(_:)) {
            return true
        }
        return false
    }
    
    func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    @objc func copy(sender: Any) {
        UIPasteboard.general.string = self.msgTextLabel?.text
    }
    
    @objc func willHideMenuController(notification: NSNotification) {
        self.setImageForBubbleColor(self.bubbleColor!)
        NotificationCenter.default.removeObserver(self, name: .UIMenuControllerWillHideMenu, object: nil)
    }
}
