//
//  AppDelegate.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/5.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//
import Alamofire
import Cocoa
import Carbon
import RxCocoa
import RxSwift
import Network

enum LoginStatus {
    case Bind, ShowQR, Login;
    
    func getRawValue() -> Int {
        switch self {
        case .Bind:
            return 1;
        case .ShowQR:
            return 2;
        default:
            return 3;
        }
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {
    var blogConnect: Bool = false
    var isConnect: Bool = false
    var i: Int = 0;
    
    var loginWinCtrl: LoginWindowController!;
    var changePasswordWinCtrl: ChangePasswordWindowController!;
    var bindPhoneOrEmailWinCtrl: BindPhoneOrEmailWindowController!;
    var changePhoneNumberWinCtrl: ChangePhoneNumberWindowController!
    var purchaseHistoryWinCtrl: PurchaseHistoryWindowController!
    var buyWinCtrl: BuysWindowController!;
    var qrcodeWinCtrl: SWBQRCodeWindowController!
    var toastWindowCtrl: ToastWindowController!
    var locationWindowCtrl: LocationWindowController!
    var newPhoneOrEmailWindowCtrl: NewPhoneOrEmailWindowController!;
    var showQRCodeWindowCtrl: ShowQRCodeWindowController!;
    
    var lineModel: ListModel?;
    var userModel: UserModel?
    var allRouteArray: [[RouteModel]] = [[RouteModel]]()

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var menuItemBindOrBarcode: NSMenuItem!
    @IBOutlet weak var runningStatusMenuItem: NSMenuItem!
    @IBOutlet weak var toggleRunningMenuItem: NSMenuItem!
    @IBOutlet weak var menuItemSmartMode: NSMenuItem!
    @IBOutlet weak var serverMenuItem: NSMenuItem!
    @IBOutlet weak var serversMenuItem: NSMenuItem!
    @IBOutlet var showQRCodeMenuItem: NSMenuItem!
    @IBOutlet var scanQRCodeMenuItem: NSMenuItem!
    @IBOutlet var serverProfilesBeginSeparatorMenuItem: NSMenuItem!
    @IBOutlet var serverProfilesEndSeparatorMenuItem: NSMenuItem!
    @IBOutlet weak var copyHttpProxyExportCmdLineMenuItem: NSMenuItem!
    @IBOutlet weak var lanchAtLoginMenuItem: NSMenuItem!
    @IBOutlet weak var menuItemStatus: NSMenuItem!
    @IBOutlet weak var menuItemChangePassword: NSMenuItem!
    @IBOutlet weak var menuItemPuchaseHistory: NSMenuItem!
    @IBOutlet weak var menuItemVipSecurityCenter: NSMenuItem!
    

    @IBOutlet weak var hudWindow: NSPanel!
    @IBOutlet weak var panelView: NSView!
    @IBOutlet weak var isNameTextField: NSTextField!

    let kProfileMenuItemIndexBase = 100

    var statusItem: NSStatusItem!
    static let StatusItemIconWidth: CGFloat = NSStatusItem.variableLength
    
    func ensureLaunchAgentsDirOwner () {
        let dirPath = NSHomeDirectory() + "/Library/LaunchAgents"
        let fileMgr = FileManager.default
        if fileMgr.fileExists(atPath: dirPath) {
            do {
                let attrs = try fileMgr.attributesOfItem(atPath: dirPath)
                if attrs[FileAttributeKey.ownerAccountName] as! String != NSUserName() {
                    //try fileMgr.setAttributes([FileAttributeKey.ownerAccountName: NSUserName()], ofItemAtPath: dirPath)
                    let bashFilePath = Bundle.main.path(forResource: "fix_dir_owner.sh", ofType: nil)!
                    let script = "do shell script \"bash \\\"\(bashFilePath)\\\" \(NSUserName()) \" with administrator privileges"
                    if let appleScript = NSAppleScript(source: script) {
                        var err: NSDictionary? = nil
                        appleScript.executeAndReturnError(&err)
                    }
                }
            }
            catch {
                NSLog("Error when ensure the owner of $HOME/Library/LaunchAgents, \(error.localizedDescription)")
            }
        }
    }
    
    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }
    
    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        UserDefaults.standard.set(token, forKey: "deviceTokenStr")
        UserDefaults.standard.synchronize()
        
        if UUIDHelper.getUUID() != nil  &&  UUIDHelper.getUUID()!.count > 0 {
            let dict = ["uuid":UUIDHelper.getUUID()!, "bundle_id":Bundle.main.bundleIdentifier!.replacingOccurrences(of: ".mac", with: ""), "token":token, "env":PchFile.pushBox] as [String:Any]
            
            registerAPNs(dict: dict)
        }
    }
    
    func accreditLogin(dict: [String: Any]) {
        let strUrlPay = "\(PchFile.rootURL)/push_info/push_info.php";
        Alamofire.request(URL(string: strUrlPay)!,
                          method: .post,
                          parameters: dict)
            .validate()
            .responseData(completionHandler: { response in
                
            })
    }
    
    func userloginCount(uuid: String, vipUUID: String) {
        guard let url = URL(string: "\(PchFile.rootURL)/user_login/Login.php") else {
            return
        }
        
        let deviceToken = (UserDefaults.standard.value(forKey: "deviceTokenStr") as? String) ?? ""
        let dict = ["uuid":UUIDHelper.getUUID(), "bundle_id":Bundle.main.bundleIdentifier!.replacingOccurrences(of: ".mac", with: ""), "vip_uuid":vipUUID, "env":PchFile.pushBox, "free_token":deviceToken, "user_name":""] as [String:Any]
        
        Alamofire.request(url,
                          method: .post,
                          parameters: dict)
            .validate()
            .responseData(completionHandler: { response in
                let appDelegate: AppDelegate = NSApplication.shared.delegate as! AppDelegate
                guard response.result.isSuccess else {
                    return
                }
                
                let str = JoDess.decode(String(data: response.result.value!, encoding: String.Encoding.utf8), key: PchFile.keyDecode);
                let json: [String:Any]? = str?.convertToDictionary();
                let share = UserDefaults(suiteName: "group.com.tms.rvpn")
                share?.set(str, forKey: "userInfo")
                share?.synchronize()
                
                if(json != nil  &&  json!["error_code"] != nil  &&  (json!["error_code"] as! Int) == 0) {
                    appDelegate.makeToast("Login Successful")
                    
                    if(json!["data"] != nil) {
                        let data = json!["data"] as? [String:Any]
                        
                        appDelegate.userModel?.phone = data!["phone"] as? String
                        appDelegate.userModel?.uuid = data!["vip_uuid"] as? String
                        appDelegate.userModel?.user_expiration_date = data!["user_expiration_date"] as? String
                        appDelegate.userModel?.version = data!["version"] as? String
                        appDelegate.userModel?.token = data!["token"] as? String
                        appDelegate.userModel?.goods_name = data!["goods_name"] as? String
                        appDelegate.userModel?.user_type = "vip"
                        
                        KeyChainStore.save("com.company.app.psd", data: appDelegate.userModel?.uuid)
                        
                        if(appDelegate.userModel?.token != nil  &&  appDelegate.userModel!.token!.count > 0) {
                            KeyChainStore.save("com.company.app.token", data: appDelegate.userModel!.token!)
                        }
                        
                        appDelegate.menuItemStatus.title = appDelegate.userModel?.phone ?? "Free"
                        appDelegate.setStatusLogin()
                        self.window?.close()
                    }
                }
                else {
                    appDelegate.makeToast("Login Failed")
                }
            })
    }
    
    
    func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String : Any]) {
        if userInfo["extra"] != nil {
            if((userInfo["extra"] as! [String:Any])["login_tag"] != nil  &&  ((userInfo["extra"] as! [String:Any])["login_tag"] as! Int) == 1  &&  (userInfo["extra"] as! [String:Any])["tag"] != nil  &&  ((userInfo["extra"] as! [String:Any])["tag"] as! Int) == 1) {
                self.userloginCount(uuid: UUIDHelper.getUUID(), vipUUID: (userInfo["uuid"] ?? "") as! String)
            }
            else if((userInfo["extra"] as! [String:Any])["login_tag"] != nil  &&  ((userInfo["extra"] as! [String:Any])["login_tag"] as! Int) == 2  &&  (userInfo["extra"] as! [String:Any])["tag"] != nil  &&  ((userInfo["extra"] as! [String:Any])["tag"] as! Int) == 1) {
                self.makeToast("Failure to force login")
            }
            else if((userInfo["extra"] as! [String:Any])["login_tag"] != nil  &&  ((userInfo["extra"] as! [String:Any])["login_tag"] as! Int) == 0  &&  (userInfo["extra"] as! [String:Any])["tag"] != nil  &&  ((userInfo["extra"] as! [String:Any])["tag"] as! Int) == 1) {
                let alert = NSAlert();
                alert.alertStyle = .informational;
                alert.messageText = "Agree with each other login";
                alert.addButton(withTitle: "Cancel")
                alert.addButton(withTitle: "OK")
                let modalResponse: NSApplication.ModalResponse = alert.runModal();
                
                switch modalResponse {
                case NSApplication.ModalResponse.alertFirstButtonReturn:
                    accreditLogin(dict: ["vip_uuid":(userInfo["uuid"] as! String), "bundle_id":Bundle.main.bundleIdentifier!.replacingOccurrences(of: ".mac", with: ""), "isDev":PchFile.pushBox, "tag":"1", "uuid":UUIDHelper.getUUID(), "login_tag":"2"])
                default:
                    accreditLogin(dict: ["vip_uuid":(userInfo["uuid"] as! String), "bundle_id":Bundle.main.bundleIdentifier!.replacingOccurrences(of: ".mac", with: ""), "isDev":PchFile.pushBox, "tag":"1", "uuid":UUIDHelper.getUUID(), "login_tag":"1", "env":PchFile.pushBox])
                    break;
                }
            }
            else if((userInfo["extra"] as! [String:Any])["login_tag"] != nil  &&  ((userInfo["extra"] as! [String:Any])["login_tag"] as! Int) == 0  &&  (userInfo["extra"] as! [String:Any])["tag"] != nil  &&  ((userInfo["extra"] as! [String:Any])["tag"] as! Int) == 2) {
                let alert = NSAlert();
                alert.alertStyle = .informational;
                alert.messageText = "Your account has been logged in elsewhere. If you are not authorized by yourself, please log in again and change your password.";
                alert.addButton(withTitle: "Cancel")
                alert.addButton(withTitle: "OK")
                let modalResponse: NSApplication.ModalResponse = alert.runModal();
                
                switch modalResponse {
                case NSApplication.ModalResponse.alertSecondButtonReturn:
                    KeyChainStore.deleteKeyData("com.company.app.token")
                    KeyChainStore.deleteKeyData("com.company.app.psd")
                    
                    self.userCountActiveWithUUID(uuid: nil, bundleID: Bundle.main.bundleIdentifier!.replacingOccurrences(of: ".mac", with: ""), token: nil)
                default:
                    break;
                }
            }
            else if((userInfo["extra"] as! [String:Any])["tag"] != nil  &&  ((userInfo["extra"] as! [String:Any])["tag"] as! Int) == 3) {
                actBuy(nil)
            }
        }
    }
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        ProxyConfHelper.install()
        _ = LaunchAtLoginController()// Ensure set when launch
        
        NSUserNotificationCenter.default.delegate = self
        
        self.ensureLaunchAgentsDirOwner()
        self.getNeedRouteInfo()
        
        // Prepare ss-local
        InstallSSLocal()
        InstallPrivoxy()
        InstallSimpleObfs()
        // Prepare defaults
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            "ShadowsocksOn": true,
            "ShadowsocksRunningMode": "auto",
            "LocalSocks5.ListenPort": NSNumber(value: 1086 as UInt16),
            "LocalSocks5.ListenAddress": "127.0.0.1",
            "PacServer.ListenPort":NSNumber(value: 1089 as UInt16),
            "LocalSocks5.Timeout": NSNumber(value: 60 as UInt),
            "LocalSocks5.EnableUDPRelay": NSNumber(value: false as Bool),
            "LocalSocks5.EnableVerboseMode": NSNumber(value: false as Bool),
            "GFWListURL": "https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt",
            "AutoConfigureNetworkServices": NSNumber(value: true as Bool),
            "LocalHTTP.ListenAddress": "127.0.0.1",
            "LocalHTTP.ListenPort": NSNumber(value: 1087 as UInt16),
            "LocalHTTPOn": true,
            "LocalHTTP.FollowGlobal": true,
            "Kcptun.LocalHost": "127.0.0.1",
            "Kcptun.LocalPort": NSNumber(value: 8388),
            "Kcptun.Conn": NSNumber(value: 1),
            "ProxyExceptions": "127.0.0.1, localhost, 192.168.0.0/16, 10.0.0.0/8",
            ])
        
        statusItem = NSStatusBar.system.statusItem(withLength: AppDelegate.StatusItemIconWidth)
        statusItem.isEnabled = false;
        let image : NSImage = NSImage(named: NSImage.Name(rawValue: "menu_icon_disabled"))!
        image.isTemplate = true
        statusItem.image = image
        statusItem.menu = statusMenu
        UserDefaults.standard.set("http://47.75.13.70", forKey: "ip")
        UserDefaults.standard.synchronize()
        
        let notifyCenter = NotificationCenter.default
        
        _ = notifyCenter.rx.notification(NOTIFY_CONF_CHANGED)
            .subscribe(onNext: { noti in
                self.applyConfig()
//                self.updateCopyHttpProxyExportMenu()
            })
        
        notifyCenter.addObserver(forName: NOTIFY_SERVER_PROFILES_CHANGED, object: nil, queue: nil
            , using: {
                (note) in
                let profileMgr = ServerProfileManager.instance
                if profileMgr.activeProfileId == nil &&
                    profileMgr.profiles.count > 0{
                    if profileMgr.profiles[0].isValid(){
                        profileMgr.setActiveProfiledId(profileMgr.profiles[0].uuid)
                        
                        let profileName: String;
                        if !profileMgr.profiles[0].remark.isEmpty {
                            profileName = profileMgr.profiles[0].remark
                        }
                        else {
                            profileName = profileMgr.profiles[0].serverHost
                        }
                        
                        let serverMenuText = "Server - \(profileName)"
                        self.serverMenuItem.title = serverMenuText;
                    }
                }
                
                self.updateRunningModeMenu()
                SyncSSLocal()
            }
        )
        _ = notifyCenter.rx.notification(NOTIFY_TOGGLE_RUNNING_SHORTCUT)
            .subscribe(onNext: { noti in
                self.doToggleRunning(showToast: true)
            })
        _ = notifyCenter.rx.notification(NOTIFY_FOUND_SS_URL)
            .subscribe(onNext: { noti in
                self.handleFoundSSURL(noti)
            })
        
        // Handle ss url scheme
        NSAppleEventManager.shared().setEventHandler(self
            , andSelector: #selector(self.handleURLEvent)
            , forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
        
        getAllRouteInfo()
        
        
        let mode = defaults.string(forKey: "ShadowsocksRunningMode")
        menuItemSmartMode.tag = (mode != nil  && mode == "global") ? 0 : 1

        updateMainMenu()
        updateRunningModeMenu()
        
        ProxyConfHelper.install()
        ProxyConfHelper.startMonitorPAC()
        applyConfig()

        // Register global hotkey
        ShortcutsController.bindShortcuts()
        
        
        //GetAvailableIP
        if((NetworkReachabilityManager.init()?.isReachable)!) {
            self.getAvailableIP(url: PchFile.rootURL);
            self.userCountActiveWithUUID(uuid: UUIDHelper.getUUID(), bundleID: Bundle.main.bundleIdentifier!.replacingOccurrences(of: ".mac", with: ""), token: UUIDHelper.getToken())
            
            NSApplication.shared.registerForRemoteNotifications(matching: [.alert, .sound])
        }
        else {
            let alert = NSAlert();
            alert.alertStyle = .critical;
            alert.messageText = "Network is not connected, please try again";
            alert.runModal()
            NSApp.terminate(self)
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        StopSSLocal()
        StopPrivoxy()
        ProxyConfHelper.disableProxy()
    }

    func applyConfig() {
        SyncSSLocal()
        
        let defaults = UserDefaults.standard
        let isOn = defaults.bool(forKey: "ShadowsocksOn")
        let mode = defaults.string(forKey: "ShadowsocksRunningMode")
        
        if isOn {
            if mode == "auto" {
                ProxyConfHelper.enablePACProxy()
            } else if mode == "global" {
                ProxyConfHelper.enableGlobalProxy()
            } else if mode == "manual" {
                ProxyConfHelper.disableProxy()
            }
        } else {
            ProxyConfHelper.disableProxy()
        }
    }

    // MARK: - UI Methods
    @IBAction func actBuy(_ sender: Any?) {
        if(self.userModel != nil) {
            if buyWinCtrl != nil {
                buyWinCtrl.close()
            }
            
            buyWinCtrl = BuysWindowController(windowNibName: NSNib.Name(rawValue: "BuysWindowController"))
            buyWinCtrl.userModel = self.userModel;
            buyWinCtrl.showWindow(self)
            NSApp.activate(ignoringOtherApps: true)
            buyWinCtrl.window?.makeKeyAndOrderFront(self)
        }
    }
    
    @IBAction func toggleRunning(_ sender: NSMenuItem) {
        self.doToggleRunning(showToast: false)
    }
    
    func doToggleRunning(showToast: Bool) {
        let defaults = UserDefaults.standard
        var isOn = UserDefaults.standard.bool(forKey: "ShadowsocksOn")
        isOn = !isOn
        defaults.set(isOn, forKey: "ShadowsocksOn")
        
        self.updateMainMenu()
        self.applyConfig()
        
        if showToast {
            if isOn {
                self.makeToast("VPN: On".localized)
            }
            else {
                self.makeToast("VPN: Off".localized)
            }
        }
    }
    
    @IBAction func updateGFWList(_ sender: NSMenuItem) {
        UpdatePACFromGFWList()
    }
    
    @IBAction func showQRCodeForCurrentServer(_ sender: NSMenuItem) {
        var errMsg: String?
        if let profile = ServerProfileManager.instance.getActiveProfile() {
            if profile.isValid() {
                // Show window
                if qrcodeWinCtrl != nil{
                    qrcodeWinCtrl.close()
                }
                qrcodeWinCtrl = SWBQRCodeWindowController(windowNibName: NSNib.Name(rawValue: "SWBQRCodeWindowController"))
                qrcodeWinCtrl.qrCode = profile.URL()!.absoluteString
                qrcodeWinCtrl.legacyQRCode = profile.URL(legacy: true)!.absoluteString
                qrcodeWinCtrl.title = profile.title()
                qrcodeWinCtrl.showWindow(self)
                NSApp.activate(ignoringOtherApps: true)
                qrcodeWinCtrl.window?.makeKeyAndOrderFront(nil)
                
                return
            } else {
                errMsg = "Current server profile is not valid.".localized
            }
        } else {
            errMsg = "No current server profile.".localized
        }
        if let msg = errMsg {
            self.makeToast(msg)
        }
    }
    
    
    @IBAction func scanQRCodeFromScreen(_ sender: NSMenuItem) {
        ScanQRCodeOnScreen()
    }
    
    @IBAction func importProfileURLFromPasteboard(_ sender: NSMenuItem) {
        let pb = NSPasteboard.general
        if #available(OSX 10.13, *) {
            if let text = pb.string(forType: NSPasteboard.PasteboardType.URL) {
                if let url = URL(string: text) {
                    NotificationCenter.default.post(
                        name: Notification.Name(rawValue: "NOTIFY_FOUND_SS_URL"), object: nil
                        , userInfo: [
                            "urls": [url],
                            "source": "pasteboard",
                            ])
                }
            }
        }
        if let text = pb.string(forType: NSPasteboard.PasteboardType.string) {
            var urls = text.split(separator: "\n")
                .map { String($0).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
                .map { URL(string: $0) }
                .filter { $0 != nil }
                .map { $0! }
            urls = urls.filter { $0.scheme == "ss" }
            
            NotificationCenter.default.post(
                name: Notification.Name(rawValue: "NOTIFY_FOUND_SS_URL"), object: nil
                , userInfo: [
                    "urls": urls,
                    "source": "pasteboard",
                    ])
        }
    }

    @IBAction func actSmartMode(_ sender: Any) {
        let defaults = UserDefaults.standard
        
        if(menuItemSmartMode.tag == 1) {
            menuItemSmartMode.tag = 0
            defaults.setValue("global", forKey: "ShadowsocksRunningMode")
        }
        else {
            menuItemSmartMode.tag = 1;
            defaults.setValue("auto", forKey: "ShadowsocksRunningMode")
        }
        
        updateRunningModeMenu()
        applyConfig()
    }
    
    
    @IBAction func copyExportCommand(_ sender: NSMenuItem) {
        // Get the Http proxy config.
        let defaults = UserDefaults.standard
        let address = defaults.string(forKey: "LocalHTTP.ListenAddress")!
        let port = defaults.integer(forKey: "LocalHTTP.ListenPort")
        
        // Format an export string.
        let command = "export http_proxy=http://\(address):\(port);export https_proxy=http://\(address):\(port);"
        
        // Copy to paste board.
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(command, forType: NSPasteboard.PasteboardType.string)
        
        // Show a toast notification.
        self.makeToast("Export Command Copied.".localized)
    }
    
    @IBAction func showLogs(_ sender: NSMenuItem) {
        let ws = NSWorkspace.shared
        if let appUrl = ws.urlForApplication(withBundleIdentifier: "com.apple.Console") {
            try! ws.launchApplication(at: appUrl
                ,options: NSWorkspace.LaunchOptions.default
                ,configuration: [NSWorkspace.LaunchConfigurationKey.arguments: "~/Library/Logs/ss-local.log"])
        }
    }
    
    @IBAction func showAbout(_ sender: NSMenuItem) {
//        NSApp.orderFrontStandardAboutPanel(sender);
//        NSApp.activate(ignoringOtherApps: true)
        
        if(userModel != nil) {
            if locationWindowCtrl != nil {
                locationWindowCtrl.close()
            }
            
            locationWindowCtrl = LocationWindowController(windowNibName: NSNib.Name(rawValue: "LocationWindowController"))
            locationWindowCtrl.userModel = self.userModel;
            locationWindowCtrl.showWindow(self)
            NSApp.activate(ignoringOtherApps: true)
            locationWindowCtrl.window?.makeKeyAndOrderFront(self)
        }
    }
    
    func showNewPhoneOrEmail() {
        if newPhoneOrEmailWindowCtrl != nil {
            newPhoneOrEmailWindowCtrl.close()
        }
        
        newPhoneOrEmailWindowCtrl = NewPhoneOrEmailWindowController(windowNibName: NSNib.Name(rawValue: "NewPhoneOrEmailWindowController"))
        newPhoneOrEmailWindowCtrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        newPhoneOrEmailWindowCtrl.window?.makeKeyAndOrderFront(self)
    }
    
    func updateRunningModeMenu() {
        var serverMenuText = "Server"

        let mgr = ServerProfileManager.instance
        for p in mgr.profiles {
            if mgr.activeProfileId == p.uuid {
                var profileName :String
                if !p.remark.isEmpty {
                    profileName = p.remark
                } else {
                    profileName = p.serverHost
                }
                
                serverMenuText = "\(serverMenuText) - \(profileName)"
            }
        }
        serverMenuItem.title = serverMenuText
        
        let statusSmartMode = (menuItemSmartMode.tag==0 ? "Off":"On")
        menuItemSmartMode.title = "Smart Mode \(statusSmartMode)"
        updateStatusMenuImage()
    }
    
    func updateStatusMenuImage() {
        let defaults = UserDefaults.standard
        let isOn = defaults.bool(forKey: "ShadowsocksOn")
        if isOn && statusItem.isEnabled {
            statusItem.image = NSImage(named: NSImage.Name(rawValue: (menuItemSmartMode.tag == 0 ? "menu_icon" : "menu_icon_s")))
        } else {
            statusItem.image = NSImage(named: NSImage.Name(rawValue: "menu_icon_disabled"))
        }
    }
    
    func updateMainMenu() {
        let defaults = UserDefaults.standard
        let isOn = defaults.bool(forKey: "ShadowsocksOn")
        if isOn {
            runningStatusMenuItem.title = "VPN: On".localized
            toggleRunningMenuItem.title = "Turn VPN Off".localized
            let image = NSImage(named: NSImage.Name(rawValue: (statusItem.isEnabled ? "menu_icon" : "menu_icon_disabled")))
            statusItem.image = image
        } else {
            runningStatusMenuItem.title = "VPN: Off".localized
            toggleRunningMenuItem.title = "Turn VPN On".localized
            let image = NSImage(named: NSImage.Name(rawValue: "menu_icon_disabled"))
            statusItem.image = image
        }
        
        updateStatusMenuImage()
    }
    
    func updateCopyHttpProxyExportMenu() {
        let defaults = UserDefaults.standard
        let isOn = defaults.bool(forKey: "LocalHTTPOn")
        copyHttpProxyExportCmdLineMenuItem.isHidden = !isOn
    }
    
    
    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        if let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue {
            if let url = URL(string: urlString) {
                NotificationCenter.default.post(
                    name: Notification.Name(rawValue: "NOTIFY_FOUND_SS_URL"), object: nil
                    , userInfo: [
                        "urls": [url],
                        "source": "url",
                        ])
            }
        }
    }
    
    func getCoderVersionUUID(dict: [String:Any]) {
        
    }
    
    func handleFoundSSURL(_ note: Notification) {
        let sendNotify = {
            (title: String, subtitle: String, infoText: String) in
            
            let userNote = NSUserNotification()
            userNote.title = title
            userNote.subtitle = subtitle
            userNote.informativeText = infoText
            userNote.soundName = NSUserNotificationDefaultSoundName
            
            NSUserNotificationCenter.default
                .deliver(userNote);
        }
        
        if let userInfo = (note as NSNotification).userInfo {
            let urls = userInfo["urls"] as! [Any];
            
            if(urls.count > 0) {
                let dict: [String:Any] = urls[0] as! [String:Any]
                sendNotify("", "", "qrcode detected".localized)
                
                let strUrlPay = "\(PchFile.rootURL)/user_login/FindVersion.php";
                Alamofire.request(URL(string: strUrlPay)!,
                                  method: .post,
                                  parameters: ["uuid":dict["uuID"] as! String, "version":dict["version"] as! String, "bundleID":dict["bundleID"] as! String])
                    .validate()
                    .responseJSON { response in
                        guard response.result.isSuccess else {
                            return
                        }
                        
                        guard (response.result.value != nil),  let json = response.result.value as? [String: Any] else {
                            return
                        }
                        
                        if(json["version"] != nil  &&  (json["version"] as! String) == (dict["version"] as! String)) {
                            let alert = NSAlert();
                            alert.alertStyle = .informational;
                            alert.messageText = "Continue Login?";
                            alert.addButton(withTitle: "Cancel")
                            alert.addButton(withTitle: "Force Login")
                            alert.addButton(withTitle: "Show Login Screen")
                            let modalResponse: NSApplication.ModalResponse = alert.runModal();

                            switch modalResponse {
                            case NSApplication.ModalResponse.alertSecondButtonReturn:
                                self.accreditLogin(dict: ["vip_uuid":(json["uuID"] ?? ""), "bundle_id":Bundle.main.bundleIdentifier!.replacingOccurrences(of: ".mac", with: ""), "isDev":PchFile.pushBox, "tag":1, "uuid":UUIDHelper.getUUID(), "login_tag":0])

                            case NSApplication.ModalResponse.alertThirdButtonReturn:
                                self.showLoginView()
                            default:
                                break;
                            }
                        }
                        else {
                            self.makeToast("QRCode expired!")
                        }
                    }
                }
            else {
                sendNotify("", "", "qrcode not detected".localized)
            }
        }
    }
    
    //------------------------------------------------------------
    // NSUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: NSUserNotificationCenter
        , shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
    
    
    func makeToast(_ message: String) {
        if toastWindowCtrl != nil {
            toastWindowCtrl.close()
        }
        toastWindowCtrl = ToastWindowController(windowNibName: NSNib.Name(rawValue: "ToastWindowController"))
        toastWindowCtrl.message = message
        toastWindowCtrl.showWindow(self)
        //NSApp.activate(ignoringOtherApps: true)
        //toastWindowCtrl.window?.makeKeyAndOrderFront(self)
        toastWindowCtrl.fadeInHud()
    }
    
    @IBAction func actVipSecurityCenter(_ sender: Any) {
        if(self.userModel != nil  &&  self.userModel?.user_type == "vip") {
            if(self.userModel?.phone != nil  &&  self.userModel!.phone!.count > 0) {
                if changePhoneNumberWinCtrl != nil {
                    changePhoneNumberWinCtrl.close()
                }
                
                changePhoneNumberWinCtrl = ChangePhoneNumberWindowController(windowNibName: NSNib.Name(rawValue: "ChangePhoneNumberWindowController"))
                changePhoneNumberWinCtrl.userModel = self.userModel;
                changePhoneNumberWinCtrl.showWindow(self)
                NSApp.activate(ignoringOtherApps: true)
                changePhoneNumberWinCtrl.window?.makeKeyAndOrderFront(self)
            }
            else {
                self.showBindPhoneOrEmailWindowsController()
            }
        }
        else {
            self.makeToast("For VIP only")
        }
    }
    
    func showBindPhoneOrEmailWindowsController() {
        if bindPhoneOrEmailWinCtrl != nil {
            bindPhoneOrEmailWinCtrl.close()
        }
        
        bindPhoneOrEmailWinCtrl = BindPhoneOrEmailWindowController(windowNibName: NSNib.Name(rawValue: "BindPhoneOrEmailWindowController"))
        bindPhoneOrEmailWinCtrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        bindPhoneOrEmailWinCtrl.window?.makeKeyAndOrderFront(self)
    }
    
    
    @IBAction func actChangePassword(_ sender: Any) {
        if(userModel != nil  &&  userModel?.user_type != nil  &&  userModel?.user_type! == "vip") {
            let title1: String?
            let title2: String?
            
            if userModel!.password != nil  &&  userModel?.password == JoDess.md5("1") {
                title1 = PchFile.key58
                title2 = "Please confirm your password"
            }
            else {
                title1 = "Please enter the old password"
                title2 = PchFile.key58
            }
            
            
            
            if changePasswordWinCtrl != nil {
                changePasswordWinCtrl.close()
            }
            
            changePasswordWinCtrl = ChangePasswordWindowController(windowNibName: NSNib.Name(rawValue: "ChangePasswordWindowController"))
            changePasswordWinCtrl.title1 = title1;
            changePasswordWinCtrl.title2 = title2;
            changePasswordWinCtrl.showWindow(self)
            NSApp.activate(ignoringOtherApps: true)
            changePasswordWinCtrl.window?.makeKeyAndOrderFront(self)
        }
        else {
            makeToast("For VIP only")
        }
    }
    
    @IBAction func actPurchaseHistory(_ sender: Any) {
        if(self.userModel != nil  &&  self.userModel?.user_type != nil  &&  self.userModel?.user_type == "vip") {
            if purchaseHistoryWinCtrl != nil {
                purchaseHistoryWinCtrl.close()
            }
            
            purchaseHistoryWinCtrl = PurchaseHistoryWindowController(windowNibName: NSNib.Name(rawValue: "PurchaseHistoryWindowController"))
            purchaseHistoryWinCtrl.showWindow(self)
            NSApp.activate(ignoringOtherApps: true)
            purchaseHistoryWinCtrl.window?.makeKeyAndOrderFront(self)
        }
        else {
            makeToast("For VIP only")
        }
    }
    
    @IBAction func actionLoginShowQR(_ sender: Any) {
        if menuItemBindOrBarcode.tag == LoginStatus.Bind.getRawValue() {
            let alert = NSAlert();
            alert.alertStyle = .informational;
            alert.messageText = "For your account's security and convenience to retrieve your account or password, please bind the mailbox or phone number";
            alert.addButton(withTitle: "YES")
            alert.addButton(withTitle: "NO")
            let modalResponse: NSApplication.ModalResponse = alert.runModal();
            
            switch modalResponse {
                case NSApplication.ModalResponse.alertFirstButtonReturn:
                    showBindPhoneOrEmailWindowsController()
                default:
                    break;
            }
        }
        else if menuItemBindOrBarcode.tag == LoginStatus.ShowQR.getRawValue() {
            var version = self.userModel?.version == nil ? 0.0 : Float(self.userModel!.version!)
            version = version! + 1.0
            
            
            let dict = ["uuID":UUIDHelper.getUUID(), "bundleID":Bundle.main.bundleIdentifier!.replacingOccurrences(of: ".mac", with: ""), "version":version!] as [String : Any]
            let subTempData = try? JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions.prettyPrinted)
            var isSuccess = false;
            
            
            if(subTempData != nil) {
                let subStr = String(data: subTempData!, encoding: String.Encoding.utf8)
                let base64: String = JoDess.encodeBase64(with: subStr!)
                let data = base64.data(using: String.Encoding.utf8)
                let qrImage = generateQRCode(from: data!)
                
                if(qrImage != nil) {
                    isSuccess = true;
                    
                    if showQRCodeWindowCtrl != nil {
                        showQRCodeWindowCtrl.close()
                    }
                    
                    showQRCodeWindowCtrl = ShowQRCodeWindowController(windowNibName: NSNib.Name(rawValue: "ShowQRCodeWindowController"))
                    showQRCodeWindowCtrl.qrImage = qrImage;
                    showQRCodeWindowCtrl.showWindow(self)
                    NSApp.activate(ignoringOtherApps: true)
                    showQRCodeWindowCtrl.window?.makeKeyAndOrderFront(self)
                }
            }
            
            
            if(!isSuccess) {
                makeToast("Failed Generate QR Code");
            }
        }
        else {
            self.showLoginView()
        }
    }
    
    
    
    //MARK: - API & Method
    func showLoginView() {
        if loginWinCtrl != nil {
            loginWinCtrl.close()
        }
        
        loginWinCtrl = LoginWindowController(windowNibName: NSNib.Name(rawValue: "LoginWindowController"))
        loginWinCtrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        loginWinCtrl.window?.makeKeyAndOrderFront(self)
    }
    
    func registerAPNs(dict: [String:Any]) {
        let strUrlPay = "\(PchFile.rootURL)/push_info/ReceiveInfo.php";
        Alamofire.request(URL(string: strUrlPay)!,
                          method: .post,
                          parameters: dict)
            .validate()
            .responseData(completionHandler: { response in
                guard response.result.isSuccess else {
                    return
                }
                
                /*let str = JoDess.decode(String(data: response.result.value!, encoding: String.Encoding.utf8), key: PchFile.keyDecode);
                let json: [String:Any]? = str?.convertToDictionary();
                
                
                if(json != nil  &&  json!["error_code"] != nil  &&  (json!["error_code"] as! Int) != 0) {
                    UserDefaults.standard.setValue(dict["token"], forKey: "deviceTokenStr")
                    UserDefaults.standard.synchronize()
                }*/
            })
    }
    


    
    func generateQRCode(from data: Data) -> NSImage? {
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                let rep = NSCIImageRep(ciImage: output)
                let image = NSImage(size: rep.size)
                image.addRepresentation(rep)
                
                return image
            }
        }
        
        return nil
    }

    
    func setStatusLogin() {
        //Setup Menu Item
        menuItemBindOrBarcode.isEnabled = true;
        
        if(self.userModel != nil   &&  self.userModel?.user_type == "vip"  &&  self.userModel?.phone != nil) {
            menuItemBindOrBarcode.title = "Show Barcode";
            menuItemBindOrBarcode.tag = LoginStatus.ShowQR.getRawValue()
        }
        else if(self.userModel != nil  && self.userModel?.user_type == "vip"  &&  self.userModel?.phone == nil) {
            menuItemBindOrBarcode.title = "Bind Phone or Email"
            menuItemBindOrBarcode.tag = LoginStatus.Bind.getRawValue()
        }
        else {
            menuItemBindOrBarcode.title = "Login"
            menuItemBindOrBarcode.tag = LoginStatus.Login.getRawValue()
        }
        
        
        if(self.userModel != nil  &&  self.userModel?.user_type != nil  &&  self.userModel?.user_type == "vip") {// Disable Scan Button if VIP
            self.scanQRCodeMenuItem.isEnabled = false;
        }
        else {
            self.scanQRCodeMenuItem.isEnabled = true;
        }
    }
    
    func getAvailableIP(url: String) {
        let strUrl = url.appending("/tactics/Domain.php")
        guard let tempURL = URL(string: strUrl) else {
            return
        }
        
        Alamofire.request(tempURL,
                          method: .post).validate()
            .responseData(completionHandler: { response in
                guard response.result.isSuccess else {
                    return
                }
                
                if(response.result.value != nil) {
                    let str = JoDess.decode(String(data: response.result.value!, encoding: String.Encoding.utf8), key: PchFile.keyDecode);
                    let json: [String:Any]? = str?.convertToDictionary();
                    
                    UserDefaults.standard.set(json, forKey: "ipLoop")
                    UserDefaults.standard.set(url, forKey: "ip")
                    UserDefaults.standard.synchronize()
                    
                    self.isConnect = true;
                    self.blogConnect = true;
                }
                else {
                    //取本地的域名池中可用的域名使用
                    let json: [String : Any]? = UserDefaults.standard.object(forKey: "ipLoop") as? [String : Any];
                    var arr: [String]?;

                    if(json != nil) {
                        arr = json!["ips"] as? [String];
                    }
                    
                    
                    if(arr != nil  &&  (arr?.count)! != 0  &&  self.i < (arr?.count)!  &&  self.isConnect == false) {
                        let urlStr = "http://\(arr![self.i])"
                        self.i = self.i+1;
                        self.getAvailableIP(url: urlStr)
                    }
                    else if(self.isConnect == false) {
                        let data: [String : Any]? = UserDefaults.standard.object(forKey: "ipLoop") as? [String : Any];
                        let blogURL: String?
                        
                        if(data != nil) {
                            blogURL = data!["blog"] as? String;
                        }
                        else {
                            blogURL = nil;
                        }
                        
                        
                        var contentArr: [[String:Any]];
                        
                        if(blogURL != nil) {
                            contentArr = self.decodeContent(blogURL!);
                        
                            for dic in contentArr {
                                if(self.isConnect == true) {
                                    return;
                                }
                                
                                guard let linkURL = dic["LinkUrl"] else {
                                    return;
                                }
                                
                                self.getAvailableIP(url: (linkURL as! String))
                            }
                        }
                    }
                    else if(self.blogConnect == false) {
                        let data: [String:Any]? = UserDefaults.standard.object(forKey: "ipLoop") as? [String:Any];
                        let txtUrl: String
                        let contentArr: [[String:Any]]
                        
                        if(data != nil) {
                            txtUrl = data!["txt"] as! String
                            
                            contentArr = self.decodeContent(txtUrl);
                            for dict in contentArr {
                                if(self.isConnect == true) {
                                    return
                                }
                                
                                guard let linkURL = dict["LinkUrl"] else {
                                    return;
                                }
                                self.getAvailableIP(url: (linkURL as! String))
                            }
                        }
                    }
                }
            })
    }
    
    
    
    func decodeContent(_ str: String?) -> [[String:Any]] {
        if(str != nil) {
            var string = try? String(contentsOf: URL(string: str!)!, encoding: String.Encoding.utf8);
            
            if(string != nil) {
                guard let startRange = string!.range(of: "........#######") else {
                    return [[String:Any]]();
                }
                string = String(string![startRange.upperBound...])
                
                guard let endRange = string!.range(of: "#######.......") else {
                    return [[String:Any]]();
                }
                string = String(string![..<endRange.lowerBound])
                
                let strURL = string!.replacingOccurrences(of: "<wbr>", with: "")
                guard let nsData = Data(base64Encoded: DesFile.decrypt(withText: strURL), options: NSData.Base64DecodingOptions(rawValue: 0)) else {
                    return [[String:Any]]();
                }
                
                let stringData: String = String(data: nsData, encoding: String.Encoding.utf8)!;
                let data = stringData.data(using: String.Encoding.utf8);
                
                if(data != nil) {
                    guard let jsonArray = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) else {
                        return [[String:Any]]();
                    }
                    
                    return jsonArray as! [[String:Any]];
                }
            }
        }
        
        return [[String:Any]]();
    }
    
    
    
    
    func userCountActiveWithUUID(uuid: String?, bundleID: String, token: String?) {
        let urlString = "\(PchFile.rootURL)/user_activate/UserActivate.php"
        var dic = [String : String]();
        dic["bundle_id"] = bundleID;
        
        if(uuid != nil  &&  uuid!.count > 0) {
            dic["uuid"] = uuid!
            
            if(token != nil) {
                dic["token"] = token!
            }
        }
        
        
        Alamofire.request(URL(string: urlString)!,
                          method: .post,
                          parameters: dic)
            .validate()
            .responseData(completionHandler: { response in
                guard response.result.isSuccess else {
                    let alert = NSAlert();
                    alert.alertStyle = .critical;
                    alert.messageText = "Failed Get Activate User, Please try again!";
                    alert.runModal();
                    self.getData()
                    
                    return
                }
                

                var str = String(data: response.result.value!, encoding: String.Encoding.utf8)
                if(dic.keys.count == 1) {
                    self.makeToast("Congratulations, you've got an hour of free time to experience.")
                }
                
                str = JoDess.decode(str, key: PchFile.keyDecode);
                let json: [String:Any]? = str?.convertToDictionary();
                
                let share: UserDefaults = UserDefaults(suiteName: "group.com.tms.rvp")!
                share.set(str, forKey: "userInfo")
                share.synchronize()

                
                if(json != nil  &&  json!["error_code"] != nil  &&  (json!["error_code"] as! Int) == 0) {
                    if(json!["data"] != nil) {
                        self.userModel = UserModel();
                        
                        let subData = json!["data"] as! [String : Any];
                        self.userModel!.register_time = subData["register_time"] as? String
                        self.userModel!.token = subData["token"] as? String
                        self.userModel!.user_expiration_date = subData["user_expiration_date"] as? String
                        self.userModel!.user_type = subData["user_type"] as? String
                        self.userModel!.uuid = subData["uuid"] as? String
                        self.userModel!.goods_name = subData["goods_name"] as? String
                        self.userModel!.qq = subData["qq"] as? String
                        self.userModel!.password = subData[""] as? String
                        self.userModel!.phone = subData["phone"] as? String
                        self.userModel!.version = subData["version"] as? String
                        self.userModel!.user_name = subData["user_name"] as? String
                        self.userModel!.apple_id = subData["apple_id"] as? String
                        
                        self.menuItemStatus.title = self.userModel?.user_name ?? "Free"
                        
                        KeyChainStore.save("com.company.app.psd", data: (json!["data"] as! [String:Any])["uuid"])
                        self.coachDatawithkey("user", self.userModel as Any, "usermodel")
                    }
                    
                    self.setStatusLogin()
                    
                    
                    UserDefaults.standard.setValue((json!["data"] as! [String:Any])["user_type"], forKey: "user_type")
                    UserDefaults.standard.setValue((json!["data"] as! [String:Any])["user_expiration_date"], forKey: "userTime")
                    UserDefaults.standard.synchronize()
                }
                
                self.statusItem.isEnabled = true
                
                self.updateStatusMenuImage()
            })
    }
    
    func getData() {
        self.getNeedRouteInfo()
        self.userCountActiveWithUUID(uuid: UUIDHelper.getUUID(), bundleID: Bundle.main.bundleIdentifier!.replacingOccurrences(of: ".mac", with: ""), token: UUIDHelper.getToken())
    }
    
    func getNeedRouteInfo() {
        lineModel = ListModel();
        guard let tempData: [String : String] = UserDefaults.standard.object(forKey: "lineInfo") as? [String : String] else {
            return
        }
        
        if(tempData.count > 0) {
            lineModel?.type = tempData["type"]
            lineModel?.areaCode = tempData["area_code"]
            lineModel?.areaName = tempData["area_name"]
        }
        
        let str: String? = UserDefaults.standard.object(forKey: "connectType") as? String
        
        
        if(lineModel!.areaCode != nil  &&  lineModel!.areaCode!.count > 0) {
            if(str==nil || str?.count==0) {
                if(lineModel!.type == "vip") {
                    self.getVpnMessageWithType("vip_area", self.lineModel!.areaCode, "ssr", "SSR")
                }
                else  {
                    self.getVpnMessageWithType("area", self.lineModel!.areaCode, "ssr", "SSR")
                }
            }
        }
        else {
            self.getVpnMessageWithType("random", nil, "ssr", "SSR")
        }
    }
    
    
    func getVpnMessageWithType(_ type: String, _ area: String?, _ protocolType: String, _ appType: String?) {
        let urlString = "\(PchFile.rootURL)/get_server/ReturnServer.php"
        var dic = [String : String]();
        dic["type"] = type
        dic["connect_type"] = protocolType
        
        if(area != nil) {
            dic["area_code"] = area
        }
        
        if(appType != nil) {
            dic["area_diff"] = appType
        }
            
        
        Alamofire.request(URL(string: urlString)!,
                          method: .post,
                          parameters: dic)
            .validate()
            .responseData(completionHandler: { response in
                guard response.result.isSuccess else {
//                    self.getCoachRoute()
                    return;
                }
                
                let string = String(data: response.result.value!, encoding: String.Encoding.utf8);
                let str = JoDess.decode(string, key: PchFile.keyDecode)
                var json: [String:Any]? = str?.convertToDictionary();
                
                if(json != nil  &&  json!["error_code"] != nil  && (json!["error_code"] as! Int) == 0) {
                    json = json!["data"] as? [String:Any]
                    self.setupProfileActive(dict: json!)
                    
                    // today直接链接
                    let share = UserDefaults(suiteName: "group.com.tms.rvp")
                    share?.set(str, forKey: "routeDetail")
                    share?.synchronize()
                    UserDefaults.standard.set(json, forKey: "routeModel")
                }
            })
    }
    
    func getCoachRoute() {
        let data: Data? = UserDefaults.standard.object(forKey: "allRoute") as? Data
        if(data != nil   &&  data!.count > 0) {
            let unArchiver: NSKeyedUnarchiver = NSKeyedUnarchiver.init(forReadingWith: data!)
            allRouteArray = unArchiver.decodeObject(forKey: "allRouteArray") as! [[RouteModel]]
            unArchiver.finishDecoding()
            
            let count: Int = (allRouteArray.count > 0 ? allRouteArray[0].count : 0)
            
            if(count > 0) {
                let num = Int(arc4random() % UInt32(count))
                let tempRouteModel: RouteModel = allRouteArray[0][num]
                var tempDict: [String:Any] = [String:Any]();
                tempDict["vps_area_name"] = tempRouteModel.vpsUserName ?? ""
                tempDict["vps_addr"] = tempRouteModel.vpsAddr ?? ""
                tempDict["ss_pass"] = tempRouteModel.vpsPassword ?? ""
                tempDict["encrypt"] = tempRouteModel.encrypt ?? ""
                tempDict["port"] = tempRouteModel.port ?? ""
                
                self.setupProfileActive(dict: tempDict)
            }
        }
    }
    
    func setupProfileActive(dict: [String:Any]) {
        var uuid = UUID().uuidString
        let profileMgr = ServerProfileManager.instance
        
        for serverProfile in profileMgr.profiles {
            if serverProfile.serverHost == (dict["vps_addr"] as? String) {
                uuid = serverProfile.uuid;
                
                break
            }
        }
        
        let serverProfile: ServerProfile = ServerProfile(uuid: uuid);
        
        if(Locale.current.languageCode == "zh") {
            serverProfile.remark = (dict["vps_area_name"] ?? "") as! String;
        }
        else {
            serverProfile.remark = (dict["vps_area_code"] ?? "") as! String;
        }
        serverProfile.serverHost = (dict["vps_addr"] ?? "") as! String;
        serverProfile.password = (dict["ss_pass"] ?? "") as! String;
        serverProfile.method = (dict["encrypt"] ?? "") as! String;

        if let port = (dict["port"] as? String), let portInt = uint16(port) {
            serverProfile.serverPort = portInt
        }
        
        
        profileMgr.profiles = [ServerProfile]();
        profileMgr.profiles.append(serverProfile)
        profileMgr.save()
    }

    func coachDatawithkey(_ str: String, _ value:Any, _ key:String) {
        UserDefaults.standard.removeObject(forKey: str)
        let data = NSMutableData();
        let archivier: NSKeyedArchiver = NSKeyedArchiver(forWritingWith: data);
        archivier.encode(value, forKey: key)
        archivier.finishEncoding()
        UserDefaults.standard.set(data, forKey: str)
        UserDefaults.standard.synchronize()
    }
    
    func chooseRouteInfo(model: ListModel) {
        if(model.type != nil  &&  model.type=="vip") {
            self.getVpnMessageWithType("vip_area", model.areaCode, "ssr", "SSR")
        }
        else {
            self.getVpnMessageWithType("area", model.areaCode, "ssr", "SSR")
        }
    }
    
    
    func getAllRouteInfo() {
        let strUrl = "\(PchFile.rootURL)/get_server/ReturnAllServer.php"
        guard let tempURL = URL(string: strUrl) else {
            return
        }
        
        Alamofire.request(tempURL,
                          method: .post).validate()
            .responseData(completionHandler: { response in
                guard response.result.isSuccess else {
                    return
                }
                
                let string = String(data: response.result.value!, encoding: String.Encoding.utf8)
                let str = JoDess.decode(string, key: PchFile.keyDecode)
                let json: [String:Any]? = str?.convertToDictionary();
                
                if(json != nil  &&  ((json!["error_code"] != nil  &&  (json!["error_code"] as! Int) == 0) || json!["error_code"] == nil)) {
                    var arrTempModel = [RouteModel]();
                    
                    for dict in (json!["list"] as! [[String:Any]]) {
                        let model: RouteModel = RouteModel();
                        model.vpsAddr = dict["ip"] as? String
                        model.vpsUserName = dict["name"] as? String
                        model.vpsPassword = dict["ss_pass"] as? String
                        model.vpsPsk = dict["psk"] as? String
                        model.vpsAreaCode = dict["area_code"] as? String
                        model.vpsConnectType = dict["connect_type"] as? String
                        model.remoteID = dict["remote_id"] as? String
                        model.encrypt = dict["encrypt"] as? String
                        model.ssPass = dict["pass"] as? String
                        model.port = dict["port"] as? String
                        model.addTime = dict["add_time"] as? String
                        model.supplier = dict["supplier"] as? String
                        model.ssProtocol = dict["ss_protocol"] as? String
                        model.ssMix = dict["ss_mix"] as? String
                        
                        arrTempModel.append(model)
                    }
                    
                    self.allRouteArray.append(arrTempModel)
                    self.coachDatawithkey("allRoute", self.allRouteArray, "allRouteArray")
                }
            })
    }
}
