//
//  LocationWindowController.swift
//  ShadowsocksX-NG
//
//  Created by a on 02/10/18.
//  Copyright © 2018 qiuyuzhou. All rights reserved.
//
import Alamofire
import Cocoa

class LocationWindowController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate {
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var bgProcessIndicator: NSView!
    @IBOutlet var actProcessIndicator: NSProgressIndicator!
    var nCounter = 0;
    var data: [ListModel] = [ListModel]();
    var userModel: UserModel?;
    
    override func windowDidLoad() {
        super.windowDidLoad()
        bgProcessIndicator.wantsLayer = true
        bgProcessIndicator.layer?.backgroundColor = NSColor.lightGray.withAlphaComponent(0.5).cgColor;
        
        //TODO: Change with the elegant style to handle prevent subview be clicked
        bgProcessIndicator.addGestureRecognizer(NSClickGestureRecognizer.init(target: self, action: #selector(actionClickGesture(_:))))
        bgProcessIndicator.addGestureRecognizer(NSPressGestureRecognizer.init(target: self, action: #selector(actionClickGesture(_:))))
        bgProcessIndicator.addGestureRecognizer(NSPanGestureRecognizer.init(target: self, action: #selector(actionClickGesture(_:))))
        
//        tableView.doubleAction = #selector(tableViewDoubleClick(_:))
        showProgressIndicator(false)
        getLocation()
    }
    
    
    //MARK: - Action
    /*@objc func tableViewDoubleClick(_ sender:AnyObject) {
        if(tableView.selectedRow >= 0) {
            tableView.isEnabled = false;
            getDetailLocation(param: data[tableView.selectedRow])
        }
    }*/
    
    
    //MARK: - Method
    func cookieData() {
        let data: Data? = UserDefaults.standard.object(forKey: "data") as? Data
        
        if(data != nil && data!.count > 0) {
            let unArchiver: NSKeyedUnarchiver = NSKeyedUnarchiver.init(forReadingWith: data!)
            self.data = (unArchiver.decodeObject(forKey: "listArray") as? [ListModel]) ?? [ListModel]()
            unArchiver.finishDecoding();
            
            tableView.reloadData()
        }
    }

    
    func showProgressIndicator(_ isStop: Bool) {
        bgProcessIndicator.isHidden = isStop;
        actProcessIndicator.isIndeterminate = true;
        actProcessIndicator.usesThreadedAnimation = true;
        actProcessIndicator.startAnimation(nil);
    }
    
    @objc func actionClickGesture(_ sender: Any) {
    }
    
    func getLocation() {
        
        guard let url = URL(string: "\(PchFile.rootURL)/area_list/GetAreaList.php") else {
            showProgressIndicator(true)
            return
        }
        
        
        Alamofire.request(url,
                          method: .post,
                          parameters: ["show_where": "SSR",
                                       "region":NSLocale.current.languageCode!])
            .validate()
            .responseData(completionHandler: { response in
                guard response.result.isSuccess else {
                    self.cookieData()
                    self.showProgressIndicator(true)

                    return
                }
                
                let str = JoDess.decode(String(data: response.result.value!, encoding: String.Encoding.utf8), key: PchFile.keyDecode);
                let json: [String:Any]? = str?.convertToDictionary();
                
                
                if (json?.count)! > 0 {
                    if(!(json?["data"] is NSNull) && json?["data"] != nil) {
//                        self.data = json?["data"] as! [[String : String]]
//                        self.data = self.data.sorted { $0["type"]! < $1["type"]!}
                        self.data = [ListModel]()
                        let tempData = json?["data"] as! [[String : String]]
                        var freeArray: [ListModel] = [ListModel]()
                        var vipArray: [ListModel] = [ListModel]()
                        
                        
                        for dic in tempData {
                            let model: ListModel = ListModel();
                            model.areaCode = dic["area_code"]
                            model.areaName = dic["area_name"]
                            model.type = dic["type"]
                            model.flag = dic["flag"]
                            
                            if(model.type != nil  &&  model.type! == "free") {
                                freeArray.append(model)
                            }
                            else {
                                vipArray.append(model);
                            }
                        }
                        
                        
                        
                        self.data.append(contentsOf: freeArray)
                        self.data.append(contentsOf: vipArray)
                        UserDefaults.standard.removeObject(forKey: "data")
                        let data: NSMutableData = NSMutableData()
                        let archivier: NSKeyedArchiver = NSKeyedArchiver(forWritingWith: data)
                        archivier.encode(self.data, forKey: "listArray")
                        archivier.finishEncoding()
                        
                        UserDefaults.standard.set(data, forKey: "data")
                        UserDefaults.standard.synchronize()
                        self.tableView.reloadData()
                        self.showProgressIndicator(true)
                    }
                    else if(json?["error_code"] != nil  &&  (json?["error_code"] as? Int) != nil  &&  (json?["error_code"] as! Int) == 0) {
                        if(self.nCounter < 3) {
                            self.nCounter += 1;
                            self.getLocation()
                        }
                        else {
                            self.showProgressIndicator(true)
                            self.tableView.reloadData()
                        }
                    }
                }
            })
    }
    
    func getDetailLocation(param : ListModel) {
        guard let url = URL(string: "\(PchFile.rootURL)/get_server/ReturnServer.php") else {
            return
        }

        let type = param.type ?? "";
        let areaCode = param.areaCode ?? "";
        
        let params: [String: Any] = ["type": type,
                                     "area_code": areaCode,
                                     "connect_type": "ssr" ,
                                     "area_diff": "SSR"]
        
        Alamofire.request(url,
                          method: .post,
                          parameters: params).validate()
            .responseData(completionHandler: { response in
                guard response.result.isSuccess else {
                    self.tableView.isEnabled = true;
                    return
                }

                let str = JoDess.decode(String(data: response.result.value!, encoding: String.Encoding.utf8), key: PchFile.keyDecode);
                let json: [String:Any]? = str?.convertToDictionary();
                
                if json != nil  &&  (json?.count)! > 0 {
                    let detailData = json?["data"] as! [String : String]
                
                    let serverProfile: ServerProfile = ServerProfile(uuid: UUID().uuidString);
                    
                    if(Locale.current.languageCode == "zh") {
                        serverProfile.remark = detailData["vps_area_name"] ?? "";
                    }
                    else {
                        serverProfile.remark = detailData["vps_area_code"] ?? "";
                    }
                    
                    serverProfile.serverHost = detailData["vps_addr"] ?? "";
                    serverProfile.password = detailData["ss_pass"] ?? ""
                    serverProfile.method = detailData["encrypt"] ?? ""
                    
                    if let port = detailData["port"], let portInt = uint16(port) {
                        serverProfile.serverPort = portInt
                    }
                    
                    if !serverProfile.isValid() {
                        self.shakeWindows()
                    }
                    else {
                        let profileMgr = ServerProfileManager.instance
                        profileMgr.profiles = [ServerProfile]();
                        profileMgr.profiles.append(serverProfile)
                        profileMgr.save()
                        NotificationCenter.default.post(name: NOTIFY_SERVER_PROFILES_CHANGED, object: nil)
                        self.window?.close()
                    }
                }
            })
    }
    
    
    func shakeWindows(){
        let numberOfShakes:Int = 8
        let durationOfShake:Float = 0.5
        let vigourOfShake:Float = 0.05
        
        let frame:CGRect = (window?.frame)!
        let shakeAnimation = CAKeyframeAnimation()
        
        let shakePath = CGMutablePath()
        shakePath.move(to: CGPoint(x:NSMinX(frame), y:NSMinY(frame)))
        
        for _ in 1...numberOfShakes{
            shakePath.addLine(to: CGPoint(x: NSMinX(frame) - frame.size.width * CGFloat(vigourOfShake), y: NSMinY(frame)))
            shakePath.addLine(to: CGPoint(x: NSMinX(frame) + frame.size.width * CGFloat(vigourOfShake), y: NSMinY(frame)))
        }
        
        shakePath.closeSubpath()
        shakeAnimation.path = shakePath
        shakeAnimation.duration = CFTimeInterval(durationOfShake)
        window?.animations = [NSAnimatablePropertyKey(rawValue: "frameOrigin"):shakeAnimation]
        window?.animator().setFrameOrigin(window!.frame.origin)
    }
    
    @objc func actionSelect(_ sender: NSButton) {
        if(userModel?.user_type != nil  &&  userModel?.user_type == "free"  &&  data[sender.tag].type == "vip") {
            let alert = NSAlert();
            alert.alertStyle = .informational;
            alert.messageText = "Upgrade VIP speed is faster and more stable, the line is unlimited traffic, and support multi-device switching.";
            alert.addButton(withTitle: "Cancel")
            alert.addButton(withTitle: "Update VIP")
            alert.beginSheetModal(for: self.window!, completionHandler: {
                (modalResponse) -> Void in
                switch modalResponse {
                    case NSApplication.ModalResponse.alertSecondButtonReturn:
                        let appDelegate: AppDelegate = NSApplication.shared.delegate as! AppDelegate;
                        appDelegate.actBuy(nil);
                    
                    default:
                        print("cancel action")
                }
            })
        }
        else {
            let model: ListModel = self.data[sender.tag];
            let appDelegate: AppDelegate = NSApplication.shared.delegate as! AppDelegate;
            appDelegate.chooseRouteInfo(model: model)

            let tempData: [String : String] = ["type":model.type!, "area_code":model.areaCode!, "area_name":model.areaName!]
            UserDefaults.standard.setValue(tempData, forKey: "lineInfo")
            let share = UserDefaults.init(suiteName: "group.com.tms.rvp")
            
            let subTempData = try? JSONSerialization.data(withJSONObject: tempData, options: JSONSerialization.WritingOptions.prettyPrinted)
            if(subTempData != nil) {
                let subStr = String(data: subTempData!, encoding: String.Encoding.utf8)
                share?.setValue(subStr, forKey: "routeInfo")
                share?.synchronize()
            }
            
            UserDefaults.standard.synchronize()
            self.getDetailLocation(param: data[sender.tag])
        }
    }
    
    
    //MARK: NSTableViewDelegate and DataSource
    func numberOfRows(in tableView: NSTableView) -> Int {
        return data.count
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        tableView.deselectRow(tableView.selectedRow)
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 40;
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var strImage: String?
        var text: String?
        var cellIdentifier: String = ""
        
        let item: ListModel = data[row];
        if(tableColumn == tableView.tableColumns[0]) {//Area Name
            if Locale.current.languageCode == "zh" {
                text = item.areaName;
            }
            else {
                text = item.areaCode;
            }
            
            
            strImage = item.flag;
            cellIdentifier = "areaName"
        }
        else if(tableColumn == tableView.tableColumns[1]) {
            text = item.type;
            strImage = nil;
            cellIdentifier = "typeID"
        }
        else {//Button
            text = nil;
            strImage = nil;
            cellIdentifier = "selectID";
        }
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = (text ?? "")!
            if let stringImage = strImage {
                do {
                    try cell.imageView?.image = NSImage(data: Data(contentsOf: URL(string: stringImage)!))
                }
                catch {
                    print("Error Load image")
                }
            }
            
            if(cellIdentifier == "selectID") {
                let btnSelect: NSButton = cell.subviews.first as! NSButton;
                btnSelect.tag = row;
                btnSelect.action = #selector(actionSelect(_:))
            }
            
            return cell
        }
        
        return nil
    }
}


