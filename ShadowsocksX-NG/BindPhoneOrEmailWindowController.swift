//
//  BindPhoneOrEmailWindowController.swift
//  ShadowsocksX-NG
//
//  Created by a on 10/10/18.
//  Copyright © 2018 qiuyuzhou. All rights reserved.
//
import Alamofire
import Cocoa

class BindPhoneOrEmailWindowController: NSWindowController, NSTextFieldDelegate {
    @IBOutlet var tfEmailOrPhoneNumber: NSTextField!
    @IBOutlet var tfVerificationCode: NSTextField!
    @IBOutlet var tfPassword: NSSecureTextField!
    @IBOutlet var btnConfirm: NSButton!
    @IBOutlet var btnVerificationCode: NSButton!
    @IBOutlet var bgProcessIndicator: NSView!
    @IBOutlet var actProcessIndicator: NSProgressIndicator!
    
    var nCountTimer = 60;
    var isBindingAction: Bool = false
    var timer: Timer?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        btnConfirm.isEnabled = false;
        
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
        nCountTimer = 60;
        btnVerificationCode.title = "\(nCountTimer)"
        btnVerificationCode.isEnabled = false;
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
    }
    
    @objc func updateCounter() {
        self.nCountTimer -= 1
        
        if(self.nCountTimer == 0) {
            self.btnVerificationCode.title = "Get Verification Code"
            self.btnVerificationCode.isEnabled = true;
            self.timer!.invalidate()
            self.timer = nil;
        }
        else {
            self.btnVerificationCode.title = "\(self.nCountTimer)"
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
                self.showProgressIndicator(true)
                
                guard response.result.isSuccess else {
                    appDelegate.makeToast("Binding Email/Phone failed!")
                    
                    return
                }
                
                
                let str = JoDess.decode(String(data: response.result.value!, encoding: String.Encoding.utf8), key: PchFile.keyDecode);
                let json: [String:Any]? = str?.convertToDictionary();


                if json != nil  &&  (json?.count)! > 0 {
                    if(json!["error_code"] != nil  &&  (json!["error_code"] as! Int) == 0) {
                        appDelegate.makeToast("Success")
                        
                        if(self.isBindingAction) {
                            self.window?.close()
                        }
                    }
                    else if(json!["error_code"] != nil  &&  (json!["error_code"] as! Int) == 10032) {
                        appDelegate.makeToast("The phone number or email is bound account")
                    }
                    else {
                        appDelegate.makeToast("Binding Failed")
                    }
                }
            })
    }
    
    func bindPhoneOrEmail() {
        if tfEmailOrPhoneNumber.stringValue.count > 0  &&  (isValidateEmail(email: tfEmailOrPhoneNumber.stringValue) || isValidateMobile(mobile: tfEmailOrPhoneNumber.stringValue))  {
            if(tfPassword.stringValue.count > 0) {
                self.showProgressIndicator(false)
                
                if tfEmailOrPhoneNumber.stringValue.contains("@") {
                    self.bindPhoneOrEmailWithParameters(dict: ["email":tfEmailOrPhoneNumber.stringValue, "emailcode":tfVerificationCode.stringValue, "uuid":UUIDHelper.getUUID(), "password":JoDess.md5(tfPassword.stringValue), "bundle_id":Bundle.main.bundleIdentifier!.replacingOccurrences(of: ".mac", with: "")], subURL: "/PHPMailer/ValidateCode.php")
                }
                else {
                    self.bindPhoneOrEmailWithParameters(dict: ["phone":tfEmailOrPhoneNumber.stringValue, "msgcode":tfVerificationCode.stringValue, "uuid":UUIDHelper.getUUID(), "password":JoDess.md5(tfPassword.stringValue), "bundle_id":Bundle.main.bundleIdentifier!.replacingOccurrences(of: ".mac", with: "")], subURL: "/phone_validate/ValidateCode.php")
                }
            }
            else {
                let appDelegate: AppDelegate = NSApplication.shared.delegate as! AppDelegate
                appDelegate.makeToast("Please set the account password")
            }
        }
    }
    
    
    
    //MARK: - Action
    @objc func actionClickGesture(_ sender: Any) {
    }
    
    @IBAction func actConfirm(_ sender: Any) {
        isBindingAction = true;
        self.bindPhoneOrEmail()
    }
    
    @IBAction func actVerificationCode(_ sender: Any) {
        isBindingAction = false;
        if tfEmailOrPhoneNumber.stringValue.count > 0  &&  (isValidateEmail(email: tfEmailOrPhoneNumber.stringValue) || isValidateMobile(mobile: tfEmailOrPhoneNumber.stringValue))  {
            self.showProgressIndicator(false)
            self.openCountDown()
            
            if(tfEmailOrPhoneNumber.stringValue.contains("@")) {
                self.bindPhoneOrEmailWithParameters(dict: ["email": tfEmailOrPhoneNumber.stringValue], subURL: "/PHPMailer/send.php")
            }
            else {
                self.bindPhoneOrEmailWithParameters(dict: ["phone": tfEmailOrPhoneNumber.stringValue], subURL: "/phone_validate/SendMsgPost.php")
            }
        }
    }
}



extension BindPhoneOrEmailWindowController {
    //MARK: - NSTextField Delegate
    override func controlTextDidChange(_ obj: Notification) {
        let tempTextField: NSTextField = obj.object as! NSTextField;
        
        if tfPassword.stringValue.count > 0  &&  tfEmailOrPhoneNumber.stringValue.count > 0  &&  tempTextField.stringValue.count > 2 {
            btnConfirm.isEnabled = true;
        }
        else  {
            btnConfirm.isEnabled = false;
        }
    }
}
