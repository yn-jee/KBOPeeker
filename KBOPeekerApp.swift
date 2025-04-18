//
//  KBOPeekerApp.swift
//  KBOPeeker
//
//  Created by 나윤지 on 3/21/25.
//

import SwiftUI

@main
struct KBOPeekerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    static var instance: AppDelegate!
    lazy var statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var menu: ApplicationMenu!
    var fetcher: GameIDFetcher?
    var crawler: KBOCrawler?
    var viewModel: SettingViewModel = SettingViewModel.shared
    var gameId: Int?
    var gameURL: String?
    var hasExceededMaxAttempts: Bool = false
    var isGameActive: Bool = false
    var teamJustChanged: Bool = true
    var isAnimatingEvent: Bool = false
    var lastEventText: String? = nil
    var lastTrackingStartTime: Date?
    var retryTimer: Timer?
    var scoreboardTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.instance = self
        GameStateModel.shared.isFetchingGame = true
        
        AppDelegate.instance?.updateStatusBarWithBaseballIcon()
        self.menu = ApplicationMenu.shared
        statusBarItem.menu = self.menu.createMenu()

        print("초기 설정값 로드:")
        print("Team: \(UserDefaults.standard.string(forKey: "selectedTeam") ?? "")")
        print("경기 시작: \(UserDefaults.standard.bool(forKey: "trackGameStarted"))")
        print("경기 종료: \(UserDefaults.standard.bool(forKey: "trackGameFinished"))")
        print("안타: \(UserDefaults.standard.bool(forKey: "trackHit"))")
        print("홈런: \(UserDefaults.standard.bool(forKey: "trackHomeRun"))")
        print("득점: \(UserDefaults.standard.bool(forKey: "trackScore"))")
        print("아웃: \(UserDefaults.standard.bool(forKey: "trackOut"))")
        print("실점: \(UserDefaults.standard.bool(forKey: "trackPointLoss"))")

        
        // ✅ 옵저버 등록
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePreferencesSaved),
            name: Notification.Name("PreferencesSaved"),
            object: nil
        )

        startTracking()
        startRetryTimer()
        startScoreboardTimer()
    }

    @objc func handlePreferencesSaved() {
        print("📣 PreferencesSaved notification received")
        self.teamJustChanged = true
        
        GameStateModel.shared.isFetchingGame = true
        GameStateModel.shared.isCancelled = false
        
        let gameState = GameStateModel.shared
        gameState.isFetchingGame = true
        gameState.isCancelled = false
        gameState.selectedTeamName = ""
        gameState.opponentTeamName = ""
        gameState.stadiumName = ""
        gameState.currentInning = ""
        gameState.isHome = false
        gameState.isTopInning = true
        gameState.inningNumber = 0
        gameState.ballCount = 0
        gameState.strikeCount = 0
        gameState.outCount = 0
        gameState.isFirstBaseOccupied = false
        gameState.isSecondBaseOccupied = false
        gameState.isThirdBaseOccupied = false
        gameState.teamScores = [:]
        
        startTracking()
    }

    func startTracking() {
        self.gameURL = nil
        GameStateModel.shared.isFetchingGame = true
        GameStateModel.shared.isCancelled = false
        GameStateModel.shared.noGame = false
        
        // 기존 크롤러 종료
        self.crawler?.stop()
        self.crawler = nil
        
        guard let button = self.statusBarItem.button else { return }
        
        AppDelegate.instance?.updateStatusBarWithBaseballIcon()
        
        fetcher = GameIDFetcher()
        let selectedTeam = UserDefaults.standard.string(forKey: "selectedTeam") ?? ""
        print(selectedTeam)

        var attempt = 0
        let maxAttempts = 5
        self.hasExceededMaxAttempts = false

        func tryFetchGameId() {
            GameStateModel.shared.isFetchingGame = true
            
            attempt += 1
            if GameStateModel.shared.noGame {
                print("✅ noGame 플래그가 설정되어 있으므로 재시도 중단")
                GameStateModel.shared.isFetchingGame = false
                return
            }
            print("[시도 \(attempt)] 경기 ID를 검색 중...")

            if let fetcher = self.fetcher, fetcher.isCancelled {
                print("⛔️ 경기취소 감지됨 — 재시도 중단")
                GameStateModel.shared.isFetchingGame = false
                return
            }
            
            fetcher?.getGameId(for: selectedTeam) { gameId in
                if let gameId = gameId {
                    self.gameId = gameId
                    let gameURL = "https://sports.daum.net/match/\(gameId)"
                    self.gameURL = gameURL
                    print("경기 URL: \(gameURL)")

                    self.crawler = KBOCrawler(gameURL: gameURL)
                    self.crawler?.onEventDetected = { [weak self] eventText in
                        // Removed redundant check:
                        // let now = Date()
                        // if let startTime = self?.lastTrackingStartTime, now.timeIntervalSince(startTime) < 3 {
                        //     print("⏱️ 크롤링 시작 후 3초 이내 감지된 이벤트 무시: \(eventText)")
                        //     return
                        // }
                        guard let self = self else { return }
//                        self.lastTrackingStartTime = Date()
                    
                        var displayText = "KBO 이벤트"
                        
                        let priorityOrder = ["홈런", "득점", "루타", "볼넷", "몸에 맞는 볼", "아웃"]
                        if let last = self.lastEventText {
                            let lastPriority = priorityOrder.firstIndex(where: { last.contains($0) }) ?? Int.max
                            let newPriority = priorityOrder.firstIndex(where: { eventText.contains($0) }) ?? Int.max
                            
//                            if eventText == self.lastEventText {
//                                print("⚠️ 이전 이벤트와 동일하므로 무시됨: \(eventText)")
//                                return
//                            }
////
//                            if newPriority > lastPriority {
//                                print("🔁 낮은 우선순위 이벤트 무시됨: \(eventText)")
//                                return
//                            }
                        }

                        if self.lastEventText == eventText { return }
                        self.lastEventText = eventText

                        if eventText.contains("홈런") {
                            print("홈런!!🤡")
                            displayText = "홈런!"
                        } else if eventText.contains("득점") {
                            print("득점!!🤡")
                            displayText = "득점!"
                        } else if eventText.contains("루타") {
                            print("안타!!🤡")
                            displayText = "안타!"
                        } else if eventText.contains("볼넷") || eventText.contains("몸에 맞는 볼") {
                            print("사사구!!🤡")
                            displayText = "사사구"
                        } else if eventText.contains("아웃") {
                            print("아웃!!🤡")
                            displayText = "아웃"
                        } else if eventText.contains("실점") {
                            print("실점!!🤡")
                            displayText = "실점"
                        } else {
                            displayText = "KBO 이벤트"
                        }

                        if self.isAnimatingEvent {
                            print("⚠️ 현재 애니메이션 중이므로 이벤트 무시: \(eventText)")
                        }

                        self.isAnimatingEvent = true

                        var iconName = "baseball"
                        if eventText.contains("실점") && self.viewModel.trackPointLoss {
                            iconName = "실점"
                        } else if eventText.contains("홈런") && self.viewModel.trackHomeRun {
                            iconName = "득점"
                        } else if eventText.contains("득점") && self.viewModel.trackScore {
                            iconName = "득점"
                        } else if eventText.contains("안타") && self.viewModel.trackHit {
                            iconName = "안타"
                        } else if eventText.contains("사사구") && self.viewModel.trackBB {
                            iconName = "사사구"
                        } else if eventText.contains("아웃") && self.viewModel.trackOut {
                            iconName = "아웃"
                        }

                        let eventImage = NSImage(named: NSImage.Name(iconName))
                        eventImage?.isTemplate = true
                        button.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .bold)
                        let selected = GameStateModel.shared.selectedTeamName
                        let opponent = GameStateModel.shared.opponentTeamName
                        let myScore = GameStateModel.shared.teamScores[selected] ?? 0
                        let opponentScore = GameStateModel.shared.teamScores[opponent] ?? 0
                        
                        let homeLogo = NSImage(named: NSImage.Name(selected))
                        let awayLogo = NSImage(named: NSImage.Name(opponent))
                        let scoreString = " \(myScore) : \(opponentScore) "
                        let scoreAttr = NSAttributedString(string: scoreString, attributes: [
                            .font: NSFont.monospacedDigitSystemFont(ofSize: 14, weight: .bold)
                        ])

                        let imageAttachment1 = NSTextAttachment()
                        imageAttachment1.image = homeLogo
                        imageAttachment1.bounds = CGRect(x: 0, y: -3, width: 14, height: 14)
                        let imageAttachment2 = NSTextAttachment()
                        imageAttachment2.image = awayLogo
                        imageAttachment2.bounds = CGRect(x: 0, y: -3, width: 14, height: 14)

                        let attributedString = NSMutableAttributedString()
                        if self.viewModel.showLogo {
                            attributedString.append(NSAttributedString(attachment: imageAttachment1))
                        }
                        attributedString.append(scoreAttr)
                        if self.viewModel.showLogo {
                            attributedString.append(NSAttributedString(attachment: imageAttachment2))
                        }

                        if let button = self.statusBarItem.button {
                            button.image = nil
                            button.attributedTitle = attributedString
                        }

                        DispatchQueue.main.async {
                            if let button = self.statusBarItem.button {
                                button.image = nil
                                button.attributedTitle = attributedString
                            }
                        }
                        
                        
                        print("🪧 버튼에 표시될 이벤트 텍스트: \(displayText)")
                        
                        if eventImage == nil {
                            print("⚠️ 이미지 '\(iconName)' 을 불러오지 못함")
                        }
                        
                        let totalDuration = Double(self.viewModel.alertTime)
                        let timeSinceStart = Date().timeIntervalSince(self.lastTrackingStartTime ?? Date())
                        if timeSinceStart < 5 {
                            print("⏱️ 크롤링 시작 후 5초 이내 감지된 이벤트 무시: \(eventText)")
                            return
                        }
                        self.crawler?.pause(for: totalDuration)

                        var flashCount = Int(totalDuration)
                        var showText = true
                        if self.viewModel.blinkIcon {
                            button.image = eventImage
                            button.title = ""
                            button.font = NSFont.monospacedDigitSystemFont(ofSize: 14, weight: .bold)
 
                            let totalBlinks = max(Int(totalDuration) - 1, 0)
                            var remainingBlinks = totalBlinks
                            var showText = true
 
                            let flashTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                                if remainingBlinks == 0 {
                                    timer.invalidate()
 
                                    // 마지막 상태 표시 (텍스트 or 아이콘)
                                    if showText {
                                        button.title = displayText
                                        button.image = nil
                                    } else {
                                        button.title = ""
                                        button.image = eventImage
                                    }
 
                                    // 1.2초 후 상태 복원
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                        self.isAnimatingEvent = false
                                        self.lastEventText = nil
 
                                        if self.isGameActive {
                                            button.image = nil
                                            button.attributedTitle = attributedString
                                        } else {
                                            AppDelegate.instance?.updateStatusBarWithBaseballIcon()
                                        }
                                    }
                                    return
                                }
 
                                remainingBlinks -= 1
                                if showText {
                                    button.title = displayText
                                    button.image = nil
                                } else {
                                    button.title = ""
                                    button.image = eventImage
                                }
                                showText.toggle()
                            }
                            RunLoop.main.add(flashTimer, forMode: .common)
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
                            if self.isGameActive {
                                button.image = nil
                                button.attributedTitle = attributedString
                            } else {
                                AppDelegate.instance?.updateStatusBarWithBaseballIcon()
                            }
                            self.isAnimatingEvent = false
                            self.lastEventText = nil
                        }
                        
                        DispatchQueue.main.async {
                            EventModel.shared.latestEvent = eventText
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(20)) {
                                if EventModel.shared.latestEvent == eventText {
                                    EventModel.shared.latestEvent = ""
                                }
                            }
                        }
                    }
                    self.crawler?.onTeamDetected = { isHome, opponent in
                        print(isHome ? "홈 경기" : "원정 경기")
                        print("상대팀: \(opponent)")
                        DispatchQueue.main.async {
                            if let button = self.statusBarItem.button {
                                AppDelegate.instance?.updateStatusBarWithBaseballIcon()
                            }
                        }
                        if let crawler = self.crawler {
                            let selected = GameStateModel.shared.selectedTeamName
                            let opponent = GameStateModel.shared.opponentTeamName
                            print("\(selected) 대 \(opponent)")

                            let myScore = GameStateModel.shared.teamScores[selected] ?? 0
                            let opponentScore = GameStateModel.shared.teamScores[opponent] ?? 0
                            
                            let homeLogo = NSImage(named: NSImage.Name(selected))
                            let awayLogo = NSImage(named: NSImage.Name(opponent))
                            let scoreString = " \(myScore) : \(opponentScore) "
                            let scoreAttr = NSAttributedString(string: scoreString, attributes: [
                                .font: NSFont.monospacedDigitSystemFont(ofSize: 14, weight: .bold)
                            ])

                            let imageAttachment1 = NSTextAttachment()
                            imageAttachment1.image = homeLogo
                            imageAttachment1.bounds = CGRect(x: 0, y: -3, width: 16, height: 16)
                            let imageAttachment2 = NSTextAttachment()
                            imageAttachment2.image = awayLogo
                            imageAttachment2.bounds = CGRect(x: 0, y: -3, width: 16, height: 16)

                            let attributedString = NSMutableAttributedString()
                            if self.viewModel.showLogo {
                                attributedString.append(NSAttributedString(attachment: imageAttachment1))
                            }
                            attributedString.append(scoreAttr)
                            if self.viewModel.showLogo {
                                attributedString.append(NSAttributedString(attachment: imageAttachment2))
                            }

                            if let button = self.statusBarItem.button {
                                button.image = nil
                                button.attributedTitle = attributedString
                            }

                            DispatchQueue.main.async {
                                if let button = self.statusBarItem.button {
                                    button.image = nil
                                    button.attributedTitle = attributedString
                                }
                            }
                            self.isGameActive = true
                            GameStateModel.shared.isFetchingGame = false
                        }
                    }
                    self.crawler?.start()
//                    self.lastTrackingStartTime = Date()
                } else {
                    if attempt < maxAttempts {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            GameStateModel.shared.isFetchingGame = true
                            tryFetchGameId()
                        }
                    } else {
                        self.hasExceededMaxAttempts = true
                        self.isGameActive = false
                        print("경기를 찾지 못했습니다.")
                        GameStateModel.shared.isFetchingGame = false
                    }
                }
            }
        }
        
        GameStateModel.shared.isFetchingGame = true
        tryFetchGameId()
    }
    
    func startRetryTimer() {
        retryTimer?.invalidate()
        retryTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let minute = Calendar.current.component(.minute, from: Date())
            if (0...5).contains(minute) || (30...35).contains(minute) {
                if GameStateModel.shared.isFetchingGame == false {
                    print("⏰ \(minute)분 — 정기 재시도 트리거")
                    self.startTracking()
                }
            }
        }
        RunLoop.main.add(retryTimer!, forMode: .common)
    }

    func startScoreboardTimer() {
        scoreboardTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 12 && hour <= 23 {
            if let submenu = ApplicationMenu.shared.scoreboardSubmenu {
                print("📊 자동 스코어보드 갱신 (\(Date()))")
                ApplicationMenu.shared.updateScoreboardMenu(submenu)
            }
        }
        }
        RunLoop.main.add(scoreboardTimer!, forMode: .common)
    }
    
    func updateStatusBarWithBaseballIcon() {
        guard let button = self.statusBarItem.button else { return }
        guard let originalImage = NSImage(named: NSImage.Name("baseball")) else { return }

        originalImage.isTemplate = true
        let size = NSSize(width: 18, height: 18)
        let resizedImage = NSImage(size: size)
        resizedImage.lockFocus()
        originalImage.draw(in: NSRect(origin: .zero, size: size),
                           from: .zero,
                           operation: .sourceOver,
                           fraction: 1.0)
        resizedImage.unlockFocus()

        resizedImage.isTemplate = true
        button.image = resizedImage
        button.title = ""
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        retryTimer?.invalidate()
        scoreboardTimer?.invalidate()
    }
}
