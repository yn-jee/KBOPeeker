//
//  KBOCrawler.swift
//  KBOPeeker
//
//  Created by 나윤지 on 3/21/25.
//
import Foundation
import WebKit
import SwiftSoup
import Combine

class KBOCrawler: NSObject, WKNavigationDelegate {
    private var gameURL: String
    private var webView: WKWebView?
    private var timer: Timer?
    private var previousBatterName: String?
    private var previousMyScore: Int?
    private var previousOpponentScore: Int?

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

        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
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
            GameStateModel.shared.isFetchingGame = true
            let doc = try SwiftSoup.parse(html)

            guard let selectedTeam = UserDefaults.standard.string(forKey: "selectedTeam") else { return }
            gameState.selectedTeamName = selectedTeam

            let team1 = try doc.select("div.info_team.team_vs1 span.tit_team").first()?.text() ?? ""
            let team2 = try doc.select("div.info_team.team_vs2 span.tit_team").first()?.text() ?? ""
            
            let gameInfos = try doc.select("dl.list_gameinfo")
            for info in gameInfos {
                let dt = try info.select("dt").text()
                if dt.contains("경기장명") {
                    let stadium = try info.select("dd").text()
                    gameState.stadiumName = stadium
                    print("경기장명: \(stadium)")
                    break
                }
            }

            
            let isHome: Bool
            if team1 == selectedTeam {
                isHome = false
            } else if team2 == selectedTeam {
                isHome = true
            } else {
                print("⚠️ selectedTeam이 team1/team2 어디에도 없음")
                return
            }
            gameState.opponentTeamName = isHome ? team1 : team2
            gameState.isHome = isHome
            self.onTeamDetected?(isHome, gameState.opponentTeamName)

            let score1 = Int(try doc.select("div.info_team.team_vs1 span.num_team").first()?.text() ?? "") ?? 0
            let score2 = Int(try doc.select("div.info_team.team_vs2 span.num_team").first()?.text() ?? "") ?? 0

            let previousMyScoreValue = gameState.teamScores[selectedTeam] ?? 0
            let previousOpponentScoreValue = gameState.teamScores[gameState.opponentTeamName] ?? 0
            
            gameState.teamScores[team1] = score1
            gameState.teamScores[team2] = score2
            UserDefaults.standard.set(false, forKey: "teamChanged")

            

            gameState.currentInning = try doc.select("span.txt_status").first()?.text() ?? ""

            print("응원팀: \(gameState.selectedTeamName), 상대팀: \(gameState.opponentTeamName)")
            print("스코어 - \(team1): \(score1), \(team2): \(score2)")
            print("현재 이닝: \(gameState.currentInning)")
            
            if let selected = UserDefaults.standard.string(forKey: "selectedTeam") {
                if team1 == selected {
                    self.onTeamDetected?(false, gameState.opponentTeamName)
                } else if team2 == selected {
                    self.onTeamDetected?(true, gameState.opponentTeamName)
                } else {
                    print("⚠️ selectedTeam이 team1/team2 어디에도 없음 (두 번째 판별)")
                }
                GameStateModel.shared.isFetchingGame = false
            }

            if gameState.currentInning.contains("경기종료") {
                print("경기가 종료되었습니다.")
                GameStateModel.shared.isFetchingGame = false
                self.stop()
                return
            }
            
            if gameState.currentInning.contains("경기 전") {
                print("경기 시작 전입니다.")
                GameStateModel.shared.isFetchingGame = false
                self.stop()
        
                DispatchQueue.main.async {
                    if let button = AppDelegate.instance?.statusBarItem.button {
                        let image = NSImage(named: NSImage.Name("baseball"))
                        image?.isTemplate = true
                        button.image = image
                        button.title = ""
                    }
                }
                return
            }

            
            let scoreDiv = try doc.select("div.score").first()

            let previousOutCount = gameState.outCount
            
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

            let inningElement = try doc.select("div.inning").first()

            let topClass = try inningElement?.select("div.triangle-top").first()?.className() ?? ""
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
            print("awayTeam: \(awayTeam), homeTeam: \(homeTeam)")
            print("selectedTeamName: \(gameState.selectedTeamName)")
            print("currentAttackingTeam: \(currentAttackingTeam)")
            let isOurTeamAtBat = (currentAttackingTeam == gameState.selectedTeamName)
//            if let setting = AppDelegate.instance?.viewModel,
//               setting.trackOut,
//               isOurTeamAtBat,
//               outCount > previousOutCount {
//                print("✅ 아웃카운트 증가 감지됨: \(previousOutCount) → \(outCount)")
//                self.onEventDetected?("아웃")
//            }

            print("현재 공격 팀: \(currentAttackingTeam) / 우리 팀 공격 중? \(isOurTeamAtBat)")

            // 현재 타자 이름 파싱
            let previousName = previousBatterName
            let currentBatterName = try doc.select("div.combo_history div.info_profile strong.txt_player").first()?.text() ?? ""

            let batterChanged = previousName != nil && previousName != currentBatterName
            previousBatterName = currentBatterName
            
            var currentBatterEventLine: String? = nil
            var previousBatterEventLine: String? = nil

            // 전체 이벤트 블록에서 현재 타자의 이벤트 줄만 추출
            print("🎯 currentBatterName: \(currentBatterName)")
            
            let historyDivs = try doc.select("div.combo_history")
            for div in historyDivs {
                let name = try div.select("strong.txt_player").text()
                if name == currentBatterName {
                    let itemHistoryDivs = try div.select("div.item_history")
                    for item in itemHistoryDivs.reversed() {
                        if let span = try? item.select("span.txt_g").first(), let text = try? span.text(), !text.isEmpty {
                            print("📌 current 이벤트: \(text)")
                            currentBatterEventLine = text
                            break
                        } else if let span = try? item.select("span").first(), let text = try? span.text(), !text.isEmpty {
                            print("📌 current 대체 이벤트: \(text)")
                            currentBatterEventLine = text
                            break
                        }
                    }
                    break
                }
            }

            if batterChanged, let previousName = previousName {
                print("타자 바뀜")
                for div in historyDivs {
                    let name = try div.select("strong.txt_player").text()
                    if name == previousName {
                        let itemHistoryDivs = try div.select("div.item_history")
                        for item in itemHistoryDivs.reversed() {
                            if let span = try? item.select("span.txt_g").first(), let text = try? span.text(), !text.isEmpty {
                                print("🕓 이전 타자(\(previousName)) 마지막 이벤트: \(text)")
                                previousBatterEventLine = text
                                break
                            } else if let span = try? item.select("span").first(), let text = try? span.text(), !text.isEmpty {
                                print("🕓 이전 타자(\(previousName)) 대체 이벤트: \(text)")
                                previousBatterEventLine = text
                                break
                            }
                        }
                        break
                    }
                }
            }
//
//            // Determine highest priority event
//            var highestPriorityEvent: String?
//
//            if let setting = AppDelegate.instance?.viewModel {
//                print("isOurTeamAtBat: \(isOurTeamAtBat), outCount: \(outCount), previousOutCount: \(previousOutCount)")
//
//                // 득점 감지
//                if setting.trackScore && scoreForTeam(gameState.selectedTeamName) > previousMyScoreValue {
//                    let event = "득점!"
//                    self.onEventDetected?(event)
//                }
//
//                // 실점 감지
//                if setting.trackPointLoss && scoreForTeam(gameState.opponentTeamName) > previousOpponentScoreValue {
//                    let event = "실점!"
//                    print("🐛 AppDelegate에 전달될 eventText: \(event)")
//                    self.onEventDetected?(event)
//                }
//
//                // 타자 이벤트 전체 텍스트 기준으로 판단
//                let fullEventTexts: [String] = try {
//                    let targetDivs = historyDivs.filter {
//                        let name = (try? $0.select("strong.txt_player").text()) ?? ""
//                        return name == (batterChanged ? (previousName ?? "") : currentBatterName)
//                    }
//
//                    guard let div = targetDivs.first else { return [] }
//
//                    guard let elements = try? div.select("div.item_history") else { return [] }
//                    let historyItems = Array(elements)
//                    var lines: [String] = []
//
//                    for item in historyItems {
//                        if let spans = try? item.select("span.txt_g") {
//                            for span in spans {
//                                let text = try span.text()
//                                if !text.isEmpty {
//                                    lines.append(text)
//                                }
//                            }
//                        }
//                    }
//                    return lines
//                }()
//
//                for eventLine in fullEventTexts {
//                    if setting.trackHomeRun && eventLine.contains("홈런") {
//                        highestPriorityEvent = "홈런! \(eventLine)"
//                        break
//                    } else if setting.trackScore && eventLine.contains("홈인") {
//                        highestPriorityEvent = "득점! \(eventLine)"
//                        break
//                    } else if setting.trackHit && (eventLine.contains("안타") || eventLine.contains("루타")) {
//                        highestPriorityEvent = "안타 발생: \(eventLine)"
//                        break
//                    } else if setting.trackBB && (eventLine.contains("볼넷") || eventLine.contains("몸에 맞는 볼")) {
//                        highestPriorityEvent = "사사구 발생: \(eventLine)"
//                        break
//                    }
//                }
//
//                if setting.trackOut && isOurTeamAtBat && outCount > previousOutCount {
//                    if highestPriorityEvent == nil {
//                        highestPriorityEvent = "아웃"
//                    }
//                }
//
//                // 최종 이벤트 실행
//                if let finalEvent = highestPriorityEvent {
//                    print("🐛 AppDelegate에 전달될 eventText: \(finalEvent)")
//                    self.onEventDetected?(finalEvent)
//                }
//            }
            
            
            // Determine highest priority event
            var highestPriorityEvent: String?

            if let setting = AppDelegate.instance?.viewModel {
                print("isOurTeamAtBat: \(isOurTeamAtBat), outCount: \(outCount), previousOutCount: \(previousOutCount)")


                // 타자 이벤트 전체 텍스트 기준으로 판단
                let fullEventTexts: [String] = try {
                    let targetDivs = historyDivs.filter {
                        let name = (try? $0.select("strong.txt_player").text()) ?? ""
                        return name == (batterChanged ? (previousName ?? "") : currentBatterName)
                    }

                    guard let div = targetDivs.first else { return [] }

                    guard let elements = try? div.select("div.item_history") else { return [] }
                    var lines: [String] = []

                    for item in elements {
                        if let spans = try? item.select("span.txt_g") {
                            for span in spans {
                                let text = try span.text()
                                if !text.isEmpty {
                                    lines.append(text)
                                }
                            }
                        }
                    }
                    return lines
                }()
//                
//                // 홈인 텍스트 기반으로 득점/실점 판별
//                for line in fullEventTexts {
//                    if line.contains("홈인") {
//                        let isOurTeamScored = isOurTeamAtBat
//                        if isOurTeamScored && setting.trackScore {
//                            let event = "득점! \(line)"
//                            self.onEventDetected?(event)
//                            break
//                        } else if !isOurTeamScored && setting.trackPointLoss {
//                            let event = "실점! \(line)"
//                            print("🐛 AppDelegate에 전달될 eventText: \(event)")
//                            self.onEventDetected?(event)
//                            break
//                        }
//                    }
//                }
                
                // 모든 이벤트에서 우선순위에 맞는 항목을 탐색
                var eventPriority: [(String, String)] = []

                for line in fullEventTexts {
                    if isOurTeamAtBat {
                        if setting.trackHomeRun && line.contains("홈런") {
                            eventPriority.append(("홈런", "홈런! \(line)"))
                        }
                        if setting.trackScore && line.contains("홈인") {
                            eventPriority.append(("득점", "득점! \(line)"))
                        }
                        if setting.trackHit && (line.contains("안타") || line.contains("루타")) {
                            eventPriority.append(("안타", "안타! \(line)"))
                        }
                        if setting.trackBB && (line.contains("볼넷") || line.contains("몸에 맞는 볼")) {
                            eventPriority.append(("사사구", "사사구: \(line)"))
                        }
                        if setting.trackBB && (line.contains("아웃")) {
                            eventPriority.append(("아웃", "아웃: \(line)"))
                        }
                    } else {
                        if setting.trackScore && line.contains("홈인") {
                            eventPriority.append(("실점", "실점: \(line)"))
                        }
                    }
                }

                let priorityOrder = ["홈런", "득점", "안타", "사사구", "아웃", "실점"]
                for priority in priorityOrder {
                    if let found = eventPriority.first(where: { $0.0 == priority }) {
                        highestPriorityEvent = found.1
                        break
                    }
                }
//
//                // 아웃 텍스트 감지 (볼넷 등보다 우선순위 낮음)
//                if setting.trackOut && isOurTeamAtBat && outCount > previousOutCount {
//                    if highestPriorityEvent == nil {
//                        if let outLine = fullEventTexts.first(where: { $0.contains("아웃") }) {
//                            highestPriorityEvent = "아웃: \(outLine)"
//                        } else {
//                            highestPriorityEvent = "아웃"
//                        }
//                    }
//                }

                // 최종 이벤트 실행
                if let finalEvent = highestPriorityEvent {
                    print("🐛 AppDelegate에 전달될 eventText: \(finalEvent)")
                    self.onEventDetected?(finalEvent)
                }
            }
            
            
            if !(gameState.currentInning.contains("경기종료") || gameState.currentInning.contains("경기취소") || gameState.currentInning.contains("경기 전")) {
                
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
                
                print("1루: \(gameState.isFirstBaseOccupied), 2루: \(gameState.isSecondBaseOccupied), 3루: \(gameState.isThirdBaseOccupied)")
                print("B/S/O: \(gameState.ballCount)/\(gameState.strikeCount)/\(gameState.outCount)")
            }
            
            previousMyScore = scoreForTeam(gameState.selectedTeamName)
            previousOpponentScore = scoreForTeam(gameState.opponentTeamName)
            
        } catch {
            print("HTML 파싱 오류: \(error)")
        }
    }

    private func scoreForTeam(_ team: String) -> Int {
        return gameState.teamScores[team] ?? 0
    }

}
