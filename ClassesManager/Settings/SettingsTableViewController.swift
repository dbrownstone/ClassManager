//
//  SettingsTableViewController.swift
//  ClassesManager
//
//  Created by David Brownstone on 10/08/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    
    @IBOutlet var activeTimeButtons: [UIButton]!
    enum activeTimes: String {
        case oneDay = "1 Day"
        case oneWeek = "1 Week"
        case twoWeeks = "2 Weeks"
        case fourWeeks = "1 Month"
        case noLimit = "No Limit"
    }
    
    enum RowHeights: Int {
        case menu_invisible = 40
        case menu_visible = 190
    }
    
    var standardRowHeight = true
    var selectedActiveTimeRow = -1
    var individualChatTimePeriod = ""
    var classChatTimePeriod = ""
    var cancelButtonPicked = false
    var menuOpened = false
    var heightForSelectedRow = 40
    var selectedRow = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Remove this line - for debug only
        SettingsBundleHelper.initializeTimeSettings()
        if standardDefaults.object(forKey: Constants.StdDefaultKeys.IndividualChatVisibilityPeriod) != nil  {
            individualChatTimePeriod = standardDefaults.string(forKey:  Constants.StdDefaultKeys.IndividualChatVisibilityPeriod)!
        }
        if standardDefaults.object(forKey: Constants.StdDefaultKeys.ClassChatVisibilityPeriod) != nil {
            classChatTimePeriod = standardDefaults.string(forKey:  Constants.StdDefaultKeys.ClassChatVisibilityPeriod)!
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func showHideTimesMenu(_ sender: CustomButton) {
        
        if heightForSelectedRow == RowHeights.menu_invisible.rawValue {
            self.selectedActiveTimeRow = (sender.indexPath?.row)!
            heightForSelectedRow = RowHeights.menu_visible.rawValue
        } else {
            self.selectedActiveTimeRow = -1
            heightForSelectedRow = RowHeights.menu_invisible.rawValue
        }
        selectedRow = (sender.indexPath?.row)!
        self.tableView.reloadRows(at: [IndexPath(row: 0, section: 1), IndexPath(row: 1, section: 1)], with: .automatic)
    }
    
    @objc func displaySelectedTimePeriod(_ sender: CustomButton) {
        let whichButton = sender.name
        let cell = self.tableView.cellForRow(at: sender.indexPath!)
        let theView = cell?.viewWithTag(11)
        let cancelBtn = cell?.viewWithTag(51) as! CustomButton
//        let stackView = cell?.viewWithTag(100) as! UIStackView
        cancelBtn.indexPath = sender.indexPath
        theView?.isHidden = false
//        stackView.isHidden = true
        let labelResult = cell?.viewWithTag(50) as! UILabel
        labelResult.text = whichButton
        if sender.indexPath?.row == 0 {
            standardDefaults.set(whichButton, forKey:Constants.StdDefaultKeys.IndividualChatVisibilityPeriod)
        } else {
            standardDefaults.set(whichButton, forKey:Constants.StdDefaultKeys.ClassChatVisibilityPeriod)
        }
        cancelBtn.isHidden = false
        cancelBtn.addTarget(self, action: #selector(self.cancelButtonPick(_:)), for: UIControlEvents.touchUpInside)
        menuOpened = !menuOpened
        heightForSelectedRow = RowHeights.menu_invisible.rawValue
        selectedRow = (sender.indexPath?.row)!
        self.tableView.reloadRows(at: [sender.indexPath!], with: .automatic)
    }
    
    @objc func cancelButtonPick(_ sender: CustomButton) {
        let cell = self.tableView.cellForRow(at: sender.indexPath!)
        let labelResult = cell?.viewWithTag(50) as! UILabel
        let theView = cell?.viewWithTag(11)
        let theStackView = cell?.viewWithTag(100) as! UIStackView
        theStackView.isHidden = false
        theView?.isHidden = false
        self.selectedActiveTimeRow = (sender.indexPath?.row)!
        cancelButtonPicked = false
        sender.isHidden = true
        heightForSelectedRow = RowHeights.menu_visible.rawValue
        selectedRow = (sender.indexPath?.row)!
        self.tableView.reloadRows(at: [sender.indexPath!], with: .none)
        self.selectedRow = -1
        labelResult.text = ""
    }
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30.0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Login Behaviour"
        }
        return "Visibility Period for messages"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        if section == 0 {
            return 1
        }
        return 2
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 && self.selectedRow == indexPath.row {
            if self.heightForSelectedRow > RowHeights.menu_invisible.rawValue {
                return CGFloat(self.heightForSelectedRow)
            }
            return CGFloat(RowHeights.menu_invisible.rawValue)
        }
        
        return CGFloat(RowHeights.menu_invisible.rawValue)
    }
    
    var oneDayBtn, sevenDayBtn, fourteenDayBtn, oneMonthBtn, unlimitedBtn: CustomButton!
    
    func setBorder(_ view: UIView) {
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.black.cgColor
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var reuseIdentifier: String!
        if indexPath.section == 0 {
            reuseIdentifier = "AutomaticLogin"
        } else {
            reuseIdentifier = "ActiveTimeMenu"
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        
        if indexPath.section == 1 {
            if heightForSelectedRow == RowHeights.menu_visible.rawValue {
                prepareThePullDownMenu(cell,indexPath: indexPath)
            } else {
                let theStackView = cell.viewWithTag(100) as! UIStackView
                theStackView.isHidden = true
            }
            if (indexPath.row == 0 && !(individualChatTimePeriod).isEmpty) || (indexPath.row == 1 && !(classChatTimePeriod.isEmpty)) {
                let theView = cell.viewWithTag(11)
                theView?.isHidden = true
                let cancelBtn = cell.viewWithTag(51) as! CustomButton
                cancelBtn.indexPath = indexPath
                cancelBtn.isHidden = false
                cancelBtn.addTarget(self, action: #selector(self.cancelButtonPick(_:)), for: UIControlEvents.touchUpInside)
                let labelResult = cell.viewWithTag(50) as! UILabel
                labelResult.text = individualChatTimePeriod
                self.selectedActiveTimeRow = indexPath.row
            } else {
                let mainBtn = cell.viewWithTag(99) as! CustomButton
                mainBtn.name = "main"
                mainBtn.indexPath = indexPath
                mainBtn.addTarget(self, action: #selector(self.showHideTimesMenu(_:)), for: UIControlEvents.touchUpInside)
                setBorder(mainBtn)
//
//                if selectedRow != indexPath.row {
//                    let theStackView = cell.viewWithTag(100) as! UIStackView
//                    theStackView.isHidden = true
//                }
                
//                let buttonView = cell.viewWithTag(100) as! UIStackView
//                setBorder(buttonView)
            }
            
            
            // Configure the cell...
            
            let titleLbl = cell.viewWithTag(10) as! UILabel
            if indexPath.row == 0 {
                titleLbl.text = "Individual"
            } else {
                titleLbl.text = "Class"
            }
        }
        return cell
    }
    
    func prepareThePullDownMenu(_ cell: UITableViewCell, indexPath: IndexPath) {
        let theStackView = cell.viewWithTag(100) as! UIStackView
        theStackView.isHidden = false
        
        oneDayBtn = cell.viewWithTag(101) as! CustomButton
        oneDayBtn.name = activeTimes.oneDay.rawValue
        oneDayBtn.indexPath = indexPath
        oneDayBtn.addTarget(self, action: #selector(self.displaySelectedTimePeriod(_:)), for: UIControlEvents.touchUpInside)
        setBorder(oneDayBtn)
        
        sevenDayBtn = cell.viewWithTag(102) as! CustomButton
        sevenDayBtn.name = activeTimes.oneWeek.rawValue
        sevenDayBtn.indexPath = indexPath
        sevenDayBtn.addTarget(self, action: #selector(self.displaySelectedTimePeriod(_:)), for: UIControlEvents.touchUpInside)
        setBorder(sevenDayBtn)
        
        fourteenDayBtn = cell.viewWithTag(103) as! CustomButton
        fourteenDayBtn.name = activeTimes.twoWeeks.rawValue
        fourteenDayBtn.indexPath = indexPath
        fourteenDayBtn.addTarget(self, action: #selector(self.displaySelectedTimePeriod(_:)), for: UIControlEvents.touchUpInside)
        setBorder(fourteenDayBtn)
        
        oneMonthBtn = cell.viewWithTag(104) as! CustomButton
        oneMonthBtn.name = activeTimes.fourWeeks.rawValue
        oneMonthBtn.indexPath = indexPath
        oneMonthBtn.addTarget(self, action: #selector(self.displaySelectedTimePeriod(_:)), for: UIControlEvents.touchUpInside)
        setBorder(oneMonthBtn)
        
        unlimitedBtn = cell.viewWithTag(105) as! CustomButton
        unlimitedBtn.name = activeTimes.noLimit.rawValue
        unlimitedBtn.indexPath = indexPath
        unlimitedBtn.addTarget(self, action: #selector(self.displaySelectedTimePeriod(_:)), for: UIControlEvents.touchUpInside)
        setBorder(unlimitedBtn)
    }
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}

class CustomButton : UIButton {
    
    var name : String = ""
    var indexPath : IndexPath? = nil
    
    //        convenience init(name: String, indexPath: IndexPath) {
    //            self.init()
    //            self.name = name
    //            self.indexPath = indexPath
    //        }
}
