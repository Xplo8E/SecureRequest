import SwiftUI
import Foundation

struct RegistrationView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                TextField("Username", text: $username)
                PasswordField(password: $password, placeholder: "Password")
                Button("Register") {
                    register()
                }
            }
            .navigationTitle("Register")
            .alert(isPresented: $showError) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func register() {
        let body = ["username": username, "password": password]
        NetworkManager.shared.request("/register", method: "POST", body: body) { (result: Result<EmptyResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}


