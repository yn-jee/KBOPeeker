//
//  SettingView.swift
//  KBOPeeker
//
//  Created by 나윤지 on 3/26/25.
//

import SwiftUI
import Foundation

struct SettingView: View {
    @StateObject var viewModel = SettingViewModel.shared
    @ObservedObject var gameState = GameStateModel.shared
    @AppStorage("teamChanged") var teamChanged: Bool = false
    
    var body: some View {
        HStack {
            VStack {
                Text("응원팀을 선택하세요")
                    .font(.headline)
                Picker(selection: $viewModel.selectedTeam, label: Text("")) {
                    ForEach(teamNames.keys.sorted(), id: \.self) { key in
                        Text(teamNames[key]!)
                            .tag(key)
                            .padding(.vertical, 2)
                    }
                }
                .pickerStyle(.inline)
                .frame(width: 200, height: 270)
            }
            .padding([.top, .bottom], 10)
            
            Spacer()
                
            VStack {
                Text("추적할 이벤트를 선택하세요")
                    .font(.headline)
                VStack {
                    VStack {
                        HStack {
                            Toggle("홈런", isOn: $viewModel.trackHomeRun)
                            Toggle("득점", isOn: $viewModel.trackScore)
                        }
                        .frame(width: 105, alignment: .leading)
                        HStack {
                            Toggle("안타", isOn: $viewModel.trackHit)
                            Toggle("사사구", isOn: $viewModel.trackBB)
                        }
                        .frame(width: 105, alignment: .leading)
                        HStack {
                            Toggle("아웃", isOn: $viewModel.trackOut)
                            Toggle("실점", isOn: $viewModel.trackPointLoss)
                        }
                        .frame(width: 105, alignment: .leading)
                    }
                    .padding(.top, 10)
                    Spacer()
                    
                    Toggle("아이콘 깜빡임", isOn: $viewModel.blinkIcon)
                    Spacer()
                    
                    HStack {
                        Text("알림 지속 시간  ")
                        Picker("", selection: $viewModel.alertTime) {
                            ForEach(1...20, id: \.self) { second in
                                Text("\(second)").tag(second)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 60)
                        Text("초")
                    }
                    .padding([.leading, .trailing])
                    Spacer()
                    
                    Button(action: {
                        openLoginItemsPreferencePane()
                    }) {
                        Label("로그인 시 자동 실행 설정", systemImage: "gearshape")
                    }
                    .buttonStyle(.bordered)
                    .padding(.bottom, 10)
                    
                    Text("+ 버튼 > 응용 프로그램\n\t> KBOPeeker 선택 > 추가")
                    Spacer()
                }
                .frame(height: 270)
            }
            
            Spacer()
                
        }
        .onAppear {
            DispatchQueue.main.async {
                print("🟢 SettingView onAppear 진입")
                if viewModel.selectedTeam.isEmpty {
                    let storedTeam = UserDefaults.standard.string(forKey: "selectedTeam") ?? "키움 히어로즈"
                    print("🔁 강제 로드된 팀: [\(storedTeam)]")
                    viewModel.selectedTeam = storedTeam
                }
                print("🟢 viewModel.selectedTeam (onAppear): [\(viewModel.selectedTeam)]")
            }
        }
        .onChange(of: viewModel.selectedTeam) {
            DispatchQueue.main.async {
                teamChanged = true
                viewModel.save()
                print("✅ 팀 변경됨 (async): \(viewModel.selectedTeam)")
            }
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
        .onChange(of: viewModel.alertTime) {
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
            print("지속 시간: \(UserDefaults.standard.integer(forKey: "alertTime"))")
            
            UserDefaults.standard.set(true, forKey: "initialSetupDone")
            NotificationCenter.default.post(name: Notification.Name("PreferencesSaved"), object: nil)
            gameState.isFetchingGame = true
            print("🔴 SettingView onDisappear 진입")
            print("🔴 viewModel.selectedTeam (onDisappear): [\(viewModel.selectedTeam)]")
            print("🔴 UserDefaults.selectedTeam: [\(UserDefaults.standard.string(forKey: "selectedTeam") ?? "<nil>")]")
        }
        .frame(width: 470, height: 320)
    }
    
    func openLoginItemsPreferencePane() {
        let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")!
        NSWorkspace.shared.open(url)
    }
}
