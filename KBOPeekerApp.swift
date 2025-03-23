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
    static private(set) var instance: AppDelegate!
    lazy var statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let menu = ApplicationMenu()
    var fetcher: GameIDFetcher?
    var crawler: KBOCrawler?
    var gameId: Int?
    var gameURL: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.instance = self
        statusBarItem.button?.image = NSImage(named: NSImage.Name("baseball"))
        statusBarItem.button?.imagePosition = .imageLeading
        statusBarItem.menu = menu.createMenu()

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

        startTracking()
    }

    func startTracking() {
        // 기존 크롤러 종료
        self.crawler?.stop()
        self.crawler = nil

        fetcher = GameIDFetcher()
        let selectedTeam = UserDefaults.standard.string(forKey: "selectedTeam") ?? ""
        print(selectedTeam)

        var attempt = 0
        let maxAttempts = 5

        func tryFetchGameId() {
            attempt += 1
            print("[시도 \(attempt)] 경기 ID를 검색 중...")

            fetcher?.getGameId(for: selectedTeam) { gameId in
                if let gameId = gameId {
                    self.gameId = gameId
                    let gameURL = "https://sports.daum.net/match/\(gameId)"
                    print("경기 URL: \(gameURL)")

                    self.crawler = KBOCrawler(gameURL: gameURL)
                    self.crawler?.onTeamDetected = { isHome, opponent in
                        print(isHome ? "홈 경기" : "원정 경기")
                        print("상대팀: \(opponent)")
                    }
                    self.crawler?.onEventDetected = { eventText in
                        print("이벤트 감지됨: \(eventText)")
                    }
                    self.crawler?.start()
                } else {
                    if attempt < maxAttempts {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            tryFetchGameId()
                        }
                    } else {
                        print("경기를 찾지 못했습니다.")
                    }
                }
            }
        }

        tryFetchGameId()
    }
}
