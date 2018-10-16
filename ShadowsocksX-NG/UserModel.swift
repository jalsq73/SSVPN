//
//  UserModel.swift
//  ShadowsocksX-NG
//
//  Created by a on 09/10/18.
//  Copyright © 2018 qiuyuzhou. All rights reserved.
//

import Cocoa
@objcMembers
class UserModel: NSObject, NSCoding {
    var register_time: String?
    var token: String?
    var user_expiration_date: String?
    var user_type: String?
    var uuid: String?
    var goods_name: String?
    var qq: String?
    var password: String?
    var phone: String?
    var version: String?
    var user_name: String?
    var apple_id: String?

    override init() {
        
    }
    
    init(registerTime: String?, token: String?, userExpirationDate: String?, userType: String?, uuid: String?, goodsName: String?, qq: String?, password: String?, phone: String?, version: String?, userName: String?, appleID: String?) {
        self.register_time = registerTime
        self.token = token
        self.user_expiration_date = userExpirationDate
        self.user_type = userType
        self.uuid = uuid
        self.goods_name = goodsName
        self.qq = qq
        self.password = password
        self.phone = phone
        self.version = version
        self.user_name = userName
        self.apple_id = appleID
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.register_time, forKey: "register_time")
        aCoder.encode(self.token, forKey: "token")
        aCoder.encode(self.user_expiration_date, forKey: "user_expiration_date")
        aCoder.encode(self.user_type, forKey: "user_type")
        aCoder.encode(self.uuid, forKey: "uuid")
        aCoder.encode(self.goods_name, forKey: "goods_name")
        aCoder.encode(self.qq, forKey: "qq")
        aCoder.encode(self.password, forKey: "password")
        aCoder.encode(self.version, forKey: "version")
        aCoder.encode(self.phone, forKey: "phone")
        aCoder.encode(self.user_name, forKey: "user_name")
        aCoder.encode(self.apple_id, forKey: "apple_id")
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let registerTime = aDecoder.decodeObject(forKey: "register_time") as? String
        let token = aDecoder.decodeObject(forKey: "token") as? String
        let userExpirationDate = aDecoder.decodeObject(forKey: "user_expiration_date") as? String
        let userType = aDecoder.decodeObject(forKey: "user_type") as? String
        let uuid = aDecoder.decodeObject(forKey: "uuid") as? String
        let goodsName = aDecoder.decodeObject(forKey: "goods_name") as? String
        let qq = aDecoder.decodeObject(forKey: "qq") as? String
        let password = aDecoder.decodeObject(forKey: "password") as? String
        let version = aDecoder.decodeObject(forKey: "version") as? String
        let phone = aDecoder.decodeObject(forKey: "phone") as? String
        let userName = aDecoder.decodeObject(forKey: "user_name") as? String
        let appleID = aDecoder.decodeObject(forKey: "apple_id") as? String
        
        self.init(registerTime: registerTime, token: token, userExpirationDate: userExpirationDate, userType: userType, uuid: uuid, goodsName: goodsName, qq: qq, password: password, phone: phone, version: version, userName: userName, appleID: appleID);
    }
}
