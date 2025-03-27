//
//  ContentView.swift
//  KBOPeeker
//
//  Created by 나윤지 on 3/21/25.
//

import SwiftUI
import CoreData
import Combine

let teamNames = [
    "KIA": "기아 타이거즈",
    "두산": "두산 베어스",
    "롯데": "롯데 자이언츠",
    "삼성": "삼성 라이온즈",
    "키움": "키움 히어로즈",
    "한화": "한화 이글스",
    "KT": "KT 위즈",
    "LG": "LG 트윈스",
    "NC": "NC 다이노스",
    "SSG": "SSG 랜더스"
]

struct ContentView: View {
    //    // 상태 관련 변수
    //    @State private var selectedTeam: String = UserDefaults.standard.string(forKey: "selectedTeam") ?? "키움 히어로즈"
    //    @State private var trackGameStarted: Bool = UserDefaults.standard.bool(forKey: "trackGameStarted")
    //    @State private var trackGameFinished: Bool = UserDefaults.standard.bool(forKey: "trackGameFinished")
    //    @State private var trackHit: Bool = UserDefaults.standard.bool(forKey: "trackHit")
    //    @State private var trackHomeRun: Bool = UserDefaults.standard.bool(forKey: "trackHomeRun")
    //    @State private var trackScore: Bool = UserDefaults.standard.bool(forKey: "trackScore")
    //    @State private var trackOut: Bool = UserDefaults.standard.bool(forKey: "trackOut")
    //    @State private var trackPointLoss: Bool = UserDefaults.standard.bool(forKey: "trackPointLoss")
    //    @State private var notification: Bool = UserDefaults.standard.bool(forKey: "notification")
    //    
    //    // 설정 관련 변수
    //    @Environment(\.presentationMode) var presentationMode
    //    @State private var changeSaved = ""
    //    @State private var showSavedMessage = false
    //    @State private var showTeamPicker = false
    //    @State private var showSettings = false
    
    @ObservedObject var viewModel: SettingViewModel
    @ObservedObject var gameState = GameStateModel.shared
    
    
    var body: some View {
        VStack(alignment: .center) {
            //            HStack {
            //                HStack {
            //                    Text("응원팀: ")
            //                    Button(action: {
            //                        if showTeamPicker {
            //                            savePreferences()
            //                            UserDefaults.standard.set(true, forKey: "initialSetupDone")
            //                            NotificationCenter.default.post(name: Notification.Name("PreferencesSaved"), object: nil)
            //                            AppDelegate.instance.startTracking()
            //                        }
            //                        withAnimation(.easeInOut(duration: 0.3)) {
            //                            showTeamPicker.toggle()
            //                        }
            //                    }) {
            //                        Text(showTeamPicker ? "팀 저장" : (teamNames[selectedTeam] ?? selectedTeam))
            //                    }
            //                }
            ////                .frame(width: 200)
            ////
            //                Spacer()
            //
            //                Button(action: {
            //                    if showSettings {
            //                        savePreferences()
            //                        UserDefaults.standard.set(true, forKey: "initialSetupDone")
            //                        NotificationCenter.default.post(name: Notification.Name("PreferencesSaved"), object: nil)
            //                        AppDelegate.instance.startTracking()
            //                    }
            //                    withAnimation(.easeInOut(duration: 0.3)) {
            //                        showSettings.toggle()
            //                    }
            //                }) {
            //                    Text(showSettings ? "설정 저장" : "설정")
            //                }
            //            }
            
            Text("\(teamNames[viewModel.selectedTeam] ?? "우리 팀") 화이팅!")
                .padding(.top, 10)
                .font(.system(size: 12, weight: .bold))
            
            // 경기 정보
            HStack(alignment: .center) {
                VStack(spacing: 6) {
                    HStack {
                        Text("\(gameState.selectedTeamName)")
                            .font(.system(size: 13, weight: .bold))
                        Text("\(gameState.teamScores[gameState.selectedTeamName] ?? 0)")
                            .font(.system(size: 16, weight: .bold))
                    }
                    HStack {
                        Text("\(gameState.opponentTeamName)")
                            .font(.system(size: 13, weight: .bold))
                        Text("\(gameState.teamScores[gameState.opponentTeamName] ?? 0)")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .frame(width: 65)
                
                let burgundy = Color(#colorLiteral(red: 0.4392156899, green: 0.01176470611, blue: 0.1921568662, alpha: 1))
                // 이닝
                VStack(spacing: 4) {
                    if gameState.isTopInning {
                        Text("▲")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(burgundy)
                    }
                    Text("\(gameState.inningNumber)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(burgundy)
                    if !gameState.isTopInning {
                        Text("▼")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(burgundy)
                    }
                }
                .frame(width: 20)
                
                // 베이스 정보
                ZStack {
                    ZStack {
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(20), spacing: 2), count: 2), spacing: 2) {
                            Rectangle()
                                .frame(width: 20, height: 20)
                                .opacity(gameState.isThirdBaseOccupied ? 1 : 0.3) // top-left
                            
                            Rectangle()
                                .frame(width: 20, height: 20)
                                .opacity(gameState.isSecondBaseOccupied ? 1 : 0.3) // top-right
                            
                            Color.clear // bottom-left (비워둠)
                            
                            Rectangle()
                                .frame(width: 20, height: 20)
                                .opacity(gameState.isFirstBaseOccupied ? 1 : 0.3) // bottom-right
                        }
                        .rotationEffect(.degrees(-45)) // 전체 그리드를 회전
                    }
                    //                .padding([.top, .leading, .trailing], 20)
                    .padding(.top, 20)
                    .frame(width: 50, height: 50) // 전체 프레임 조절
                }
                .frame(width: 60)
                
                Spacer()
                
                // BSO 표시
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("B")
                            .foregroundColor(.white)
                            .font(.system(size: 13, weight: .bold))
                            .frame(width: 15)
                        ForEach(0..<3) { i in
                            Circle()
                                .fill(i < gameState.ballCount ? Color.green : Color.gray)
                                .frame(width: 10, height: 10)
                        }
                    }
                    .frame(height: 12)
                    HStack {
                        Text("S")
                            .foregroundColor(.white)
                            .font(.system(size: 13, weight: .bold))
                            .frame(width: 15)
                        ForEach(0..<2) { i in
                            Circle()
                                .fill(i < gameState.strikeCount ? Color.yellow : Color.gray)
                                .frame(width: 10, height: 10)
                        }
                    }
                    .frame(height: 12)
                    HStack {
                        Text("O")
                            .foregroundColor(.white)
                            .font(.system(size: 13, weight: .bold))
                            .frame(width: 15)
                        ForEach(0..<2) { i in
                            Circle()
                                .fill(i < gameState.outCount ? Color.red : Color.gray)
                                .frame(width: 10, height: 10)
                        }
                    }
                    .frame(height: 12)
                }
                
                Spacer()
            }
            .padding([.top, .bottom], 10)
            
        }
        .frame(width: 200)
    }
}
