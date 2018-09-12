//
//  SettingsViewController.swift
//  MultiTab
//
//  Created by David Brownstone on 01/04/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    enum activeTimes: String {
        case oneDay = "1"
        case oneWeek = "7"
        case twoWeeks = "14"
        case fourWeeks = "28"
        case noLimit = "-1"
    }
    
    @IBOutlet weak var theTableView: UITableView!
    @IBOutlet weak var individualActiveTimeSelected: UILabel!
    @IBOutlet weak var classActiveTimeSelected: UILabel!
    @IBOutlet var activeTimeButtons: [UIButton]!
    
    @IBOutlet weak var indivSelectBtn: UIButton!
    @IBOutlet weak var indivStackView: UIStackView!
    @IBOutlet weak var classSelectBtn: UIButton!
    @IBOutlet weak var classStackView: UIStackView!
    
    var standardRowHeight: CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.theTableView.delegate = self
        self.theTableView.dataSource = self
//        self.theTableView.rowHeight = UITableViewAutomaticDimension
//        self.theTableView.estimatedRowHeight = 40
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func handleSelection(_ sender: UIButton) {
        if sender == indivSelectBtn {
            indivStackView.isHidden = false
        } else {
            classStackView.isHidden = false
        }
//        self.theTableView.estimatedRowHeight = 160
        theTableView.reloadData()
//        activeTimeButtons.forEach { (button) in
//            UIView.animate(withDuration: 0.3, animations: {
//                button.isHidden = !button.isHidden
//                self.view.layoutIfNeeded()
//            })
//        }
    }
    
//    @IBAction func activeTimeButtonTapped(_ sender: UIButton) {
//        guard let title = sender.currentTitle, let theTime = activeTimes(rawValue: title) else {
//            return
//        }
//
//        switch theTime {
//        case .oneDay:
//            print("One Day")
//        case .oneWeek:
//            print("One Week")
//        case .twoWeeks:
//            print("Two Weeks")
//        case .fourWeeks:
//            print("Four Weeks")
//        default:
//            print("No Limit")
//        }
//
//    }
    
}
