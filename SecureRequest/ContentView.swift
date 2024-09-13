//
//  ContentView.swift
//  SecureRequest
//
//  Created by APPLE on 13/09/24.
//

import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = false
    @EnvironmentObject var noteViewModel: NoteViewModel

    var body: some View {
        Group {
            if isLoggedIn {
                NotesListView()
            } else {
                LoginView(isLoggedIn: $isLoggedIn)
            }
        }
        .onAppear {
            testEncryption()
        }
    }
    
    func testEncryption() {
        let testString = "{\"test\":\"Hello, World!\"}"
        let encrypted = NetworkManager.shared.encrypt(testString)
        print("Test encrypted: \(encrypted)")
        
        NetworkManager.shared.request("/test-encryption", method: "POST", body: ["data": encrypted]) { (result: Result<[String: String], Error>) in
            switch result {
            case .success(let response):
                print("Test decryption response: \(response)")
            case .failure(let error):
                print("Test encryption error: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
}

