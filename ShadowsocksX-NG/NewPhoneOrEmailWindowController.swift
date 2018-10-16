//
//  NewPhoneOrEmailWindowController.swift
//  ShadowsocksX-NG
//
//  Created by a on 10/10/18.
//  Copyright © 2018 qiuyuzhou. All rights reserved.
//
import Alamofire
import Cocoa

class NewPhoneOrEmailWindowController: NSWindowController {
    @IBOutlet var tfPhoneOrEmail: NSTextField!
    @IBOutlet var tfVerificationCode: NSTextField!
    @IBOutlet var btnSubmit: NSButton!
    @IBOutlet var btnSendCode: NSButton!
    @IBOutlet var bgProcessIndicator: NSView!
    @IBOutlet var actProcessIndicator: NSProgressIndicator!
    
    var nCountTimer: Int = 60;
    var timer: Timer?
    var isClick: Bool = false
    
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
        if isValidateEmail(email: tfPhoneOrEmail.stringValue) || isValidateMobile(mobile: tfPhoneOrEmail.stringValue) {
            self.openCountDown()
            self.showProgressIndicator(false)
            
            if tfPhoneOrEmail.stringValue.contains("@") {
                self.bindPhoneOrEmailWithParameters(dict: ["email":tfPhoneOrEmail.stringValue], subURL: "/PHPMailer/send.php")
            }
            else {
                self.bindPhoneOrEmailWithParameters(dict: ["phone":tfPhoneOrEmail.stringValue], subURL: "/phone_validate/SendMsgPost.php")
            }
        }
    }
    
    @IBAction func actSubmit(_ sender: Any) {
        isClick = true;
        
        if isValidateEmail(email: tfPhoneOrEmail.stringValue) || isValidateMobile(mobile: tfPhoneOrEmail.stringValue) {
            self.showProgressIndicator(false)
            
            if tfPhoneOrEmail.stringValue.contains("@") {
                self.bindPhoneOrEmailWithParameters(dict: ["email":tfPhoneOrEmail.stringValue, "emailcode":tfVerificationCode.stringValue, "uuid":UUIDHelper.getUUID(), "bundle_id":Bundle.main.bundleIdentifier!.replacingOccurrences(of: ".mac", with: "")], subURL: "/PHPMailer/ValidateCode.php")
            }
            else {
                self.bindPhoneOrEmailWithParameters(dict: ["phone":tfPhoneOrEmail.stringValue, "msgcode":tfVerificationCode.stringValue, "uuid":UUIDHelper.getUUID(), "bundle_id":Bundle.main.bundleIdentifier!.replacingOccurrences(of: ".mac", with: "")], subURL: "/PHPMailer/ValidateCode.php")
            }
        }
    }
}
