
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

        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.webView?.reload()
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            webView.evaluateJavaScript("document.body.innerHTML") { result, error in
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

            // 홈/원정팀 판단
            if let awayTeamElement = try doc.select("span.team_vs.team_vs1 span.txt_team").first(),
               let homeTeamElement = try doc.select("span.team_vs.team_vs2 span.txt_team").first(),
               let selectedTeam = UserDefaults.standard.string(forKey: "selectedTeam") {

                let away = try awayTeamElement.text()
                let home = try homeTeamElement.text()

                let isHome = (home == selectedTeam)
                let opponent = isHome ? away : home
                onTeamDetected?(isHome, opponent)
            }

            // 이벤트 감지
            let events = try doc.select(".item_sms")
            for event in events {
                let text = try event.text()
                onEventDetected?(text)

                if text.contains("경기종료") {
                    sendNotification(title: "경기 종료", body: "오늘 경기가 종료되었습니다.")
                }
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
