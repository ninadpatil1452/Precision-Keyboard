//
//  Precision_KeyboardApp.swift
//  Precision Keyboard
//
//  Created by Ninad Patil on 08/09/25.
//

import SwiftUI

@main
struct Precision_KeyboardApp: App {
    @StateObject private var session = StudySessionStore()
    var body: some Scene {
        WindowGroup {
            RootView()
              .environmentObject(session)
        }
    }
}
