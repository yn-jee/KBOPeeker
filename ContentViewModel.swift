//
//  ContentViewModel.swift
//  KBOPeeker
//
//  Created by 나윤지 on 3/26/25.
//

import Foundation

class ContentViewModel: ObservableObject {
    @Published var showTeamPicker = false
    @Published var showSettings = false
    
    var needsExpandedHeight: Bool {
        return showTeamPicker || showSettings
    }
}
