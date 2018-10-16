//
//  ChangePasswordWindowController.swift
//  ShadowsocksX-NG
//
//  Created by a on 10/10/18.
//  Copyright © 2018 qiuyuzhou. All rights reserved.
//
import Alamofire
import Cocoa

class ChangePasswordWindowController: NSWindowController {
    var title1: String!
    var title2: String!
    @IBOutlet var lblTitle1: NSTextField!
    @IBOutlet var lblTitle2: NSTextField!
    @IBOutlet var tf1: NSSecureTextField!
    @IBOutlet var tf2: NSSecureTextField!
    @IBOutlet var actIndicator: NSProgressIndicator!
    @IBOutlet var bgProcessIndicator: NSView!
    
    
    override func windowDidLoad() {
        super.windowDidLoad()

        lblTitle1.stringValue = title1
        lblTitle2.stringValue = title2
        
        bgProcessIndicator.wantsLayer = true
        bgProcessIndicator.layer?.backgroundColor = NSColor.lightGray.withAlphaComponent(0.5).cgColor;
        
        //TODO: Change with the elegant style to handle prevent subview be clicked
        bgProcessIndicator.addGestureRecognizer(NSClickGestureRecognizer.init(target: self, action: #selector(actionClickGesture(_:))))
        bgProcessIndicator.addGestureRecognizer(NSPressGestureRecognizer.init(target: self, action: #selector(actionClickGesture(_:))))
        bgProcessIndicator.addGestureRecognizer(NSPanGestureRecognizer.init(target: self, action: #selector(actionClickGesture(_:))))
    }
    
    //MARK: - Action
    @IBAction func actSave(_ sender: Any) {
        let appDelegate: AppDelegate = NSApplication.shared.delegate as! AppDelegate
        
        if(title1 == PchFile.key58) {
            if tf1.stringValue == tf2.stringValue {
                if tf1.stringValue.count >= 8 {
                    self.showProgressIndicator(false)
                    self.changePasswordWithpassword1(str1: appDelegate.userModel!.password!, str2: JoDess.md5(tf2.stringValue))
                }
                else {
                    appDelegate.makeToast("Password at least 8 (including letters, numbers, underline)")
                }
            }
            else {
                appDelegate.makeToast("The password is inconsistent twice")
            }
        }
        else {
            if tf1.stringValue == tf2.stringValue {
                if tf2.stringValue.count >= 8 {
                    self.showProgressIndicator(false)
                    self.changePasswordWithpassword1(str1: JoDess.md5(tf1.stringValue), str2: JoDess.md5(tf2.stringValue))
                }
                else {
                    appDelegate.makeToast("Password at least 8 (including letters, numbers, underline)")
                }
            }
            else {
                appDelegate.makeToast("The password is inconsistent twice")
            }
        }
    }
    
    @objc func actionClickGesture(_ sender: Any) {
    }
    

    //MARK: - Method
    func showProgressIndicator(_ isStop: Bool) {
        bgProcessIndicator.isHidden = isStop;
        actIndicator.isHidden = isStop;
        actIndicator.isIndeterminate = true;
        actIndicator.usesThreadedAnimation = true;
        actIndicator.startAnimation(nil);
    }
    
    func changePasswordWithpassword1(str1: String, str2: String) {
        guard let url = URL(string: "\(PchFile.rootURL)/user_login/ChangePass.php") else {
            self.showProgressIndicator(true)
            return
        }
        
        let dict = ["uuid":UUIDHelper.getUUID(), "old_pass":str1, "new_pass":str2, "tag":"1"] as! [String:String]
        
        Alamofire.request(url,
                          method: .post,
                          parameters: dict)
            .validate()
            .responseData(completionHandler: { response in
                self.showProgressIndicator(true)
                let appDelegate: AppDelegate = NSApplication.shared.delegate as! AppDelegate
                
                guard response.result.isSuccess else {
                    appDelegate.makeToast("Failed to change password")
                    
                    return
                }
                
                let str = JoDess.decode(String(data: response.result.value!, encoding: String.Encoding.utf8), key: PchFile.keyDecode);
                let json: [String:Any]? = str?.convertToDictionary();
                
                if(json != nil  &&  json!["error_code"] != nil  &&  (json!["error_code"] as! Int) == 0) {
                    appDelegate.makeToast("password has been updated")
                    self.window?.close()
                }
                else {
                    appDelegate.makeToast("Failed to change password")
                }
            })
    }
}
