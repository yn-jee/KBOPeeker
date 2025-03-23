//
//  GameInfoFetcher.swift
//  KBOPeeker
//
//  Created by 나윤지 on 3/22/25.
////
//
//import Foundation
//import SwiftSoup
//
//class GameInfoFetcher {
//    static func getGameId(for selectedTeam: String, completion: @escaping (Int?) -> Void) {
//        DispatchQueue.global().async {
//            let dateFormatter = DateFormatter()
//            dateFormatter.dateFormat = "yyyyMMdd"
//            let today = dateFormatter.string(from: Date())
//
//            let monthPrefix = String(today.prefix(6))
//            let dayPart = String(today.suffix(2))
//
//            let url = URL(string: "https://sports.daum.net/schedule/kbo?date=\(monthPrefix)")!
//
//            do {
//                let webString = try String(contentsOf: url)
//                let document = try SwiftSoup.parse(webString)
//
//                print(webString)
//                print("오늘 날짜 문자열:", today)
//
//                do {
//                    let allRows = try document.select("tr")
//                    print(allRows.count)
//                    let rows = try allRows.filter { try $0.attr("data-date") == "20250322" }
//                    print("필터링된 tr 개수:", rows.count)
//
//                    for row in allRows {
//                        print("row:", try row.text())
//                    }
//                } catch {
//                    print("파싱 에러:", error)
//                }
//
//                print("오늘 날짜에 해당 팀 경기 없음")
//                DispatchQueue.main.async {
//                    completion(nil)
//                }
//
//            } catch {
//                print("HTML 파싱 실패 또는 로딩 실패: \(error.localizedDescription)")
//                DispatchQueue.main.async {
//                    completion(nil)
//                }
//            }
//        }
//    }
//
//    private static func parse(json: [String: Any], selectedTeam: String, date: String) -> Int {
//        guard let schedule = json["schedule"] as? [String: [[String: Any]]],
//              let games = schedule[date] else {
//            print("No games found for date: \(date)")
//            return -1
//        }
//
//        for game in games {
//            guard let home = game["homeTeamName"] as? String,
//                  let away = game["awayTeamName"] as? String,
//                  let gameId = game["gameId"] as? Int else { continue }
//
//            if home == selectedTeam || away == selectedTeam {
//                print("Game ID: \(gameId)")
//                return gameId
//            }
//        }
//        return 0
//    }
//}
//

import Foundation
import WebKit
import SwiftSoup

class GameInfoFetcher: NSObject, WKNavigationDelegate {
    private var browseView: WKWebView?
    private var selectedTeam: String = ""
    private var completionHandler: ((Int?) -> Void)?

    func getGameId(for selectedTeam: String, completion: @escaping (Int?) -> Void) {
        self.selectedTeam = selectedTeam
        self.completionHandler = completion
        self.start()
    }

    private func start() {
        let config = WKWebViewConfiguration()
        browseView = WKWebView(frame: .zero, configuration: config)
        browseView?.navigationDelegate = self

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let today = dateFormatter.string(from: Date())
        let monthPrefix = String(today.prefix(6))
        
        let url = URL(string: "https://sports.daum.net/schedule/kbo?date=\(monthPrefix)")!
        let request = URLRequest(url: url)
        DispatchQueue.main.async {
            self.browseView?.load(request)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.body.innerHTML") { result, error in
            guard let html = result as? String else {
                print("HTML 로딩 실패: \(error?.localizedDescription ?? "알 수 없는 오류")")
                self.completionHandler?(nil)
                return
            }

            do {
                let document = try SwiftSoup.parse(html)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd"
                let today = dateFormatter.string(from: Date())

                let allRows = try document.select("tr")
                let rows = try allRows.filter { try $0.attr("data-date") == today }

                print("오늘 날짜 문자열: \(today)")
                print("필터링된 tr 개수: \(rows.count)")

                for row in rows {
                    let homeTeam = try row.select("div.info_team.team_home a span.txt_team").first()?.text() ?? ""
                    let awayTeam = try row.select("div.info_team.team_away a span.txt_team").first()?.text() ?? ""

                    if homeTeam == self.selectedTeam || awayTeam == self.selectedTeam {
                        if let link = try row.select("td.td_btn a.link_game").first(),
                           let href = try? link.attr("href"),
                           href.contains("/match/"),
                           let gameIdStr = href.components(separatedBy: "/match/").last,
                           let gameId = Int(gameIdStr) {
                            print("Game ID 추출됨: \(gameId)")
                            self.completionHandler?(gameId)
                            return
                        }
                    }
                }

                print("오늘 날짜에 해당 팀 경기 없음")
                self.completionHandler?(nil)

            } catch {
                print("HTML 파싱 실패: \(error.localizedDescription)")
                self.completionHandler?(nil)
            }
        }
    }
}
