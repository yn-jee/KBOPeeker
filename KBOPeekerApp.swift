//
//  KBOPeekerApp.swift
//  KBOPeeker
//
//  Created by 나윤지 on 3/21/25.
//

import SwiftUI
import UserNotifications

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
    static private(set) var instance: AppDelegate!
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

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.instance = self
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    print("🔴 알림 권한 요청 에러: \(error)")
                } else {
                    print("🟢 알림 권한 granted: \(granted)")
                }
            }
        
        if let button = self.statusBarItem.button {
            button.title = ""
            let image = NSImage(named: NSImage.Name("baseball"))
            image?.isTemplate = true
            button.image = image
        }
        self.menu = ApplicationMenu()
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
        print("알림: \(UserDefaults.standard.bool(forKey: "notification"))")

        // ✅ 옵저버 등록
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePreferencesSaved),
            name: Notification.Name("PreferencesSaved"),
            object: nil
        )

        startTracking()
    }

    @objc func handlePreferencesSaved() {
        print("📣 PreferencesSaved notification received")
        self.teamJustChanged = true
        startTracking()
    }

    func startTracking() {
        self.gameURL = nil
        GameStateModel.shared.isFetchingGame = true
        
        // 기존 크롤러 종료
        self.crawler?.stop()
        self.crawler = nil

        fetcher = GameIDFetcher()
        let selectedTeam = UserDefaults.standard.string(forKey: "selectedTeam") ?? ""
        print(selectedTeam)

        var attempt = 0
        let maxAttempts = 5
        self.hasExceededMaxAttempts = false

        func tryFetchGameId() {
            attempt += 1
            print("[시도 \(attempt)] 경기 ID를 검색 중...")

            fetcher?.getGameId(for: selectedTeam) { gameId in
                if let gameId = gameId {
                    self.gameId = gameId
                    let gameURL = "https://sports.daum.net/match/\(gameId)"
                    self.gameURL = gameURL
                    print("경기 URL: \(gameURL)")

                    self.crawler = KBOCrawler(gameURL: gameURL)
                    self.crawler?.onEventDetected = { [weak self] eventText in
                        let now = Date()
                        if let startTime = self?.lastTrackingStartTime, now.timeIntervalSince(startTime) < 3 {
                            print("⏱️ 크롤링 시작 후 3초 이내 감지된 이벤트 무시: \(eventText)")
                            return
                        }
                        guard let self = self else { return }
                        guard let button = self.statusBarItem.button else { return }

                        print("🪧 버튼에 표시될 이벤트 텍스트: \(eventText)")

                        let priorityOrder = ["홈런", "득점", "루타", "볼넷", "몸에 맞는 볼", "아웃"]
                        if let last = self.lastEventText {
                            let lastPriority = priorityOrder.firstIndex(where: { last.contains($0) }) ?? Int.max
                            let newPriority = priorityOrder.firstIndex(where: { eventText.contains($0) }) ?? Int.max
                            if newPriority > lastPriority {
                                print("🔁 낮은 우선순위 이벤트 무시됨: \(eventText)")
                                return
                            }
                        }

                        if self.lastEventText == eventText { return }
                        self.lastEventText = eventText

                        if self.viewModel.notification {
                            let content = UNMutableNotificationContent()
                            if eventText.contains("홈런") {
                                print("홈런!!🤡")
                                content.title = "홈런!"
                            } else if eventText.contains("득점") {
                                print("득점!!🤡")
                                content.title = "득점!"
                            } else if eventText.contains("루타") {
                                print("안타!!🤡")
                                content.title = "안타!"
                            } else if eventText.contains("볼넷") || eventText.contains("몸에 맞는 볼") {
                                print("사사구!!🤡")
                                content.title = "사사구!"
                            } else if eventText.contains("아웃") {
                                print("아웃!!🤡")
                                content.title = "아웃"
                            } else if eventText.contains("실점") {
                                print("실점!!🤡")
                                content.title = "실점"
                            } else {
                                content.title = "KBO 이벤트"
                            }
                            content.body = eventText
                            content.sound = UNNotificationSound.default
                            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                            UNUserNotificationCenter.current().add(request)
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
                        let scoreText = " \(myScore) : \(opponentScore) "
                        
                        if eventImage == nil {
                            print("⚠️ 이미지 '\(iconName)' 을 불러오지 못함")
                        }
                        
                        for i in 0..<5 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + (0.7 * Double(i * 2))) {
                                button.image = nil
                                button.title = eventText
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + (0.7 * Double(i * 2 + 1))) {
                                button.title = ""
                                button.image = eventImage
                            }
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
                            if self.isGameActive {
                                button.image = nil
                                button.title = scoreText
                            } else {
                                button.title = ""
                                let image = NSImage(named: NSImage.Name("baseball"))
                                image?.isTemplate = true
                                button.image = image
                            }
                            self.isAnimatingEvent = false
                            self.lastEventText = nil
                        }
                    }
                    self.crawler?.onTeamDetected = { isHome, opponent in
                        print(isHome ? "홈 경기" : "원정 경기")
                        print("상대팀: \(opponent)")
                        DispatchQueue.main.async {
                            if let button = self.statusBarItem.button {
                                button.title = ""
                                let image = NSImage(named: NSImage.Name("baseball"))
                                image?.isTemplate = true
                                button.image = image
                            }
                        }
                        if let crawler = self.crawler {
                            let selected = GameStateModel.shared.selectedTeamName
                            let opponent = GameStateModel.shared.opponentTeamName
                            print("\(selected) 대 \(opponent)")

                            let myScore = GameStateModel.shared.teamScores[selected] ?? 0
                            let opponentScore = GameStateModel.shared.teamScores[opponent] ?? 0
                            
                            let scoreText = " \(myScore) : \(opponentScore) "  // 공백으로 여백 줘서 강조
                            if let button = self.statusBarItem.button {
                                button.font = NSFont.monospacedDigitSystemFont(ofSize: 14, weight: .bold)
                                button.title = scoreText
                            }
                            print(scoreText)

                            DispatchQueue.main.async {
                                if let button = self.statusBarItem.button {
                                    button.image = nil
                                    button.title = scoreText
                                }
                            }
                            self.isGameActive = true
                        }
                    }
                    self.lastTrackingStartTime = Date()
                    self.crawler?.start()
                    
                    GameStateModel.shared.isFetchingGame = false 
                } else {
                    if attempt < maxAttempts {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            tryFetchGameId()
                        }
                    } else {
                        self.hasExceededMaxAttempts = true
                        self.isGameActive = false
                        print("경기를 찾지 못했습니다.")
                    }
                }
            }
        }

        tryFetchGameId()
    }
}
