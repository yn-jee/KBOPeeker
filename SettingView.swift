//
//  SettingView.swift
//  KBOPeeker
//
//  Created by 나윤지 on 3/26/25.
//

import SwiftUI
import Foundation

struct SettingView: View {
    @ObservedObject var viewModel: SettingViewModel
    @ObservedObject var gameState = GameStateModel.shared
    @AppStorage("teamChanged") var teamChanged: Bool = false
    
    var body: some View {
        HStack {
            VStack {
                Text("응원팀을 선택하세요")
                    .font(.headline)
                Picker(selection: $viewModel.selectedTeam, label: Text("")) {
                    ForEach(teamNames.keys.sorted(), id: \.self) { key in
                        Text(teamNames[key]!).tag(key)
                    }
                }
                .pickerStyle(.inline)
                .frame(width: 200)
            }
            .padding([.top, .bottom], 10)
            
            Spacer()
                
            VStack {
                Text("추적할 이벤트를 선택하세요")
                    .font(.headline)
                HStack {
                    VStack {
                        Toggle("경기 시작", isOn: $viewModel.trackGameStarted)
                        Toggle("경기 종료", isOn: $viewModel.trackGameFinished)
                    }.frame(width: 70)
                    VStack {
                        Toggle("안타", isOn: $viewModel.trackHit)
                        Toggle("사사구", isOn: $viewModel.trackBB)
                        Toggle("홈런", isOn: $viewModel.trackHomeRun)
                        Toggle("득점", isOn: $viewModel.trackScore)
                    }.frame(width: 70)
                    VStack {
                        Toggle("아웃", isOn: $viewModel.trackOut)
                        Toggle("실점", isOn: $viewModel.trackPointLoss)
                    }.frame(width: 70)
                }

                Toggle("알림 활성화", isOn: $viewModel.notification)
                    .padding()
                
                Button(action: {
                    openLoginItemsPreferencePane()
                }) {
                    Label("로그인 시 자동 실행 설정", systemImage: "gearshape")
                }
                .buttonStyle(.bordered)
                .padding(.top, 10)
                
                Text("+ > Finder에서 KBOPeeker 선택 > 추가")
                .padding(.top, 10)
            }
            
            Spacer()
                
        }
        .onChange(of: viewModel.selectedTeam) {
            teamChanged = true
            viewModel.save()
        }
        .onChange(of: viewModel.trackGameStarted) {
            viewModel.save()
        }
        .onChange(of: viewModel.trackGameFinished) {
            viewModel.save()
        }
        .onChange(of: viewModel.trackHit) {
            viewModel.save()
        }
        .onChange(of: viewModel.trackBB) {
            viewModel.save()
        }
        .onChange(of: viewModel.trackHomeRun) {
            viewModel.save()
        }
        .onChange(of: viewModel.trackScore) {
            viewModel.save()
        }
        .onChange(of: viewModel.trackOut) {
            viewModel.save()
        }
        .onChange(of: viewModel.trackPointLoss) {
            viewModel.save()
        }
        .onChange(of: viewModel.notification) {
            viewModel.save()
        }
        .onDisappear {
            print("Saved Preferences:")
            print("Team: \(UserDefaults.standard.string(forKey: "selectedTeam") ?? "")")
            print("경기 시작: \(UserDefaults.standard.bool(forKey: "trackGameStarted"))")
            print("경기 종료: \(UserDefaults.standard.bool(forKey: "trackGameFinished"))")
            print("안타: \(UserDefaults.standard.bool(forKey: "trackHit"))")
            print("사사구: \(UserDefaults.standard.bool(forKey: "trackBB"))")
            print("홈런: \(UserDefaults.standard.bool(forKey: "trackHomeRun"))")
            print("득점: \(UserDefaults.standard.bool(forKey: "trackScore"))")
            print("아웃: \(UserDefaults.standard.bool(forKey: "trackOut"))")
            print("실점: \(UserDefaults.standard.bool(forKey: "trackPointLoss"))")
            print("알림: \(UserDefaults.standard.bool(forKey: "notification"))")
            
            UserDefaults.standard.set(true, forKey: "initialSetupDone")
            NotificationCenter.default.post(name: Notification.Name("PreferencesSaved"), object: nil)
//            AppDelegate.instance.startTracking()
            gameState.isFetchingGame = true
            
        }
        .frame(width: 470, height: 270)
    }
    
    func openLoginItemsPreferencePane() {
        let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")!
        NSWorkspace.shared.open(url)
    }
    
//
//    func savePreferences() {
//        // 저장 로직
//        UserDefaults.standard.set(trackGameStarted, forKey: "trackGameStarted")
//        UserDefaults.standard.set(trackGameFinished, forKey: "trackGameFinished")
//        UserDefaults.standard.set(selectedTeam, forKey: "selectedTeam")
//        UserDefaults.standard.set(trackHit, forKey: "trackHit")
//        UserDefaults.standard.set(trackHomeRun, forKey: "trackHomeRun")
//        UserDefaults.standard.set(trackScore, forKey: "trackScore")
//        UserDefaults.standard.set(trackOut, forKey: "trackOut")
//        UserDefaults.standard.set(trackPointLoss, forKey: "trackPointLoss")
//        UserDefaults.standard.set(notification, forKey: "notification")
//
//        print("Saved Preferences:")
//        print("Team: \(UserDefaults.standard.string(forKey: "selectedTeam") ?? "")")
//        print("경기 시작: \(UserDefaults.standard.bool(forKey: "trackGameStarted"))")
//        print("경기 종료: \(UserDefaults.standard.bool(forKey: "trackGameFinished"))")
//        print("안타: \(UserDefaults.standard.bool(forKey: "trackHit"))")
//        print("홈런: \(UserDefaults.standard.bool(forKey: "trackHomeRun"))")
//        print("득점: \(UserDefaults.standard.bool(forKey: "trackScore"))")
//        print("아웃: \(UserDefaults.standard.bool(forKey: "trackOut"))")
//        print("실점: \(UserDefaults.standard.bool(forKey: "trackPointLoss"))")
//        print("알림: \(UserDefaults.standard.bool(forKey: "notification"))")
//    }
}
