//
//  ChangePhoneNumberWindowController.swift
//  ShadowsocksX-NG
//
//  Created by a on 10/10/18.
//  Copyright © 2018 qiuyuzhou. All rights reserved.
//
import Alamofire
import Cocoa

class ChangePhoneNumberWindowController: NSWindowController, NSTextFieldDelegate {
    var userModel: UserModel?;
    var timer: Timer?
    var nCountTimer: Int = 60
    var isClick: Bool = false
    
    @IBOutlet var bgProcessIndicator: NSView!
    @IBOutlet var actProcessIndicator: NSProgressIndicator!
    @IBOutlet var btnSendCode: NSButton!
    @IBOutlet var btnConfirm: NSButton!
    @IBOutlet var tfPhoneOrEmail: NSTextField!
    @IBOutlet var tfVerificationCode: NSTextField!
    
    override func windowDidLoad() {
        super.windowDidLoad()

        bgProcessIndicator.wantsLayer = true
        bgProcessIndicator.layer?.backgroundColor = NSColor.lightGray.withAlphaComponent(0.5).cgColor;
        bgProcessIndicator.addGestureRecognizer(NSClickGestureRecognizer.init(target: self, action: #selector(actionClickGesture(_:))))
        bgProcessIndicator.addGestureRecognizer(NSPressGestureRecognizer.init(target: self, action: #selector(actionClickGesture(_:))))
        bgProcessIndicator.addGestureRecognizer(NSPanGestureRecognizer.init(target: self, action: #selector(actionClickGesture(_:))))
    }
    
    
    //MARK: - Method
    func showProgressIndicator(_ isStop: Bool) {
        bgProcessIndicator.isHidden = isStop;
        actProcessIndicator.isIndeterminate = true;
        actProcessIndicator.usesThreadedAnimation = true;
        actProcessIndicator.startAnimation(nil);
    }
    
    func isValidateEmail(email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
        let emailTest: NSPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        return emailTest.evaluate(with: email)
    }
    
    func isValidateMobile(mobile: String) -> Bool {
        let phoneRegex = "^1(3[0-9]|4[57]|5[0-35-9]|8[0-9]|7[0678])\\d{8}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        
        return phoneTest.evaluate(with: mobile)
    }
    
    func openCountDown() {
        nCountTimer = 60
        btnSendCode.title = "\(nCountTimer)"
        btnSendCode.isEnabled = false;
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
    }
    
    @objc func updateCounter() {
        self.nCountTimer -= 1
        
        if(self.nCountTimer == 0) {
            self.btnSendCode.title = "Send Code"
            self.btnSendCode.isEnabled = true;
            self.timer!.invalidate()
            self.timer = nil;
        }
        else {
            self.btnSendCode.title = "\(self.nCountTimer)"
        }
    }
    
    
    func bindPhoneOrEmailWithParameters(dict: [String:Any], subURL: String) {
        guard let url = URL(string: "\(PchFile.rootURL)\(subURL)") else {
            self.showProgressIndicator(true)
            return
        }
        
        Alamofire.request(url,
                          method: .post,
                          parameters: dict)
            .validate()
            .responseData(completionHandler: { response in
                let appDelegate: AppDelegate = NSApplication.shared.delegate as! AppDelegate
                
                guard response.result.isSuccess else {
                    appDelegate.makeToast("Failure")
                    self.isClick = false;
                    self.showProgressIndicator(true)
                    
                    return
                }
                
                
                let str = JoDess.decode(String(data: response.result.value!, encoding: String.Encoding.utf8), key: PchFile.keyDecode);
                let json: [String:Any]? = str?.convertToDictionary();
                
                
                if json != nil  &&  (json?.count)! > 0 {
                    if(json!["error_code"] != nil  &&  (json!["error_code"] as! Int) == 0) {
                        appDelegate.makeToast("Success")
                        
                        if self.isClick {
                            appDelegate.showNewPhoneOrEmail()
                            self.window?.close()
                        }
                    }
                    else {
                        appDelegate.makeToast("Failure")
                    }
                }
                
                self.showProgressIndicator(true)
                self.isClick = false;
            })
    }
    
    
    
    
    //MARK: - Action
    @objc func actionClickGesture(_ sender: Any) {
    }
    
    @IBAction func actSendCode(_ sender: Any) {
        let appDelegate: AppDelegate = NSApplication.shared.delegate as! AppDelegate
        
        if(isValidateEmail(email: tfPhoneOrEmail.stringValue) || isValidateMobile(mobile: tfPhoneOrEmail.stringValue)) {
            if tfPhoneOrEmail.stringValue == self.userModel?.phone! {
                self.openCountDown()
                self.showProgressIndicator(false)
                
                if tfPhoneOrEmail.stringValue.contains("@") {
                    self.bindPhoneOrEmailWithParameters(dict: ["email":tfPhoneOrEmail.stringValue], subURL: "/PHPMailer/send.php")
                }
                else {
                    self.bindPhoneOrEmailWithParameters(dict: ["phone":tfPhoneOrEmail.stringValue], subURL: "/phone_validate/SendMsgPost.php")
                }
            }
            else {
                appDelegate.makeToast("The phone number or email you entered is different from the original one")
            }
        }
        else {
            appDelegate.makeToast("Phone number or email format error")
        }
    }
    
    
    @IBAction func actConfirm(_ sender: Any) {
        isClick = true;

        if isValidateEmail(email: tfPhoneOrEmail.stringValue) || isValidateMobile(mobile: tfPhoneOrEmail.stringValue) {
            self.showProgressIndicator(false)
            
            if tfPhoneOrEmail.stringValue.contains("@") {
                self.bindPhoneOrEmailWithParameters(dict: ["email":tfPhoneOrEmail.stringValue, "emailcode":tfVerificationCode.stringValue, "uuid":UUIDHelper.getUUID(), "bundle_id":Bundle.main.bundleIdentifier!.replacingOccurrences(of: ".mac", with: "")], subURL: "/PHPMailer/ValidateCode.php")
            }
            else {
                self.bindPhoneOrEmailWithParameters(dict: ["phone":tfPhoneOrEmail.stringValue, "msgcode":tfVerificationCode.stringValue, "uuid":UUIDHelper.getUUID(), "bundle_id":Bundle.main.bundleIdentifier!.replacingOccurrences(of: ".mac", with: "")], subURL: "/phone_validate/ValidateCode.php")
            }
        }
    }
}

extension ChangePhoneNumberWindowController {
    //MARK: - NSTextField Delegate
    override func controlTextDidChange(_ obj: Notification) {
        let tempTextField: NSTextField = obj.object as! NSTextField;
        
        if tfPhoneOrEmail.stringValue.count > 0  &&  tempTextField.stringValue.count > 2 {
            btnConfirm.isEnabled = true;
        }
        else  {
            btnConfirm.isEnabled = false;
        }
    }
}
