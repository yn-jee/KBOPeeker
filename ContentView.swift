//
//  ContentView.swift
//  KBOPeeker
//
//  Created by 나윤지 on 3/21/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var selectedTeam: String = UserDefaults.standard.string(forKey: "selectedTeam") ?? "키움 히어로즈"
    @State private var trackGameStarted: Bool = UserDefaults.standard.bool(forKey: "trackGameStarted")
    @State private var trackGameFinished: Bool = UserDefaults.standard.bool(forKey: "trackGameFinished")
    @State private var trackHit: Bool = UserDefaults.standard.bool(forKey: "trackHit")
    @State private var trackHomeRun: Bool = UserDefaults.standard.bool(forKey: "trackHomeRun")
    @State private var trackScore: Bool = UserDefaults.standard.bool(forKey: "trackScore")
    @State private var trackOut: Bool = UserDefaults.standard.bool(forKey: "trackOut")
    @State private var trackPointLoss: Bool = UserDefaults.standard.bool(forKey: "trackPointLoss")
    @State private var notification: Bool = UserDefaults.standard.bool(forKey: "notification")

    @Environment(\.presentationMode) var presentationMode
    
    @State private var changeSaved = ""
    @State private var showSavedMessage = false
    @State private var showTeamPicker = false

    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Text("응원팀: ")
                Button("\(selectedTeam)") {
                    openTeamPickerWindow()
                }
            }
            .padding()

            // 이벤트 토글 버튼
            Text("추적할 이벤트를 선택하세요")
                .font(.headline)
            HStack {
                VStack {
                    Toggle("경기 시작", isOn: $trackGameStarted)
                    Toggle("경기 종료", isOn: $trackGameFinished)
                }.frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
                VStack {
                    Toggle("안타", isOn: $trackHit)
                    Toggle("홈런", isOn: $trackHomeRun)
                    Toggle("득점", isOn: $trackScore)
                }.frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
                VStack {
                    Toggle("아웃", isOn: $trackOut)
                    Toggle("실점", isOn: $trackPointLoss)
                }.frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
            }
            
            Toggle("알림 활성화", isOn: $notification)
                .padding()
            // 설정 저장 버튼
            Button(action: {
                savePreferences()
                UserDefaults.standard.set(true, forKey: "initialSetupDone")
                presentationMode.wrappedValue.dismiss()
                NotificationCenter.default.post(name: Notification.Name("PreferencesSaved"), object: nil)
            }) {
                Text("설정 저장")
            }
            
            if showSavedMessage {
                Text(changeSaved)
                    .padding()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: showSavedMessage)
                    .frame(height: 30)
            } else {
                Text("").frame(height: 30)
            }
            
        }
        .padding()
        .frame(width: 400)
    }

    func openTeamPickerWindow() {
        if let existingWindow = NSApp.windows.first(where: { $0.title == "응원팀 선택" }) {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }

        let pickerView = TeamPickerView(selectedTeam: $selectedTeam)
        let hostingController = NSHostingController(rootView: pickerView)

        let window = NSWindow(contentViewController: hostingController)
        window.setContentSize(NSSize(width: 250, height: 300))
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.title = "응원팀 선택"

        lazy var statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        window.level = .floating
        window.makeKeyAndOrderFront(nil)
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

        changeSaved = "변경사항이 저장되었습니다."
        
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

        withAnimation {
            showSavedMessage = true
        }

        // 3초 뒤 페이드 아웃
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showSavedMessage = false
            }
        }
    }
}

struct TeamPickerView: View {
    @Binding var selectedTeam: String
    @Environment(\.dismiss) var dismiss

    let teams = ["기아 타이거즈", "두산 베어스", "롯데 자이언츠", "삼성 라이온즈", "키움 히어로즈", "한화 이글스", "KT 위즈", "LG 트윈스", "NC 다이노스", "SSG 랜더스"]

    var body: some View {
        VStack(alignment: .leading) {
            Text("응원팀을 선택하세요")
                .font(.headline)
                .padding(.bottom)

            Picker(selection: $selectedTeam, label: Text("")) {
                ForEach(teams, id: \.self) { team in
                    Text(team).tag(team)
                }
            }
            .pickerStyle(.inline)

            HStack {
                Spacer()
                Button("저장") {
                    UserDefaults.standard.set(selectedTeam, forKey: "selectedTeam")
                                        
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
                    dismiss()
                }
            }
            .padding(.top)
        }
        .padding()
        .frame(width: 250)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
