//
//  LoginWindowController.swift
//  ShadowsocksX-NG
//
//  Created by a on 11/10/18.
//  Copyright © 2018 qiuyuzhou. All rights reserved.
//
import Alamofire
import Cocoa

class LoginWindowController: NSWindowController {
    @IBOutlet var tfPassword: NSSecureTextField!
    @IBOutlet var tfUserName: NSTextField!
    @IBOutlet var actIndicator: NSProgressIndicator!
    @IBOutlet var bgProcessIndicator: NSView!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        bgProcessIndicator.wantsLayer = true
        bgProcessIndicator.layer?.backgroundColor = NSColor.lightGray.withAlphaComponent(0.5).cgColor;
        
        //TODO: Change with the elegant style to handle prevent subview be clicked
        bgProcessIndicator.addGestureRecognizer(NSClickGestureRecognizer.init(target: self, action: #selector(actionClickGesture(_:))))
        bgProcessIndicator.addGestureRecognizer(NSPressGestureRecognizer.init(target: self, action: #selector(actionClickGesture(_:))))
        bgProcessIndicator.addGestureRecognizer(NSPanGestureRecognizer.init(target: self, action: #selector(actionClickGesture(_:))))
    }
    
    @objc func actionClickGesture(_ sender: Any) {
    }
    
    func showProgressIndicator(_ isStop: Bool) {
        bgProcessIndicator.isHidden = isStop;
        actIndicator.isHidden = isStop;
        actIndicator.isIndeterminate = true;
        actIndicator.usesThreadedAnimation = true;
        actIndicator.startAnimation(nil);
    }
    
    @IBAction func actLogin(_ sender: Any) {
        if(tfUserName.stringValue.count == 0  ||  tfPassword.stringValue.count == 0) {
            let alert = NSAlert();
            alert.alertStyle = .informational;
            alert.messageText = "Please fill all field";
            alert.addButton(withTitle: "Ok")
            alert.beginSheetModal(for: self.window!, completionHandler: nil)
        }
        else {
            guard let url = URL(string: "\(PchFile.rootURL)/user_login/Login.php") else {
                return
            }
            
            self.showProgressIndicator(false)
            let deviceToken = (UserDefaults.standard.value(forKey: "deviceTokenStr") as? String) ?? ""
            var dict = ["bundle_id":Bundle.main.bundleIdentifier!.replacingOccurrences(of: ".mac", with: ""), "password":JoDess.md5(tfPassword.stringValue)!, "env":PchFile.pushBox, "free_token":deviceToken] as [String:Any]
            
            if(tfUserName.stringValue.contains("@")) {
                dict["email"] = tfUserName.stringValue
            }
            else if(!tfUserName.stringValue.contains("@")  &&  Int(tfUserName.stringValue) != nil  && Int(tfUserName.stringValue)! > 10000000000) {
                dict["phone"] = tfUserName.stringValue
            }
            else {
                dict["user_name"] = tfUserName.stringValue
            }
            
            
            
            Alamofire.request(url,
                              method: .post,
                              parameters: dict)
                .validate()
                .responseData(completionHandler: { response in
                    self.showProgressIndicator(true)
                    
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
    }
}
