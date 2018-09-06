//
//  Connectivity.swift
//  Class Manager
//
//  Created by David Brownstone on 10/04/2018.
//  Copyright © 2018 Brownstone LLC. All rights reserved.
//

import Foundation
import Alamofire


class Connectivity {
  class func isConnectedToInternet() ->Bool {
    return NetworkReachabilityManager()!.isReachable
  }
}
