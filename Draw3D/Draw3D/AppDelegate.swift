//
//  AppDelegate.swift
//  Draw3D
//
//  Created by Kven on 9/19/20.
//  Copyright © 2020 Kven. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var skView: SKView!

    @IBAction func beatAction(_ sender: Any) {
        skView.beat()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

