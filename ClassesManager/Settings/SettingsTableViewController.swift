//
//  SettingsTableViewController.swift
//  ClassesManager
//
//  Created by David Brownstone on 10/08/2018.
//  Copyright © 2018 David Brownstone. All rights reserved.
//

import UIKit

enum activeTimes: String {
    case oneDay = "1 Day"
    case oneWeek = "1 Week"
    case twoWeeks = "2 Weeks"
    case fourWeeks = "1 Month"
    case noLimit = "No Limit"
}

class SettingsTableViewController: UITableViewController {
    
    @IBOutlet var activeTimeButtons: [UIButton]!
    @IBOutlet weak var splashImagesView: UIView!
    @IBOutlet weak var splashStack: UIStackView!
    
    var loginMode: UISwitch!
    
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
    var changingLaunchScreen = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Remove this line - for debug only
//        SettingsBundleHelper.initializeTimeSettings()
        if standardDefaults.object(forKey: Constants.StdDefaultKeys.IndividualChatVisibilityPeriod) != nil  {
            individualChatTimePeriod = standardDefaults.string(forKey:  Constants.StdDefaultKeys.IndividualChatVisibilityPeriod)!
        }
        if standardDefaults.object(forKey: Constants.StdDefaultKeys.ClassChatVisibilityPeriod) != nil {
            classChatTimePeriod = standardDefaults.string(forKey:  Constants.StdDefaultKeys.ClassChatVisibilityPeriod)!
        }
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
    
    @IBAction func setTheLoginMode(_ sender: UISwitch) {
        standardDefaults.set(sender.isOn, forKey: Constants.StdDefaultKeys.LoginMode)
    }
    
    @objc func displaySelectedTimePeriod(_ sender: CustomButton) {
        let whichButton = sender.name
        let cell = self.tableView.cellForRow(at: sender.indexPath!)
        let theView = cell?.viewWithTag(11) // contains all the menu in a stack view
        let cancelBtn = cell?.viewWithTag(51) as! CustomButton
        cancelBtn.indexPath = sender.indexPath
        theView?.isHidden = true
        let labelResult = cell?.viewWithTag(50) as! UILabel
        labelResult.text = whichButton
        if sender.indexPath?.row == 0 {
            standardDefaults.set(whichButton, forKey:Constants.StdDefaultKeys.IndividualChatVisibilityPeriod)
            individualChatTimePeriod = whichButton
        } else {
            standardDefaults.set(whichButton, forKey:Constants.StdDefaultKeys.ClassChatVisibilityPeriod)
            classChatTimePeriod = whichButton
        }
        cancelBtn.isHidden = false
        cancelBtn.addTarget(self, action: #selector(self.cancelButtonPick(_:)), for: UIControlEvents.touchUpInside)
        menuOpened = !menuOpened
        heightForSelectedRow = RowHeights.menu_invisible.rawValue
        selectedRow = (sender.indexPath?.row)!
        self.tableView.reloadRows(at: [IndexPath(row: 0, section: 1), IndexPath(row: 1, section: 1)], with: .automatic)
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
        if selectedRow == 0 {
            individualChatTimePeriod = ""
        } else {
            classChatTimePeriod = ""
        }
        labelResult.text = ""
        self.tableView.reloadRows(at: [IndexPath(row: 0, section: 1), IndexPath(row: 1, section: 1)], with: .none)
        self.selectedRow = -1
    }
    
    var stack: UIStackView!
    @objc func changeLaunchScreen(_ sender: UIButton) {
        self.stack = sender.superview?.viewWithTag(10) as! UIStackView
        self.stack.isHidden = false
        self.stack.spacing = 0
        let classTypes = Array(appDelegate.availableLaunchScreens.keys)
        print("Class Types: \(classTypes)")
        for index in 0...classTypes.count {
            DispatchQueue.main.async(execute: {
                let btn = UIButton(frame: CGRect(x: 0, y: 24*index, width: Int(self.stack.frame.size.width), height: 24))
                btn.backgroundColor = .clear
                btn.layer.cornerRadius = 5
                btn.layer.borderWidth = 1
                btn.layer.borderColor = UIColor.black.cgColor
                btn.addTarget(self, action: #selector(self.acceptTheImageChoice(_ :)), for: .touchUpInside)
                if index < classTypes.count {
                    btn.setTitle(classTypes[index], for: UIControlState.normal)
                    btn.setTitleColor(UIColor.black, for: .normal)
                    btn.setTitleColor(.red, for: .highlighted)
                } else {
                    btn.setTitle("Add New Image", for: UIControlState.normal)
                    btn.setTitleColor(UIColor.lightGray, for: .normal)
                    btn.setTitleColor(.red, for: .highlighted)
                }
                btn.titleLabel?.textAlignment = .center
                self.stack.addSubview(btn)
            })
        }
        
        self.stack.frame.size.height = CGFloat(classTypes.count * 24)
        self.changingLaunchScreen = true
        self.tableView.reloadData()
    }
    
    @objc func acceptTheImageChoice(_ sender: UIButton) {
        let selectedImageTitle = sender.titleLabel?.text
        var dict: Dictionary<String, String> = Dictionary<String, String>()
        if selectedImageTitle != "Add New Image" {
            dict[selectedImageTitle!] = appDelegate.availableLaunchScreens[selectedImageTitle!]
            appDelegate.useThisScreen = dict
            standardDefaults.set(dict, forKey: Constants.StdDefaultKeys.LaunchScreen)
            
            appDelegate.useThisScreen = dict 
                let thisScreen = Array(dict.keys).first
                if let URL = URL(string: dict[thisScreen!]!), let data = try? Data(contentsOf: URL) {
                    appDelegate.splashScreenImage = UIImage(data: data)!
                }
            
            self.changingLaunchScreen = false
            self.stack.isHidden = true
            self.tableView.reloadData()
        } else {
            
        }
        
    }
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30.0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title = ""
        switch section {
        case 1:
            title = "Visibility Period for messages"
            break
        case 2:
            title = "Change The Launch Screen"
            break
        default:
            title = "Login Behaviour"
            break
        }
        
        return title
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var noOfRows = 0
        switch section {
            case 1:
                noOfRows = 2
                break
            default:
                noOfRows = 1
                break
        }
        return noOfRows
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 && self.selectedRow == indexPath.row {
            if self.heightForSelectedRow > RowHeights.menu_invisible.rawValue {
                return CGFloat(self.heightForSelectedRow)
            }
            return CGFloat(RowHeights.menu_invisible.rawValue)
        } else if indexPath.section == 2 && self.changingLaunchScreen {
            return CGFloat(40 + (appDelegate.availableLaunchScreens.count + 1) * 24)
        }
        
        return CGFloat(RowHeights.menu_invisible.rawValue)
    }
    
    var oneDayBtn, sevenDayBtn, fourteenDayBtn, oneMonthBtn, unlimitedBtn: CustomButton!
    
    func setBorder(_ view: UIView) {
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.black.cgColor
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var reuseIdentifier = ""
        switch indexPath.section {
            case 1:
            reuseIdentifier = "ActiveTimeMenu"
            break
            case 2:
            reuseIdentifier = "ChangeLaunchScreen"
            default:
            reuseIdentifier = "AutomaticLogin"
            break
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        var theView = cell.viewWithTag(11)

        switch indexPath.section {
        case  1:
            if (indexPath.row == 0 && !(individualChatTimePeriod).isEmpty) || (indexPath.row == 1 && !(classChatTimePeriod.isEmpty)) {
                theView = cell.viewWithTag(11)
                theView?.isHidden = true
                let cancelBtn = cell.viewWithTag(51) as! CustomButton
                cancelBtn.indexPath = indexPath
                cancelBtn.isHidden = false
                cancelBtn.addTarget(self, action: #selector(self.cancelButtonPick(_:)), for: UIControlEvents.touchUpInside)
                let labelResult = cell.viewWithTag(50) as! UILabel
                if indexPath.row == 0 {
                    labelResult.text = individualChatTimePeriod
                } else {
                    labelResult.text = classChatTimePeriod
                }
                self.selectedActiveTimeRow = indexPath.row
            } else {
                let mainBtn = cell.viewWithTag(99) as! CustomButton
                mainBtn.indexPath = indexPath
                mainBtn.addTarget(self, action: #selector(self.showHideTimesMenu(_:)), for: UIControlEvents.touchUpInside)
                setBorder(mainBtn)
                if heightForSelectedRow == RowHeights.menu_visible.rawValue {
                    theView?.isHidden = false
                    prepareThePullDownMenu(cell,indexPath: indexPath)
                } else {
                    let theStackView = cell.viewWithTag(100) as! UIStackView
                    theStackView.isHidden = true
                }
                
            }
            let titleLbl = cell.viewWithTag(10) as! UILabel
            if indexPath.row == 0 {
                titleLbl.text = "Individual"
            } else {
                titleLbl.text = "Class"
            }
            break
        case 2:
            let button = cell.viewWithTag(500) as! UIButton
            button.addTarget(self,
                             action: #selector(SettingsTableViewController.changeLaunchScreen(_ :)),
                             for: .touchUpInside)
            break
        case 0:
            self.loginMode = cell.viewWithTag(80) as! UISwitch
            
            if standardDefaults.object(forKey: Constants.StdDefaultKeys.LoginMode) != nil {
                loginMode.setOn(standardDefaults.bool(forKey: Constants.StdDefaultKeys.LoginMode), animated: true)
            } else {
                loginMode.setOn(false, animated: true)
            }
            break
        default:
            break
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
