//
//  GameStateModel.swift
//  KBOPeeker
//
//  Created by 나윤지 on 3/26/25.
//

import Foundation
import Combine

class GameStateModel: ObservableObject {
    static let shared = GameStateModel() // 싱글톤
    @Published var isFetchingGame: Bool = false
    @Published var isCancelled: Bool = false
    
    @Published var isTopInning: Bool = true
    @Published var inningNumber: Int = 1

    @Published var isFirstBaseOccupied: Bool = false
    @Published var isSecondBaseOccupied: Bool = false
    @Published var isThirdBaseOccupied: Bool = false

    @Published var ballCount: Int = 0
    @Published var strikeCount: Int = 0
    @Published var outCount: Int = 0

    var selectedTeamName: String {
        get { SettingViewModel.shared.selectedTeam }
        set { SettingViewModel.shared.selectedTeam = newValue }
    }
    @Published var isHome: Bool = false
    @Published var opponentTeamName: String = ""
    @Published var stadiumName: String = ""
    @Published var currentInning: String = ""
    @Published var teamScores: [String: Int] = [:]

    private init() {
        // UserDefaults에서 불러올 수도 있음
        selectedTeamName = UserDefaults.standard.string(forKey: "selectedTeamName") ?? ""
        opponentTeamName = UserDefaults.standard.string(forKey: "opponentTeamName") ?? ""
        currentInning = UserDefaults.standard.string(forKey: "currentInning") ?? ""
        if let data = UserDefaults.standard.data(forKey: "teamScores"),
           let savedScores = try? JSONDecoder().decode([String: Int].self, from: data) {
            teamScores = savedScores
        }
    }

    func resetCounts() {
        ballCount = 0
        strikeCount = 0
        outCount = 0
    }

    func updateBaseStatus(b1: Bool, b2: Bool, b3: Bool) {
        isFirstBaseOccupied = b1
        isSecondBaseOccupied = b2
        isThirdBaseOccupied = b3
    }

    func updateInning(isTop: Bool, number: Int) {
        isTopInning = isTop
        inningNumber = number
    }

    func updateBSO(ball: Int, strike: Int, out: Int) {
        ballCount = ball
        strikeCount = strike
        outCount = out
    }

    func persist() {
        UserDefaults.standard.set(selectedTeamName, forKey: "selectedTeamName")
        UserDefaults.standard.set(opponentTeamName, forKey: "opponentTeamName")
        UserDefaults.standard.set(currentInning, forKey: "currentInning")
        if let data = try? JSONEncoder().encode(teamScores) {
            UserDefaults.standard.set(data, forKey: "teamScores")
        }
    }
}
