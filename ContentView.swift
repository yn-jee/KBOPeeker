//
//  ContentView.swift
//  KBOPeeker
//
//  Created by 나윤지 on 3/21/25.
//

import SwiftUI
import CoreData

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
    // 상태 관련 변수
    @State private var selectedTeam: String = UserDefaults.standard.string(forKey: "selectedTeam") ?? "키움 히어로즈"
    @State private var trackGameStarted: Bool = UserDefaults.standard.bool(forKey: "trackGameStarted")
    @State private var trackGameFinished: Bool = UserDefaults.standard.bool(forKey: "trackGameFinished")
    @State private var trackHit: Bool = UserDefaults.standard.bool(forKey: "trackHit")
    @State private var trackHomeRun: Bool = UserDefaults.standard.bool(forKey: "trackHomeRun")
    @State private var trackScore: Bool = UserDefaults.standard.bool(forKey: "trackScore")
    @State private var trackOut: Bool = UserDefaults.standard.bool(forKey: "trackOut")
    @State private var trackPointLoss: Bool = UserDefaults.standard.bool(forKey: "trackPointLoss")
    @State private var notification: Bool = UserDefaults.standard.bool(forKey: "notification")
    
    // 설정 관련 변수
    @Environment(\.presentationMode) var presentationMode
    @State private var changeSaved = ""
    @State private var showSavedMessage = false
    @State private var showTeamPicker = false
    @State private var showSettings = false
    
    // 경기 정보 관련 변수
    @State private var homeScore = 0
    @State private var awayScore = 0
    @State private var isFirstBaseOccupied = true
    @State private var isSecondBaseOccupied = false
    @State private var isThirdBaseOccupied = false
    @State private var isTopInning = true
    @State private var inningNumber = 5
    @State private var ballCount = 2
    @State private var strikeCount = 1
    @State private var outCount = 0
    

    var body: some View {
        VStack(alignment: .center) {
            HStack {
                HStack {
                    Text("응원팀: ")
                    Button(action: {
                        if showTeamPicker {
                            savePreferences()
                            UserDefaults.standard.set(true, forKey: "initialSetupDone")
                            NotificationCenter.default.post(name: Notification.Name("PreferencesSaved"), object: nil)
                            AppDelegate.instance.startTracking()
                        }
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showTeamPicker.toggle()
                        }
                    }) {
                        Text(showTeamPicker ? "팀 저장" : (teamNames[selectedTeam] ?? selectedTeam))
                    }
                }
//                .frame(width: 200)
//
                Spacer()

                Button(action: {
                    if showSettings {
                        savePreferences()
                        UserDefaults.standard.set(true, forKey: "initialSetupDone")
                        NotificationCenter.default.post(name: Notification.Name("PreferencesSaved"), object: nil)
                        AppDelegate.instance.startTracking()
                    }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSettings.toggle()
                    }
                }) {
                    Text(showSettings ? "설정 저장" : "설정")
                }
            }
            .padding(.top, 10)
           
            // 설정창
            ScrollView {
                if showTeamPicker {
                    VStack {
                        Text("응원팀을 선택하세요")
                            .font(.headline)
                        Picker(selection: $selectedTeam, label: Text("")) {
                            ForEach(teamNames.keys.sorted(), id: \.self) { key in
                                Text(teamNames[key]!).tag(key)
                            }
                        }
                        .pickerStyle(.inline)
                        .frame(width: 200)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding([.top, .bottom], 10)
                }

                if showSettings {
                    VStack {
                        Text("추적할 이벤트를 선택하세요")
                            .font(.headline)
                        HStack {
                            VStack {
                                Toggle("경기 시작", isOn: $trackGameStarted)
                                Toggle("경기 종료", isOn: $trackGameFinished)
                            }.frame(width: 70)
                            VStack {
                                Toggle("안타", isOn: $trackHit)
                                Toggle("홈런", isOn: $trackHomeRun)
                                Toggle("득점", isOn: $trackScore)
                            }.frame(width: 70)
                            VStack {
                                Toggle("아웃", isOn: $trackOut)
                                Toggle("실점", isOn: $trackPointLoss)
                            }.frame(width: 70)
                        }

                        Toggle("알림 활성화", isOn: $notification)
                            .padding()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            
            // 경기 정보
            HStack(alignment: .center) {
                VStack(spacing: 6) {
                    HStack {
                        Text("HOME")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Text("\(homeScore)")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                    }
                    HStack {
                        Text("AWAY")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Text("\(awayScore)")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .frame(width: 65)

                // 이닝
                VStack(spacing: 4) {
                    if isTopInning {
                        Text("▲")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text("\(inningNumber)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    if !isTopInning {
                        Text("▼")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 20)
                
                // 베이스 정보
                ZStack {
                    ZStack {
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(20), spacing: 2), count: 2), spacing: 2) {
                            Rectangle()
                                .frame(width: 20, height: 20)
                                .opacity(isThirdBaseOccupied ? 1 : 0.3) // top-left

                            Rectangle()
                                .frame(width: 20, height: 20)
                                .opacity(isSecondBaseOccupied ? 1 : 0.3) // top-right
                            
                            Color.clear // bottom-left (비워둠)

                            Rectangle()
                                .frame(width: 20, height: 20)
                                .opacity(isFirstBaseOccupied ? 1 : 0.3) // bottom-right
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
                                .fill(i < ballCount ? Color.green : Color.gray)
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
                                .fill(i < strikeCount ? Color.yellow : Color.gray)
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
                                .fill(i < outCount ? Color.red : Color.gray)
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

    func savePreferences() {
        changeSaved = ""

        // 저장 로직
        UserDefaults.standard.set(trackGameStarted, forKey: "trackGameStarted")
        UserDefaults.standard.set(trackGameFinished, forKey: "trackGameFinished")
        UserDefaults.standard.set(selectedTeam, forKey: "selectedTeam")
        UserDefaults.standard.set(trackHit, forKey: "trackHit")
        UserDefaults.standard.set(trackHomeRun, forKey: "trackHomeRun")
        UserDefaults.standard.set(trackScore, forKey: "trackScore")
        UserDefaults.standard.set(trackOut, forKey: "trackOut")
        UserDefaults.standard.set(trackPointLoss, forKey: "trackPointLoss")
        UserDefaults.standard.set(notification, forKey: "notification")

        print("Saved Preferences:")
        print("Team: \(UserDefaults.standard.string(forKey: "selectedTeam") ?? "")")
        print("경기 시작: \(UserDefaults.standard.bool(forKey: "trackGameStarted"))")
        print("경기 종료: \(UserDefaults.standard.bool(forKey: "trackGameFinished"))")
        print("안타: \(UserDefaults.standard.bool(forKey: "trackHit"))")
        print("홈런: \(UserDefaults.standard.bool(forKey: "trackHomeRun"))")
        print("득점: \(UserDefaults.standard.bool(forKey: "trackScore"))")
        print("아웃: \(UserDefaults.standard.bool(forKey: "trackOut"))")
        print("실점: \(UserDefaults.standard.bool(forKey: "trackPointLoss"))")
        print("알림: \(UserDefaults.standard.bool(forKey: "notification"))")
    }
}

//struct TeamPickerView: View {
//    @Binding var selectedTeam: String
//    @Environment(\.dismiss) var dismiss
//
//    var body: some View {
//        VStack(alignment: .leading) {
//            Text("응원팀을 선택하세요")
//                .font(.headline)
//                .padding(.bottom)
//
//            Picker(selection: $selectedTeam, label: Text("")) {
//                ForEach(teamNames.keys.sorted(), id: \.self) { key in
//                    Text(teamNames[key]!).tag(key)
//                }
//            }
//            .pickerStyle(.inline)
//
//            HStack {
//                Spacer()
//                Button("저장") {
//                    UserDefaults.standard.set(selectedTeam, forKey: "selectedTeam")
//
//                    print("Saved Preferences:")
//                    print("Team: \(UserDefaults.standard.string(forKey: "selectedTeam") ?? "")")
//                    print("경기 시작: \(UserDefaults.standard.bool(forKey: "trackGameStarted"))")
//                    print("경기 종료: \(UserDefaults.standard.bool(forKey: "trackGameFinished"))")
//                    print("안타: \(UserDefaults.standard.bool(forKey: "trackHit"))")
//                    print("홈런: \(UserDefaults.standard.bool(forKey: "trackHomeRun"))")
//                    print("득점: \(UserDefaults.standard.bool(forKey: "trackScore"))")
//                    print("아웃: \(UserDefaults.standard.bool(forKey: "trackOut"))")
//                    print("실점: \(UserDefaults.standard.bool(forKey: "trackPointLoss"))")
//                    print("알림: \(UserDefaults.standard.bool(forKey: "notification"))")
//                    AppDelegate.instance.startTracking()
//                    dismiss()
//                }
//            }
//            .padding(.top)
//        }
//        .padding()
//        .frame(width: 250)
//    }
//}
//
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
