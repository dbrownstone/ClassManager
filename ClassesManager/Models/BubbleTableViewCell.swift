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
    var messageImage: UIImage?
    var messageImageView: UIImageView?
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
        for v in contentView.subviews {
            v.removeFromSuperview()
        }
        
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
            contentView.addSubview(self.msgTextLabel!)
            contentView.bringSubview(toFront: self.msgTextLabel!)
            self.msgTextLabel?.center = (self.bubbleView?.center)!
        } else {
            self.messageImageView = UIImageView()
            let max = (contentView.frame.size.width) * 0.55
            self.messageImageView?.image = self.messageImage
            self.messageImageView?.frame = CGRect(x: 0, y: 5, width: max, height: max/((messageImage?.size.width)! / (messageImage?.size.height)!))
            self.messageImageView?.contentMode = .scaleAspectFit
            contentView.addSubview(self.messageImageView!)
            contentView.bringSubview(toFront: self.messageImageView!)
            self.messageImageView?.center = (self.bubbleView?.center)!
        }
        
        if authorType == .authorTypeOther {
            if let URL = URL(string: userImageUrl!),
                let data = try? Data(contentsOf: URL) {
                let image = UIImage(data: data)
                self.userImage = UIImageView(frame: CGRect(x: 0, y: 0, width: AuthorImageSize, height: AuthorImageSize))
                self.userImage?.image = image
                self.userImage?.isUserInteractionEnabled = true
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
        var size: CGSize?
        if (self.userImage != nil && type == .authorTypeOther) {
            contentView.addSubview(self.userImage!)
            if self.messageType == .textMessageType {
                size = self.msgTextLabel?.text?.boundingRect(
                    with: CGSize(width: (self.superview?.frame.size.width)! * 0.6, height: CGFloat.greatestFiniteMagnitude),
                    options: .usesLineFragmentOrigin,
                    attributes: [.font: self.msgTextLabel?.font as Any],
                    context: nil).size
            } else {
                size = self.messageImageView?.frame.size
            }
        } else {
            if self.messageType == .textMessageType {
                size = self.msgTextLabel?.text?.boundingRect(
                    with: CGSize(width: (self.superview?.frame.size.width)! * 0.6, height: CGFloat.greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                attributes: [.font: self.msgTextLabel?.font as Any],
                context: nil).size
            } else {
                size = self.messageImageView?.frame.size
            }
        }
        
        if type == .authorTypeSelf { // logged in - no sender image
            self.bubbleView?.frame = CGRect(x: self.frame.size.width - ((size?.width)! + BubbleWidthOffset), y: 8.0, width: (size?.width)! + BubbleWidthOffset, height: (size?.height)! + 25.0)
            self.imageView?.frame = CGRect.zero
            if self.messageType == .textMessageType {
                self.msgTextLabel?.frame = CGRect(x: self.frame.size.width - ((size?.width)! + BubbleWidthOffset - 10.0), y: 14.0, width: (size?.width)! + BubbleWidthOffset - 23.0, height: (size?.height)!)
                self.msgTextLabel?.autoresizingMask = .flexibleLeftMargin
            } else {
                self.messageImageView?.center = (self.bubbleView?.center)!
            }
            self.bubbleView?.autoresizingMask = .flexibleLeftMargin
            self.bubbleView?.transform = .identity;
            let dateWidth = (self.bubbleView?.frame.size.width)!
            let theDate = UILabel(frame: CGRect(
                x: (self.bubbleView?.frame.origin.x)!,
                    y: (self.bubbleView?.frame.origin.y)! + (self.bubbleView?.frame.size.height)!,
                    width: dateWidth,
                    height: 21
                )
            )
            theDate.font = UIFont.systemFont(ofSize: 12.0);
            theDate.font = theDate.font.italic
            theDate.text = timeStamp
            theDate.textColor = .gray
            theDate.textAlignment = .center
            theDate.numberOfLines = 0
            theDate.lineBreakMode = .byWordWrapping
            contentView.addSubview(theDate)
        } else {
            self.bubbleView?.frame = CGRect(x: 35.0, y: 8.0, width: (size?.width)! + BubbleWidthOffset, height: (size?.height)! + AuthorImageSize)
            self.userImage?.frame = CGRect(x: 5.0, y: (self.bubbleView?.frame.size.height)!, width: AuthorImageSize, height: AuthorImageSize)
            self.userImage?.layer.cornerRadius = (self.userImage?.frame.height)!/2
            self.userImage?.clipsToBounds = true
            if self.messageType == .textMessageType {
                self.msgTextLabel?.frame = CGRect(x: BubbleImageSize, y: 14.0, width: (size?.width)! + BubbleWidthOffset - 23.0, height: (size?.height)!)
                
                self.msgTextLabel?.autoresizingMask = .flexibleRightMargin;
            } else {
                self.messageImageView?.center = (self.bubbleView?.center)!
            }
            self.bubbleView?.autoresizingMask = .flexibleRightMargin;
            self.bubbleView?.transform = .identity
            self.bubbleView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            let theDate = UILabel(frame: CGRect(x: (self.bubbleView?.frame.origin.x)!,
                                                y: (self.bubbleView?.frame.origin.y)! + (self.bubbleView?.frame.size.height)!,
                                                width: (self.bubbleView?.frame.size.width)!,
                                                height: 21
                )
            )
            theDate.font = UIFont.systemFont(ofSize: 12.0);
            theDate.font = theDate.font.italic
            theDate.text = timeStamp
            theDate.textColor = .gray
            theDate.textAlignment = .center
            theDate.lineBreakMode = .byWordWrapping
            theDate.numberOfLines = 2
            contentView.addSubview(theDate)
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
