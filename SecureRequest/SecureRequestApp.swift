//
//  SecureRequestApp.swift
//  SecureRequest
//
//  Created by APPLE on 13/09/24.
//

import SwiftUI

@main
struct SecureRequestApp: App {
    @StateObject private var noteViewModel = NoteViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(noteViewModel)
        }
    }
}
