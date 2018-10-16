//
//  PchFile.swift
//  ShadowsocksX-NG
//
//  Created by a on 08/10/18.
//  Copyright © 2018 qiuyuzhou. All rights reserved.
//

import Foundation
class PchFile {
    static var rootURL: String {
        get {
            return UserDefaults.standard.value(forKey: "ip") as! String
        }
    };
    static let keyDecode = "LZQ1Yit8";
    static let key58 = "Please enter a new password"
    static let pushBox = "1"
}
