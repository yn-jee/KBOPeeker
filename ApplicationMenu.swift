//
//  ApplicationMenu.swift
//  KBOPeeker
//
//  Created by 나윤지 on 3/21/25.
//
//

import Foundation
import SwiftUI

class EventModel: ObservableObject {
    static let shared = EventModel()
    @Published var latestEvent: String = ""
}

class ApplicationMenu: NSObject {
    static let shared = ApplicationMenu()
    var scoreboardSubmenu: NSMenu?
    
    let menu = NSMenu()
    private var settingsWindow: NSWindow?
    @ObservedObject var gameState = GameStateModel.shared
    private let fetcher = GameIDFetcher()
    
    func createMenu() -> NSMenu {
        let mainView = ContentView(viewModel: SettingViewModel.shared)
            .environmentObject(EventModel.shared)
        let topView = NSHostingController(rootView: mainView)
        topView.view.frame.size = CGSize(width: 300, height: 160)
        
        let customMenuItem = NSMenuItem()
        customMenuItem.view = topView.view
        menu.addItem(customMenuItem)
        menu.addItem(NSMenuItem.separator())
        
        let getGameIDItem = NSMenuItem(title: "경기 찾기",
                                       action: #selector(getGameID),
                                       keyEquivalent: "")
        getGameIDItem.target = self
        menu.addItem(getGameIDItem)
        
        
        let webLinkMenuItem = NSMenuItem(title: "중계 바로가기",
                                         action: #selector(openLink),
                                       keyEquivalent: "")
        webLinkMenuItem.target = self
        webLinkMenuItem.representedObject = UserDefaults.standard.string(forKey: "gameURL") ?? "https://sports.daum.net/schedule/kbo"
        menu.addItem(webLinkMenuItem)
        
        let scoreboardMenuItem = NSMenuItem(title: "스코어보드",
                                            action: nil,
                                            keyEquivalent: "")
        scoreboardMenuItem.target = self
        let scoreboardSubmenu = NSMenu(title: "스코어보드")
        self.scoreboardSubmenu = scoreboardSubmenu
        scoreboardMenuItem.submenu = scoreboardSubmenu
        scoreboardMenuItem.representedObject = "https://sports.daum.net/schedule/kbo"
        menu.addItem(scoreboardMenuItem)

        updateScoreboardMenu(scoreboardSubmenu)
        
        let settingsMenuItem = NSMenuItem(title: "설정",
                                       action: #selector(openSettings),
                                       keyEquivalent: "")
        settingsMenuItem.target = self
        menu.addItem(settingsMenuItem)
        
        let quitMenuItem = NSMenuItem(title: "종료",
                                         action: #selector(quit),
                                       keyEquivalent: "q")
        quitMenuItem.target = self
        menu.addItem(quitMenuItem)
        
        return menu
    }
    
    func updateScoreboardMenu(_ menu: NSMenu) {
        print("🟡 updateScoreboardMenu 호출됨")
        fetcher.fetchScoreboard { lines in
            print("🟢 fetchScoreboard completion 호출됨. lines count: \(lines.count)")
            DispatchQueue.main.async {
                print("🔵 DispatchQueue.main 안으로 진입")
                menu.removeAllItems()
                for line in lines {
                    print("⚪️ 처리 중인 라인: \(line)")
                    let parts = line.components(separatedBy: "|")
                    if parts.count == 5 {
                        let away = parts[0]
                        let scoreAway = parts[1]
                        let scoreHome = parts[2]
                        let home = parts[3]
                        let state = parts[4]

                        let title = "\(away) \(scoreAway) : \(scoreHome) \(home)"

                        let item = NSMenuItem()
                        let stack = NSStackView()
                        stack.translatesAutoresizingMaskIntoConstraints = false
                        stack.setContentHuggingPriority(.defaultLow, for: .horizontal)
                        stack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                        stack.orientation = .horizontal
                        stack.spacing = 6
                        stack.alignment = .centerY

                        if let awayLogo = NSImage(named: away) {
                            let imageView = NSImageView(image: awayLogo)
                            imageView.translatesAutoresizingMaskIntoConstraints = false
                            imageView.widthAnchor.constraint(equalToConstant: 15).isActive = true
                            imageView.heightAnchor.constraint(equalToConstant: 15).isActive = true
                            imageView.setContentHuggingPriority(.required, for: .horizontal)
                            imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
                            stack.addArrangedSubview(imageView)
                        }

                        let label = NSTextField(labelWithString: title)
                        label.alignment = .center
                        stack.addArrangedSubview(label)

                        if let homeLogo = NSImage(named: home) {
                            let imageView = NSImageView(image: homeLogo)
                            imageView.translatesAutoresizingMaskIntoConstraints = false
                            imageView.widthAnchor.constraint(equalToConstant: 15).isActive = true
                            imageView.heightAnchor.constraint(equalToConstant: 15).isActive = true
                            imageView.setContentHuggingPriority(.required, for: .horizontal)
                            imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
                            stack.addArrangedSubview(imageView)
                        }

                        let containerStack = NSStackView()
                        containerStack.orientation = .vertical
                        containerStack.alignment = .centerX
                        containerStack.translatesAutoresizingMaskIntoConstraints = false
                        containerStack.edgeInsets = NSEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
                        containerStack.addArrangedSubview(stack)

                        let borderedView = NSView()
                        borderedView.wantsLayer = true
                        borderedView.translatesAutoresizingMaskIntoConstraints = false

                        borderedView.addSubview(containerStack)
                        containerStack.leadingAnchor.constraint(equalTo: borderedView.leadingAnchor).isActive = true
                        containerStack.trailingAnchor.constraint(equalTo: borderedView.trailingAnchor).isActive = true
                        containerStack.topAnchor.constraint(equalTo: borderedView.topAnchor).isActive = true
                        containerStack.bottomAnchor.constraint(equalTo: borderedView.bottomAnchor).isActive = true
                        borderedView.widthAnchor.constraint(greaterThanOrEqualToConstant: 145).isActive = true

                        borderedView.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(self.openScoreboardLink)))
                        item.view = borderedView
                        menu.addItem(item)
                    } else {
                        print("🔴 형식이 맞지 않는 라인: \(line)")
                        menu.addItem(NSMenuItem(title: line, action: nil, keyEquivalent: ""))
                    }
                }
            }
        }
    }
    
    @objc func getGameID(sender: NSMenuItem) {
        gameState.isFetchingGame = true
        AppDelegate.instance?.startTracking()
    }
    
    @objc func openSettings(sender: NSMenuItem) {
        if settingsWindow == nil {
            let contentView = SettingView(viewModel: SettingViewModel.shared)
            let hostingController = NSHostingController(rootView: contentView)

            // 창 크기 설정
            let windowWidth: CGFloat = 470
            let windowHeight: CGFloat = 500

            // 메인 스크린의 가시 프레임 가져오기
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame

                // 우측 상단 좌표 계산
                let originX = screenFrame.maxX - windowWidth - 50
                let originY = screenFrame.maxY - windowHeight - 50

                // 창 생성 및 위치 설정
                settingsWindow = NSWindow(
                    contentRect: NSRect(x: originX, y: originY, width: windowWidth, height: windowHeight),
                    styleMask: [.titled, .closable, .resizable],
                    backing: .buffered,
                    defer: false
                )
                settingsWindow?.contentView = hostingController.view
                settingsWindow?.title = "설정"
                settingsWindow?.level = .floating
                settingsWindow?.isReleasedWhenClosed = false

                // 창이 닫힐 때 참조 해제
                NotificationCenter.default.addObserver(
                    forName: NSWindow.willCloseNotification,
                    object: settingsWindow,
                    queue: .main
                ) { [weak self] _ in
                    self?.settingsWindow = nil
                }
            }
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func openLink(sender: NSMenuItem) {
        let link = AppDelegate.instance?.gameURL ?? "https://sports.daum.net/schedule/kbo"
        guard let url = URL(string: link) else { return }
        NSWorkspace.shared.open(url)
    }
    
    @objc func quit(sender: NSMenuItem) {
        NSApp.terminate(self)
    }
    
    @objc func openScoreboardLink() {
        guard let url = URL(string: "https://sports.daum.net/schedule/kbo") else { return }
        NSWorkspace.shared.open(url)
    }
}
