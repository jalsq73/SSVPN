//
//  RouteModel.swift
//  ShadowsocksX-NG
//
//  Created by a on 09/10/18.
//  Copyright © 2018 qiuyuzhou. All rights reserved.
//

import Cocoa

class RouteModel: NSObject, NSCoding {
    var vpsAddr: String?
    var vpsUserName: String?
    var vpsPassword: String?
    var vpsPsk: String?
    var vpsAreaCode: String?
    var vpsAreaName: String?
    var vpsConnectType: String?
    var remoteID: String?
    var encrypt: String?
    var ssPass: String?
    var port: String?
    var vip: String?
    var addTime: String?
    var supplier: String?
    var ssProtocol: String?
    var ssMix: String?
    
    override init() {
        
    }
    
    init(vpsAddr: String?, vpsUserName: String?, vpsPassword: String?, vpsPsk: String?, vpsAreaCode: String?, vpsAreaName: String?, vpsConnectType: String?, removeID: String?, encrypt: String?, ssPass: String?, port: String?, vip: String?, addTime: String?, supplier: String?, ssProtocol: String?, ssMix: String?) {
        self.vpsAddr = vpsAddr;
        self.vpsUserName = vpsUserName
        self.vpsPassword = vpsPassword
        self.vpsPsk = vpsPsk;
        self.vpsAreaCode = vpsAreaCode
        self.vpsAreaName = vpsAreaName
        self.vpsConnectType = vpsConnectType
        self.remoteID = removeID
        self.encrypt = encrypt
        self.ssPass = ssPass
        self.port = port
        self.vip = vip
        self.addTime = addTime
        self.supplier = supplier
        self.ssProtocol = ssProtocol
        self.ssMix = ssMix;
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(vpsAddr, forKey: "vps_addr")
        aCoder.encode(vpsUserName, forKey: "vps_username")
        aCoder.encode(vpsPassword, forKey: "vps_password")
        aCoder.encode(vpsPsk, forKey: "vps_psk")
        aCoder.encode(vpsAreaCode, forKey: "vps_area_code")
        aCoder.encode(vpsAreaName, forKey: "vps_area_name")
        aCoder.encode(vpsConnectType, forKey: "vps_connect_type")
        aCoder.encode(remoteID, forKey: "remote_id")
        aCoder.encode(encrypt, forKey: "encrypt")
        aCoder.encode(port, forKey: "port")
        aCoder.encode(vip, forKey: "vip")
        aCoder.encode(addTime, forKey: "add_time")
        aCoder.encode(supplier, forKey: "supplier")
        aCoder.encode(ssPass, forKey: "ss_pass")
        aCoder.encode(ssProtocol, forKey: "ss_protocol")
        aCoder.encode(ssMix, forKey: "ss_mix")
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let vps_addr: String? = aDecoder.decodeObject(forKey: "vps_addr") as? String
        let vps_username: String? = aDecoder.decodeObject(forKey: "vps_username") as? String
        let vps_password: String? = aDecoder.decodeObject(forKey: "vps_password") as? String
        let vps_psk: String? = aDecoder.decodeObject(forKey: "vps_psk") as? String
        let vps_area_code: String? = aDecoder.decodeObject(forKey: "vps_area_code") as? String
        let vps_area_name: String? = aDecoder.decodeObject(forKey: "vps_area_name") as? String
        let vps_connect_type: String? = aDecoder.decodeObject(forKey: "vps_connect_type") as? String
        let remote_id: String? = aDecoder.decodeObject(forKey: "remote_id") as? String
        let encrypt: String? = aDecoder.decodeObject(forKey: "encrypt") as? String
        let port: String? = aDecoder.decodeObject(forKey: "port") as? String
        let vip: String? = aDecoder.decodeObject(forKey: "vip") as? String
        let add_time: String? = aDecoder.decodeObject(forKey: "add_time") as? String
        let supplier: String? = aDecoder.decodeObject(forKey: "supplier") as? String
        let ss_pass: String? = aDecoder.decodeObject(forKey: "ss_pass") as? String
        let ss_mix: String? = aDecoder.decodeObject(forKey: "ss_mix") as? String
        let ss_protocol: String? = aDecoder.decodeObject(forKey: "ss_protocol") as? String
        
        self.init(vpsAddr: vps_addr, vpsUserName: vps_username, vpsPassword: vps_password, vpsPsk: vps_psk, vpsAreaCode: vps_area_code, vpsAreaName: vps_area_name, vpsConnectType: vps_connect_type, removeID: remote_id, encrypt: encrypt, ssPass: ss_pass, port: port, vip: vip, addTime: add_time, supplier: supplier, ssProtocol: ss_protocol, ssMix: ss_mix)
    }
}
