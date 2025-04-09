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
    "KIA": "KIA 타이거즈",
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
    @ObservedObject var viewModel: SettingViewModel
    @EnvironmentObject var eventModel: EventModel
    @ObservedObject var gameState = GameStateModel.shared
    @State private var waitingDots: String = ""
    @State private var refreshID = UUID()
    
    
    var body: some View {
        if gameState.isFetchingGame {
            VStack {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.6)
                Text("경기를 찾는 중...")
                    .multilineTextAlignment(.center)
                    .font(.headline)
                    .padding()
                Spacer()
            }
            .frame(width: 200)
        }
        else if AppDelegate.instance?.gameURL == nil {
            if AppDelegate.instance?.hasExceededMaxAttempts == true {

                VStack {
                    Spacer()
                    Text("경기를 찾지 못했습니다.\n\n설정 확인 후 다시 시도해주세요.")
                        .multilineTextAlignment(.center)
                        .font(.headline)
                        .padding()
                    Spacer()
                }
                .frame(width: 200)
                .onAppear {
                        DispatchQueue.main.async {
                            if let button = AppDelegate.instance?.statusBarItem.button {
                                let image = NSImage(named: NSImage.Name("baseball"))
                                image?.isTemplate = true
                                button.image = image
                                button.title = ""
                            }
                        }
                    }
            } else if gameState.isCancelled {
                VStack {
                    Spacer()
                    Text("오늘 \(teamNames[viewModel.selectedTeam] ?? viewModel.selectedTeam) 경기는 취소되었습니다.")
                        .multilineTextAlignment(.center)
                        .font(.headline)
                        .padding()
                    Spacer()
                }
                .frame(width: 200)
                .onAppear {
                        DispatchQueue.main.async {
                            if let button = AppDelegate.instance?.statusBarItem.button {
                                let image = NSImage(named: NSImage.Name("baseball"))
                                image?.isTemplate = true
                                button.image = image
                                button.title = ""
                            }
                        }
                    }
            } else if gameState.noGame {
                VStack {
                    Spacer()
                    Text("오늘 예정된 경기가 없습니다.")
                        .multilineTextAlignment(.center)
                        .font(.headline)
                        .padding()
                    Spacer()
                }
                .frame(width: 200)
                .onAppear {
                        DispatchQueue.main.async {
                            if let button = AppDelegate.instance?.statusBarItem.button {
                                let image = NSImage(named: NSImage.Name("baseball"))
                                image?.isTemplate = true
                                button.image = image
                                button.title = ""
                            }
                        }
                    }
            } else {
                VStack {
                    Spacer()
                    ProgressView() // 기본 로딩 인디케이터
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.6)
                    Text("경기를 찾는 중...")
                        .multilineTextAlignment(.center)
                        .font(.headline)
                        .padding()
                    Spacer()
                }
                .frame(width: 200)
                .onAppear {
                        DispatchQueue.main.async {
                            if let button = AppDelegate.instance?.statusBarItem.button {
                                let image = NSImage(named: NSImage.Name("baseball"))
                                image?.isTemplate = true
                                button.image = image
                                button.title = ""
                            }
                        }
                    }
            }
        }
        else if gameState.currentInning.contains("경기 전") {
            VStack {
                Spacer()
                Text("\(gameState.selectedTeamName) VS \(gameState.opponentTeamName)")
                    .multilineTextAlignment(.center)
                    .font(.headline)
                    .padding(.bottom, 8)
                Text("경기 시작 전입니다.")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .padding()
                Spacer()
            }
            .frame(width: 200)
            .onAppear {
                    DispatchQueue.main.async {
                        if let button = AppDelegate.instance?.statusBarItem.button {
                            let image = NSImage(named: NSImage.Name("baseball"))
                            image?.isTemplate = true
                            button.image = image
                            button.title = ""
                        }
                    }
                }
        }
        else if gameState.currentInning.contains("경기취소") {
            VStack {
                Spacer()
                Text("\(gameState.selectedTeamName) VS \(gameState.opponentTeamName)")
                    .multilineTextAlignment(.center)
                    .font(.headline)
                    .padding(.bottom, 8)
                Text("오늘 \(teamNames[viewModel.selectedTeam] ?? viewModel.selectedTeam) 경기는 취소되었습니다.")          .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .padding()
                Spacer()
            }
            .frame(width: 200)
            .onAppear {
                    DispatchQueue.main.async {
                        if let button = AppDelegate.instance?.statusBarItem.button {
                            let image = NSImage(named: NSImage.Name("baseball"))
                            image?.isTemplate = true
                            button.image = image
                            button.title = ""
                        }
                    }
                }
        }
        else if gameState.currentInning.contains("경기종료") {
            VStack {
                Spacer()
                Text("\(gameState.selectedTeamName) VS \(gameState.opponentTeamName)")
                    .multilineTextAlignment(.center)
                    .font(.headline)
                    .padding(.bottom, 8)
                Text("\(gameState.teamScores[gameState.selectedTeamName] ?? 0) : \(gameState.teamScores[gameState.opponentTeamName] ?? 0)")
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .bold()
                    .padding(.bottom, 8)
                Text("경기가 종료되었습니다.")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .padding()
                Spacer()
            }
            .frame(width: 200)
        }
        else {
            VStack(alignment: .center) {
                Text("\(teamNames[viewModel.selectedTeam] ?? "우리 팀") 화이팅!")
                    .padding(.top, 7)
                    .font(.system(size: 12, weight: .bold))
                Text("\(gameState.stadiumName)")
                
                Text(eventModel.latestEvent.isEmpty ? "📢 실시간 이벤트 대기 중\(waitingDots)" : "📢 \(eventModel.latestEvent)")
                    .font(.system(size: 11))
                    .padding(.top, 4)
                    .multilineTextAlignment(.center)
                    .frame(height: 27)
                    .opacity(eventModel.latestEvent.isEmpty ? 0.5 : 1)
                    .id(refreshID)
                
                // 경기 정보
                HStack(alignment: .center) {
                    Spacer()
                    
                    VStack(spacing: 6) {
                        if gameState.isHome {
                            HStack {
                                Text("\(gameState.opponentTeamName)")
                                    .font(.system(size: 13, weight: .bold))
                                    .frame(width: 30, alignment: .leading)
                                Text("\(gameState.teamScores[gameState.opponentTeamName] ?? 0)")
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(width: 22)
                            }
                            HStack {
                                Text("\(gameState.selectedTeamName)")
                                    .font(.system(size: 13, weight: .bold))
                                    .frame(width: 30, alignment: .leading)
                                Text("\(gameState.teamScores[gameState.selectedTeamName] ?? 0)")
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(width: 22)
                            }
                        } else {
                            HStack {
                                Text("\(gameState.selectedTeamName)")
                                    .font(.system(size: 13, weight: .bold))
                                    .frame(width: 30, alignment: .leading)
                                Text("\(gameState.teamScores[gameState.selectedTeamName] ?? 0)")
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(width: 22)
                            }
                            HStack {
                                Text("\(gameState.opponentTeamName)")
                                    .font(.system(size: 13, weight: .bold))
                                    .frame(width: 30, alignment: .leading)
                                Text("\(gameState.teamScores[gameState.opponentTeamName] ?? 0)")
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(width: 22)
                            }
                        }
                    }
                    
                    // 이닝
                    VStack(spacing: 4) {
                        if gameState.isTopInning {
                            Text("▲")
                                .font(.system(size: 13, weight: .bold))
                        }
                        Text("\(gameState.inningNumber)")
                            .font(.system(size: 13, weight: .bold))
                        if !gameState.isTopInning {
                            Text("▼")
                                .font(.system(size: 13, weight: .bold))
                        }
                    }
                    .frame(width: 20)
                    
                    Spacer()
                    
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
                        .padding(.top, 15)
                        .frame(width: 50, height: 50) // 전체 프레임 조절
                    }
                    .frame(width: 60)
                    
                    Spacer()
                    
                    // BSO 표시
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("B")
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
                    .padding(.leading, 5)
                    
                    Spacer()
                }
                .padding(.top, 5)
                .padding(.bottom, 8)
            }
//            .task {
//                while eventModel.latestEvent.isEmpty {
//                    await MainActor.run {
//                        switch waitingDots {
//                        case "":
//                            waitingDots = "."
//                        case ".":
//                            waitingDots = ".."
//                        case "..":
//                            waitingDots = "..."
//                        default:
//                            waitingDots = ""
//                        }
//                        refreshID = UUID()
//                    }
//                    try? await Task.sleep(nanoseconds: 700_000_000)
//                }
//            }
            .frame(width: 200)
        }
    }
}
