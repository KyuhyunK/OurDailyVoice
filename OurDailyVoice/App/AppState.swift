//
//  AppState.swift
//  OurDailyVoice
//
//  Created by Kyu Kim on 2/18/26.
//

import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var selectedSite: Site? = nil
    @Published var selectedRoom: String? = nil
    @Published var isSupervisorReady: Bool = false
    @Published var isAdminUnlocked: Bool = false
}
