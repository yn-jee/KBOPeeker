import Foundation
import WebKit
import SwiftSoup

class GameIDFetcher: NSObject, WKNavigationDelegate {
    private var browseView: WKWebView?
    private var selectedTeam: String = ""
    private var completionHandler: ((Int?) -> Void)?
    var isCancelled: Bool = false

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
                
                let hasNoGameRow = try allRows.contains { row in
                    let text = try row.select("td.td_empty").text()
                    let dateAttr = try row.attr("data-date")
                    return text.contains("경기가 없습니다") && dateAttr == today
                }
                if hasNoGameRow {
                    print("경기가 없습니다: 해당 날짜에 경기 없음")
                    GameStateModel.shared.noGame = true
                    self.completionHandler?(nil)
                    return
                }
                
                let rows = try allRows.filter { try $0.attr("data-date") == today }

                print("오늘 날짜 문자열: \(today)")
                print("필터링된 tr 개수: \(rows.count)")
                print("팀: \(self.selectedTeam)")

                for row in rows {
                    let homeTeam = try row.select("div.info_team.team_home a span.txt_team").first()?.text() ?? ""
                    let awayTeam = try row.select("div.info_team.team_away a span.txt_team").first()?.text() ?? ""

                    if homeTeam == self.selectedTeam || awayTeam == self.selectedTeam {
                        // a 태그 있는 경우 (정상 경기)
                        if let link = try row.select("td.td_btn a.link_game").first(),
                           let href = try? link.attr("href"),
                           href.contains("/match/"),
                           let gameIdStr = href.components(separatedBy: "/match/").last,
                           let gameId = Int(gameIdStr) {
                            print("Game ID 추출됨: \(gameId)")
                            self.completionHandler?(gameId)
                            return
                        }

                        // a 태그가 없고 '경기취소' 텍스트 있는 경우
                        let tdTextBtn = try row.select("td.td_btn").text()
                        if tdTextBtn.contains("경기취소") {
                            print("경기가 없습니다: 경기취소")
                            GameStateModel.shared.isCancelled = true
                            self.isCancelled = true
                            self.completionHandler?(nil)
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
