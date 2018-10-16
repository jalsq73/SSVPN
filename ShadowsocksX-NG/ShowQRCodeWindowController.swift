//
//  ShowQRCodeWindowController.swift
//  ShadowsocksX-NG
//
//  Created by a on 11/10/18.
//  Copyright © 2018 qiuyuzhou. All rights reserved.
//

import Cocoa

class ShowQRCodeWindowController: NSWindowController {
    var qrImage: NSImage!
    @IBOutlet var imgView: NSImageView!
    
    override func windowDidLoad() {
        super.windowDidLoad()

        imgView.image = qrImage
    }
}
