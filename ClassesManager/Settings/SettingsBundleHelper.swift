//
//  SettingsBundleHelper.swift
//  MultiTab
//
//  Created by David Brownstone on 08/09/2018.
//

import Foundation
class SettingsBundleHelper {
    
    class func checkAndExecuteSettings() {
        if UserDefaults.standard.bool(forKey: Constants.SettingsBundleKeys.Reset) {
            UserDefaults.standard.set(false, forKey: Constants.SettingsBundleKeys.Reset)
            let appDomain: String? = Bundle.main.bundleIdentifier
            UserDefaults.standard.removePersistentDomain(forName: appDomain!)
            // reset userDefaults..
            initializeSettings()
            // CoreDataDataModel().deleteAllData()
            // delete all other user data here..
        }
    }
    
    class func setVersionAndBuildNumber() {
        let version = Bundle.main.releaseVersionNumber
        let build = Bundle.main.buildVersionNumber
        print("version \(version!) build \(build! )")
        UserDefaults.standard.set(build, forKey: Constants.StdDefaultKeys.CurrentBuild)
        UserDefaults.standard.set(version, forKey: Constants.StdDefaultKeys.CurrentVersion)
    }
    
    class func initializeSettings() {
        let appDefaults = [Constants.StdDefaultKeys.IndividualChatVisibilityPeriod: activeTimes.noLimit.rawValue, Constants.StdDefaultKeys.ClassChatVisibilityPeriod: activeTimes.noLimit.rawValue, Constants.StdDefaultKeys.LoginMode: false] as [String : Any]
        standardDefaults.register(defaults: appDefaults)
    }
    
    // debug only
    class func clearTimeSettings() {
        standardDefaults.set(nil, forKey:Constants.StdDefaultKeys.IndividualChatVisibilityPeriod)
        standardDefaults.set(nil, forKey:Constants.StdDefaultKeys.ClassChatVisibilityPeriod)
    }
}
