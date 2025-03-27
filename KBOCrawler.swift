//
//  KBOCrawler.swift
//  KBOPeeker
//
//  Created by 나윤지 on 3/21/25.
//
import Foundation
import WebKit
import SwiftSoup
import UserNotifications
import Combine

class KBOCrawler: NSObject, WKNavigationDelegate {
    private var gameURL: String
    private var webView: WKWebView?
    private var timer: Timer?
    private var previousBatterName: String?

    private let gameState = GameStateModel.shared
    
    var onTeamDetected: ((_ isHome: Bool, _ opponent: String) -> Void)?
    var onEventDetected: ((_ eventText: String) -> Void)?

    init(gameURL: String) {
        self.gameURL = gameURL
    }

    func start() {
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: config)
        webView?.navigationDelegate = self

        if let url = URL(string: gameURL) {
            webView?.load(URLRequest(url: url))
        }

        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.webView?.reload()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        webView?.navigationDelegate = nil
        webView = nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            webView.evaluateJavaScript("document.body.innerHTML") { [weak self] result, error in
                guard let self = self else { return }
                if let html = result as? String {
                    self.parseHTML(html)
                } else {
                    print("HTML 추출 실패: \(error?.localizedDescription ?? "")")
                }
            }
        }
    }

    private func parseHTML(_ html: String) {
        do {
            let doc = try SwiftSoup.parse(html)

            guard let selectedTeam = UserDefaults.standard.string(forKey: "selectedTeam") else { return }
            gameState.selectedTeamName = selectedTeam

            let team1 = try doc.select("div.info_team.team_vs1 span.tit_team").first()?.text() ?? ""
            let team2 = try doc.select("div.info_team.team_vs2 span.tit_team").first()?.text() ?? ""

            let isHome = (team2 == selectedTeam)
            gameState.opponentTeamName = isHome ? team1 : team2
            self.onTeamDetected?(isHome, gameState.opponentTeamName)

            let score1 = Int(try doc.select("div.info_team.team_vs1 span.num_team").first()?.text() ?? "") ?? 0
            let score2 = Int(try doc.select("div.info_team.team_vs2 span.num_team").first()?.text() ?? "") ?? 0

            gameState.teamScores[team1] = score1
            gameState.teamScores[team2] = score2

            gameState.currentInning = try doc.select("span.txt_status").first()?.text() ?? ""

            print("응원팀: \(gameState.selectedTeamName), 상대팀: \(gameState.opponentTeamName)")
            print("스코어 - \(team1): \(score1), \(team2): \(score2)")
            print("현재 이닝: \(gameState.currentInning)")
            
            if let selected = UserDefaults.standard.string(forKey: "selectedTeam") {
                let isHome = (team1 == selected)
                self.onTeamDetected?(isHome, gameState.opponentTeamName)
            }

            if gameState.currentInning.contains("경기종료") {
                print("경기가 종료되었습니다.")
                self.stop()
                return
            }
            
            if !(gameState.currentInning.contains("경기종료") || gameState.currentInning.contains("경기취소")) {
                let inningElement = try doc.select("div.inning").first()

                let topClass = try inningElement?.select("div.triangle-top").first()?.className() ?? ""
                let bottomClass = try inningElement?.select("div.triangle-bottom").first()?.className() ?? ""
                let isTopInning = topClass.contains("on")
                
                let inningText = try inningElement?.select("p").first()?.text() ?? "1"
                let inningNumber = Int(inningText) ?? 1

                print("isTopInning: \(isTopInning), inningNumber: \(inningNumber)")
                
                gameState.updateInning(isTop: isTopInning, number: inningNumber)
                
                // 현재 공격 중인 팀 판별
                let teamSpans = try doc.select("div.scorebox_team span.txt_team")
                guard teamSpans.count >= 2 else { return }

                let awayTeam = try teamSpans.get(0).text()
                let homeTeam = try teamSpans.get(1).text()

                let currentAttackingTeam = gameState.isTopInning ? awayTeam : homeTeam
                let isOurTeamAtBat = (currentAttackingTeam == gameState.selectedTeamName)

                print("현재 공격 팀: \(currentAttackingTeam) / 우리 팀 공격 중? \(isOurTeamAtBat)")

                // 현재 타자 이름 파싱
                let batterNameElement = try doc.select("div.combo_history div.info_profile strong.txt_player").first()
                let currentBatterName = try batterNameElement?.text() ?? ""

                var batterChanged = false
                print(currentBatterName)
                if let previous = previousBatterName, previous != currentBatterName {
                    batterChanged = true
                }
                previousBatterName = currentBatterName

                // 이벤트 텍스트 수집 및 필터링
                let historyItems = try doc.select("div.combo_history div.item_history span.txt_g")
                var recentEvents: [String] = []
                for item in historyItems {
                    let text = try item.text()
                    recentEvents.append(text)
                }
                if batterChanged, let lastEvent = recentEvents.last {
                    print("최근 이벤트: \(lastEvent)")
                    
                    if let setting = AppDelegate.instance?.viewModel {
                        if isOurTeamAtBat {
                            if setting.trackHit && lastEvent.contains("안타") {
                                self.onEventDetected?("안타 발생: \(lastEvent)")
                            }
                            if setting.trackHomeRun && lastEvent.contains("홈런") {
                                self.onEventDetected?("홈런! \(lastEvent)")
                            }
                            if setting.trackScore && lastEvent.contains("홈인") {
                                self.onEventDetected?("득점! \(lastEvent)")
                            }
                            if setting.trackOut && lastEvent.contains("아웃") {
                                self.onEventDetected?("우리 팀 아웃: \(lastEvent)")
                            }
                        } else {
                            if setting.trackPointLoss && lastEvent.contains("홈인") {
                                self.onEventDetected?("실점! \(lastEvent)")
                            }
                        }
                    }
                }

                // 1루/2루/3루 베이스 점유 여부
                let baseElements = try doc.select("ul.base li")
                for base in baseElements {
                    let className = try base.className()
                    let isOn = className.contains("on")
                    if className.contains("b1") {
                        gameState.isFirstBaseOccupied = isOn
                    } else if className.contains("b2") {
                        gameState.isSecondBaseOccupied = isOn
                    } else if className.contains("b3") {
                        gameState.isThirdBaseOccupied = isOn
                    }
                }

                // 점수 및 B/S/O
                let scoreDiv = try doc.select("div.score").first()

                // 볼 (첫 번째 <span>)
                let ballText = try scoreDiv?.select("span").get(0).text() ?? "0"
                let ballCount = Int(ballText) ?? 0

                // 스트라이크 (두 번째 <span>)
                let strikeText = try scoreDiv?.select("span").get(1).text() ?? "0"
                let strikeCount = Int(strikeText) ?? 0

                // 아웃 카운트 (class="out-num")
                let outText = try scoreDiv?.select("span.out-num").first()?.text() ?? "0"
                let outCount = Int(outText) ?? 0

                gameState.updateBSO(ball: ballCount, strike: strikeCount, out: outCount)

                print("1루: \(gameState.isFirstBaseOccupied), 2루: \(gameState.isSecondBaseOccupied), 3루: \(gameState.isThirdBaseOccupied)")
                print("B/S/O: \(gameState.ballCount)/\(gameState.strikeCount)/\(gameState.outCount)")
            }
            
        } catch {
            print("HTML 파싱 오류: \(error)")
        }
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
