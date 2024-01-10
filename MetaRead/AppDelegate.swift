//
//  AppDelegate.swift
//  MetaRead
//
//  Created by Kven on 9/8/20.
//  Copyright © 2020 Kven. All rights reserved.
//

import Cocoa
import AVFoundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private let playlist: Playlist = Playlist.instance

    var dialog: NSOpenPanel = {
        
        let dialog = NSOpenPanel()
        
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = true
        
        dialog.canChooseDirectories    = true
        
        dialog.canCreateDirectories    = false
        dialog.allowsMultipleSelection = true
        
        dialog.resolvesAliases = true;
        
        dialog.directoryURL = URL(fileURLWithPath: NSHomeDirectory() + "/Music")
        
        return dialog
    }()

    
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var label: NSTextField!
    
    lazy var playlistVC: PlaylistVC = PlaylistVC()
    
    @IBAction func openAction(_ sender: Any) {
        
        if dialog.runModal() == NSApplication.ModalResponse.OK {
            
            clearAction(self)
            
            playlist.addFiles(dialog.urls)
            label.stringValue = dialog.urls.map {$0.path}.joined(separator: " | ")
        }
    }
    
    @IBAction func clearAction(_ sender: Any) {
        
        playlist.clear()
        label.stringValue = ""
        PlaylistVC.instance.clear()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
//        let regex = "[0-9]+:[0-9]+:[0-9]+[\\.]?[0-9]*"
//        print("\nMatches?: \("12:45:23.345345".matches(regex))")
//        print("\nMatches?: \("12:45:23".matches(regex))")
//        print("\nMatches?: \("09-12-1983".matches("[0-9]+-[0-9]+-[0-9]+"))")
//        print("\nDuration: \(ParserUtils.parseDuration("02:05:29.73838383") ?? -1)")
        openFilesLimit = 10000
        
        freopen(URL(fileURLWithPath: "/Volumes/MyData/Music/Aural-Test/metaRead.log").path.cString(using: String.Encoding.ascii)!, "a+", stderr)

        window.contentView?.addSubview(playlistVC.view)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

var openFilesLimit: UInt64 {
    
    get {
        var rl: rlimit = rlimit()
        getrlimit(RLIMIT_NOFILE, &rl)
        return rl.rlim_cur
    }
    
    set {
        var rl: rlimit = rlimit()
        rl.rlim_cur = newValue
        rl.rlim_max = newValue
        setrlimit(RLIMIT_NOFILE, &rl)
    }
}
