//
//  PurchaseHistoryWindowController.swift
//  ShadowsocksX-NG
//
//  Created by a on 10/10/18.
//  Copyright © 2018 qiuyuzhou. All rights reserved.
//
import Alamofire
import Cocoa

class PurchaseHistoryWindowController: NSWindowController {
    @IBOutlet var actIndicator: NSProgressIndicator!
    @IBOutlet var bgProcessIndicator: NSView!
    @IBOutlet var tableView: NSTableView!
    var arrData: [PackageModel] = [PackageModel]()
    
    override func windowDidLoad() {
        super.windowDidLoad()

        bgProcessIndicator.wantsLayer = true
        bgProcessIndicator.layer?.backgroundColor = NSColor.lightGray.withAlphaComponent(0.5).cgColor;
        bgProcessIndicator.addGestureRecognizer(NSClickGestureRecognizer.init(target: self, action: #selector(actionClickGesture(_:))))
        bgProcessIndicator.addGestureRecognizer(NSPressGestureRecognizer.init(target: self, action: #selector(actionClickGesture(_:))))
        bgProcessIndicator.addGestureRecognizer(NSPanGestureRecognizer.init(target: self, action: #selector(actionClickGesture(_:))))
        
        showProgressIndicator(false)
        getPurchaseHistory()
    }
    
    
    //MARK: - Method
    func getPurchaseHistory() {
        guard let url = URL(string: "\(PchFile.rootURL)/user_order/PurchaseHistory.php") else {
            self.showProgressIndicator(true)
            return
        }
        
        let dict: [String:Any] = ["uuid": UUIDHelper.getUUID()!];
        Alamofire.request(url,
                          method: .post,
                          parameters: dict)
            .validate()
            .responseData(completionHandler: { response in
                self.showProgressIndicator(true)
                guard response.result.isSuccess else {
                    return
                }
                
                let str = JoDess.decode(String(data: response.result.value!, encoding: String.Encoding.utf8), key: PchFile.keyDecode);
                let json: [String:Any]? = str?.convertToDictionary();
                
                if(json != nil  &&  json!["error_code"] != nil  &&  (json!["error_code"] as! Int) == 0) {
                    guard let dict = json!["data"] else {
                        return;
                    }
                    
                    if((dict as? [[String:Any]]) != nil) {
                        for tempDict in (dict as! [[String:Any]]) {
                            let packageModel: PackageModel = PackageModel()
                            packageModel.goodsID = tempDict["goods_id"] as? String
                            packageModel.goodsName = tempDict["goods_name"] as? String
                            packageModel.orderNum = tempDict["order_num"] as? String
                            packageModel.createdTime = Int32(tempDict["create_time"] as! String)
                            
                            self.arrData.append(packageModel)
                            self.tableView.reloadData()
                        }
                    }
                }
            })
    }
    
    func showProgressIndicator(_ isStop: Bool) {
        bgProcessIndicator.isHidden = isStop;
        actIndicator.isHidden = isStop;
        actIndicator.isIndeterminate = true;
        actIndicator.usesThreadedAnimation = true;
        actIndicator.startAnimation(nil);
    }
    
    //MARK: - Action
    @objc func actionClickGesture(_ sender: Any) {
    }
}

extension PurchaseHistoryWindowController: NSTableViewDelegate, NSTableViewDataSource {
    //MARK: - NSTableView Delegate and Datasource
    func numberOfRows(in tableView: NSTableView) -> Int {
        return arrData.count
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        tableView.deselectRow(tableView.selectedRow);
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item: PackageModel = arrData[row];
        let cell: NSTableCellView!;
        
        if(tableColumn == tableView.tableColumns[0]) {
            cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "goodsName"), owner: nil) as? NSTableCellView
            cell.textField?.stringValue = item.goodsName!
        }
        else {
            let dateFormat: DateFormatter = DateFormatter()
            dateFormat.dateFormat = "dd-MM-yyyy HH:mm:ss"
            cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "createdTime"), owner: nil) as? NSTableCellView
            
            cell.textField?.stringValue = dateFormat.string(from: Date(timeIntervalSince1970: TimeInterval(item.createdTime!)));
        }
        
        return cell
    }
}
