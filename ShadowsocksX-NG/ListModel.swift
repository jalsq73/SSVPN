//
//  ListModel.swift
//  ShadowsocksX-NG
//
//  Created by a on 09/10/18.
//  Copyright © 2018 qiuyuzhou. All rights reserved.
//

import Cocoa
class ListModel: NSObject, NSCoding {
    var areaCode: String?
    var areaName: String?
    var type: String?
    var flag: String?
    
    override init() {
        
    }
    
    init(areaCode: String?, areaName: String?, type: String?, flag: String?) {
        self.areaCode = areaCode;
        self.areaName = areaName;
        self.type = type;
        self.flag = flag;
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.areaCode, forKey: "area_code")
        aCoder.encode(self.areaName, forKey: "area_name")
        aCoder.encode(self.type, forKey: "area_type")
        aCoder.encode(self.flag, forKey: "flag")
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let areaName = aDecoder.decodeObject(forKey: "area_name") as? String
        let areaCode = aDecoder.decodeObject(forKey: "area_code") as? String
        let type = aDecoder.decodeObject(forKey: "area_type") as? String
        let flag = aDecoder.decodeObject(forKey: "flag") as? String
        
        self.init(areaCode: areaCode, areaName: areaName, type: type, flag: flag);
    }
}
