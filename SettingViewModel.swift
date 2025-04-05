//
//  SettingViewModel.swift
//  KBOPeeker
//
//  Created by 나윤지 on 3/26/25.
//

import Foundation

class SettingViewModel: ObservableObject {
    static let shared = SettingViewModel()

    @Published var selectedTeam: String
    @Published var trackGameStarted: Bool
    @Published var trackGameFinished: Bool
    @Published var trackHit: Bool
    @Published var trackBB: Bool
    @Published var trackHomeRun: Bool
    @Published var trackScore: Bool
    @Published var trackOut: Bool
    @Published var trackPointLoss: Bool
    @Published var alertTime: Int

    private init() {
        selectedTeam = UserDefaults.standard.string(forKey: "selectedTeam") ?? "키움 히어로즈"
        trackGameStarted = UserDefaults.standard.bool(forKey: "trackGameStarted")
        trackGameFinished = UserDefaults.standard.bool(forKey: "trackGameFinished")
        trackHit = UserDefaults.standard.bool(forKey: "trackHit")
        trackBB = UserDefaults.standard.bool(forKey: "trackBB")
        trackHomeRun = UserDefaults.standard.bool(forKey: "trackHomeRun")
        trackScore = UserDefaults.standard.bool(forKey: "trackScore")
        trackOut = UserDefaults.standard.bool(forKey: "trackOut")
        trackPointLoss = UserDefaults.standard.bool(forKey: "trackPointLoss")
        alertTime = UserDefaults.standard.integer(forKey: "alertTime")
    }

    func save() {
        UserDefaults.standard.set(selectedTeam, forKey: "selectedTeam")
        UserDefaults.standard.set(trackGameStarted, forKey: "trackGameStarted")
        UserDefaults.standard.set(trackGameFinished, forKey: "trackGameFinished")
        UserDefaults.standard.set(trackHit, forKey: "trackHit")
        UserDefaults.standard.set(trackBB, forKey: "trackBB")
        UserDefaults.standard.set(trackHomeRun, forKey: "trackHomeRun")
        UserDefaults.standard.set(trackScore, forKey: "trackScore")
        UserDefaults.standard.set(trackOut, forKey: "trackOut")
        UserDefaults.standard.set(trackPointLoss, forKey: "trackPointLoss")
        UserDefaults.standard.set(alertTime, forKey: "alertTime")
    }
}
