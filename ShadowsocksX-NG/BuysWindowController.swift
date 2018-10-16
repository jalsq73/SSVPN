//
//  BuysWindowController.swift
//  ShadowsocksX-NG
//
//  Created by a on 03/10/18.
//  Copyright © 2018 qiuyuzhou. All rights reserved.
//
import Alamofire
import Cocoa
import StoreKit

class BuysWindowController: NSWindowController {
    var itemList: [Any]?
    var productID: String?;
    var userModel: UserModel?
    
    @IBOutlet var table: NSTableView!
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
        
        
        
        initPay()
        showProgressIndicator(false)
        self.getProducts();
    }
    
    
    //MARK: - Method
    func showProgressIndicator(_ isStop: Bool) {
        bgProcessIndicator.isHidden = isStop;
        actIndicator.isHidden = isStop;
        actIndicator.isIndeterminate = true;
        actIndicator.usesThreadedAnimation = true;
        actIndicator.startAnimation(nil);
    }
    
    @objc func actionClickGesture(_ sender: Any) {
    }
    
    @objc func actionSelect(_ sender: NSButton) {
        table.isEnabled = false;
        
        let item = itemList![sender.tag] as! [String : Any];
        self.buy(item["goods_id"] as! String);
    }
    
    func getProducts() {
        guard let url = URL(string: "\(PchFile.rootURL)/goods_info/GoodsInfo.php") else {
            self.showProgressIndicator(true)
            return
        }
        let bundleIdentifier: String = Bundle.main.bundleIdentifier!
        
        Alamofire.request(url,
                          method: .post,
                          parameters: ["bundle_id": bundleIdentifier])
            .validate()
            .responseData(completionHandler: { response in
                self.showProgressIndicator(true)
                guard response.result.isSuccess else {
                    return
                }
                
                let str = JoDess.decode(String(data: response.result.value!, encoding: String.Encoding.utf8), key: PchFile.keyDecode);
                let json: [String:Any]? = str?.convertToDictionary();
                
                
                if (json?.count)! > 0 {
                    guard let data = json?["data"] as? [String : Any],
                        let subItemList = data["items_list"] as? [Any] else {
                        return
                    }
                    
                    self.itemList = subItemList;
                    self.table.reloadData()
                }
            })
    }
}

extension BuysWindowController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard let items = itemList else {
            return 0
        }

        return items.count;
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        table.deselectRow(table.selectedRow);
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 40;
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = itemList![row] as! [String : Any];
        let cell: NSTableCellView!;
        
        if(tableColumn == tableView.tableColumns[0]) {
            cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "goodsName"), owner: nil) as? NSTableCellView
            cell.textField?.stringValue = item["goods_name"] as! String
        }
        else if(tableColumn == tableView.tableColumns[1]){//Type
            cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "price"), owner: nil) as? NSTableCellView
            let strPrice = item["promotion_price"] as! String;
            cell.textField?.stringValue = "\(Int(Double(strPrice)!)) 元";
        }
        else {
            cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "selectID"), owner: nil) as? NSTableCellView
            
            let btnSelect: NSButton = cell.subviews.first as! NSButton;
            btnSelect.tag = row;
            btnSelect.action = #selector(actionSelect(_:))
        }
        
        return cell
    }
}

extension BuysWindowController: SKPaymentTransactionObserver, SKProductsRequestDelegate {
    func initPay() {
        SKPaymentQueue.default().add(self);
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    //MARK: - Method
    func buy(_ itemID: String) {
        if(itemList==nil && itemList?.count==0) {
            return;
        }
        
        self.showProgressIndicator(false)
        productID = itemID;
        let set: NSSet = NSSet(object: itemID)
        let projectRequest: SKProductsRequest = SKProductsRequest(productIdentifiers: set as! Set<String>);
        projectRequest.delegate = self;
        projectRequest.start()
    }

    
    func completeTransaction(_ baseString: String, _ transaction: SKPaymentTransaction) {
        let UUID = UUIDHelper.getUUID();
        let bundleID = Bundle.main.bundleIdentifier!;
        
        var dic = [String : String]();
        dic["receipt"] = baseString;
        dic["goods_id"] = self.productID;
        dic["uuid"] = UUID;
        dic["bundle_id"] = bundleID;
        
        
        let strUrlPay = "\(PchFile.rootURL)/user_order/UserOrder.php";
        Alamofire.request(URL(string: strUrlPay)!,
                          method: .post,
                          parameters: dic)
            .validate()
            .responseData(completionHandler: { response in
                self.showProgressIndicator(true)
                
                guard response.result.isSuccess else {
                    SKPaymentQueue.default().finishTransaction(transaction)
                    
                    return
                }
                
                let str = JoDess.decode(String(data: response.result.value!, encoding: String.Encoding.utf8), key: PchFile.keyDecode);
                let json: [String:Any]? = str?.convertToDictionary();

                if(json != nil  &&
                    (json?["error_code"] as? Int) != nil  &&
                    (json?["error_code"] as! Int) == 0) {
                    if(json?["data"] != nil  &&
                        ((json!["data"] as! [String : Any])["order_state"] as? Int) != nil  &&
                        ((json!["data"] as! [String : Any])["order_state"] as! Int) == 1) {
                        self.showAlert("Successful")
                        
                        SKPaymentQueue.default().finishTransaction(transaction)
                        let token = (json!["data"] as! [String : Any])["token"] as? String;
                        
                        let appDelegate: AppDelegate = NSApplication.shared.delegate as! AppDelegate
                        appDelegate.userCountActiveWithUUID(uuid: UUIDHelper.getUUID(), bundleID: Bundle.main.bundleIdentifier!.replacingOccurrences(of: ".mac", with: ""), token: token)
                        
                        if(token != nil && token!.count > 0) {
                            KeyChainStore.save("com.company.app.token", data: (json!["data"] as! [String : Any])["token"])
                        }
                        
                        
                        if(self.userModel == nil  ||  (self.userModel != nil  &&  self.userModel!.phone == nil)) {
                            let alert = NSAlert();
                            alert.alertStyle = .informational;
                            alert.messageText = "For your account's security and convenience to retrieve your account or password, please bind the mailbox or phone number";
                            alert.addButton(withTitle: "Cancel")
                            alert.addButton(withTitle: "Ok")
                            alert.beginSheetModal(for: self.window!, completionHandler: {
                                (modalResponse) -> Void in
                                switch modalResponse {
                                case NSApplication.ModalResponse.alertSecondButtonReturn:
                                    appDelegate.showBindPhoneOrEmailWindowsController()
                                    self.window?.close()
                                default:
                                    self.window?.close()
                                }
                            })
                        }
                        else {
                            self.window?.close()
                        }
                    }
                    else {
                        SKPaymentQueue.default().finishTransaction(transaction)
                        self.showAlert("Failed purchase");
                    }
                }
            })
    }
    

    //MARK: SKProduct
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach({ paymentTransaction in
            if(Bundle.main.appStoreReceiptURL != nil) {
                let transactionReceipt = try? Data(contentsOf: Bundle.main.appStoreReceiptURL!).base64EncodedString(options: NSData.Base64EncodingOptions.endLineWithCarriageReturn)
                
                guard let tempTransactionReceipt = transactionReceipt else {
                    return;
                }
                
                
                
                var base64: String = JoDess.encodeBase64(with: tempTransactionReceipt);
                base64 = base64.replacingOccurrences(of: "\n", with: "")
                base64 = base64.replacingOccurrences(of: "\r", with: "")
                base64 = base64.replacingOccurrences(of: "+", with: "%2B")
                
                
                DispatchQueue.main.async {
                    switch(paymentTransaction.transactionState) {
                    case .purchased:
                        self.completeTransaction(base64, paymentTransaction)
                        SKPaymentQueue.default().finishTransaction(paymentTransaction)
                    case .purchasing:
                        break;
                    case .restored:
                        SKPaymentQueue.default().finishTransaction(paymentTransaction);
                    case .failed:
                        SKPaymentQueue.default().finishTransaction(paymentTransaction)
                        self.showProgressIndicator(true);
                        self.showAlert("Failed purchase")
                    default:
                        break;
                    }
                }
            }
        })
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            if(response.products.count < 1) {
                self.showProgressIndicator(true)
                self.showAlert("Can not continue to pay")
                
                return;
            }
            
            let skPayment: SKPayment = SKPayment(product: response.products[0])
            SKPaymentQueue.default().add(skPayment)
        }
    }
    
    
    func showAlert(_ message: String) {
//        let alert = NSAlert();
//        alert.alertStyle = .critical;
//        alert.messageText = message;
//        alert.beginSheetModal(for: self.window!, completionHandler: nil)
        let appDelegate: AppDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.makeToast(message)
    }
}
