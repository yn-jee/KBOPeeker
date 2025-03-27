//
//  ApplicationMenu.swift
//  KBOPeeker
//
//  Created by 나윤지 on 3/21/25.
//
//

import Foundation
import SwiftUI

class ApplicationMenu: NSObject {
    let menu = NSMenu()
    private var settingsWindow: NSWindow?
    
    func createMenu() -> NSMenu {
        let mainView = ContentView(viewModel: SettingViewModel())
        let topView = NSHostingController(rootView: mainView)
        topView.view.frame.size = CGSize(width: 300, height: 120)
        
        let customMenuItem = NSMenuItem()
        customMenuItem.view = topView.view
        menu.addItem(customMenuItem)
        menu.addItem(NSMenuItem.separator())
        
        let aboutMenuItem = NSMenuItem(title: "KBOPeeker에 대하여",
                                       action: #selector(about),
                                       keyEquivalent: "")
        aboutMenuItem.target = self
        menu.addItem(aboutMenuItem)
        
        let settingsMenuItem = NSMenuItem(title: "설정",
                                       action: #selector(openSettings),
                                       keyEquivalent: "")
        settingsMenuItem.target = self
        menu.addItem(settingsMenuItem)
        
        let webLinkMenuItem = NSMenuItem(title: "중계 바로가기",
                                         action: #selector(openLink),
                                       keyEquivalent: "")
        webLinkMenuItem.target = self
        webLinkMenuItem.representedObject = UserDefaults.standard.string(forKey: "gameURL") ?? "https://sports.daum.net/schedule/kbo"
        menu.addItem(webLinkMenuItem)
        
        let quitMenuItem = NSMenuItem(title: "종료",
                                         action: #selector(quit),
                                       keyEquivalent: "q")
        quitMenuItem.target = self
        menu.addItem(quitMenuItem)
        
        return menu
    }
    
    @objc func about(sender: NSMenuItem) {
        NSApp.orderFrontStandardAboutPanel()
    }
    
    @objc func openSettings(sender: NSMenuItem) {
        if settingsWindow == nil {
            let contentView = SettingView(viewModel: SettingViewModel())
            let hostingController = NSHostingController(rootView: contentView)
            settingsWindow = NSWindow(contentRect: NSMakeRect(0, 0, 400, 500),
                                      styleMask: [.titled, .closable, .resizable],
                                      backing: .buffered,
                                      defer: false)
            settingsWindow?.contentView = hostingController.view
            settingsWindow?.title = "설정"
            settingsWindow?.level = .floating
            settingsWindow?.center()
            
            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: settingsWindow,
                queue: .main
            ) { [weak self] _ in
                self?.settingsWindow = nil
            }
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func openLink(sender: NSMenuItem) {
        let link = sender.representedObject as! String
        guard let url = URL(string: link) else { return }
        NSWorkspace.shared.open(url)
    }
    
    @objc func quit(sender: NSMenuItem) {
        NSApp.terminate(self)
    }
}
