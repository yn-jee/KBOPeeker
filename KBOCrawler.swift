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

class KBOCrawler: NSObject, WKNavigationDelegate {
    private var gameURL: String
    private var webView: WKWebView?
    private var timer: Timer?

    private(set) var selectedTeamName: String = ""
    private(set) var opponentTeamName: String = ""
    private(set) var currentInning: String = ""
    private(set) var teamScores: [String: Int] = [:]

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
            self.selectedTeamName = selectedTeam

            let team1 = try doc.select("div.info_team.team_vs1 span.tit_team").first()?.text() ?? ""
            let team2 = try doc.select("div.info_team.team_vs2 span.tit_team").first()?.text() ?? ""

            let isHome = (team2 == selectedTeam)
            self.opponentTeamName = isHome ? team1 : team2
            self.onTeamDetected?(isHome, self.opponentTeamName)

            let score1 = Int(try doc.select("div.info_team.team_vs1 span.num_team").first()?.text() ?? "") ?? 0
            let score2 = Int(try doc.select("div.info_team.team_vs2 span.num_team").first()?.text() ?? "") ?? 0

            teamScores[team1] = score1
            teamScores[team2] = score2

            currentInning = try doc.select("span.txt_status").first()?.text() ?? ""

            print("응원팀: \(selectedTeamName), 상대팀: \(opponentTeamName)")
            print("스코어 - \(team1): \(score1), \(team2): \(score2)")
            print("현재 이닝: \(currentInning)")
            
            if let selected = UserDefaults.standard.string(forKey: "selectedTeam") {
                let isHome = (team1 == selected)
                self.onTeamDetected?(isHome, self.opponentTeamName)
            }

            if currentInning.contains("경기종료") {
                print("경기가 종료되었습니다.")
                self.stop()
                return
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
