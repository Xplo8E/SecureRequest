import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var showError = false
    @Binding var isLoggedIn: Bool
    @State private var errorMessage = ""
    @State private var showingRegistration = false

    var body: some View {
        NavigationView {
            Form {
                TextField("Username", text: $username)
                PasswordField(password: $password, placeholder: "Password")
                Button("Login") {
                    login()
                }
            }
            .navigationTitle("Login")
            .alert(isPresented: $showError) {
                Alert(title: Text("Error"), message: Text("Invalid credentials"), dismissButton: .default(Text("OK")))
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Register") {
                        showingRegistration = true
                    }
                }
            }
            .sheet(isPresented: $showingRegistration) {
                RegistrationView()
            }
        }
    }

    private func login() {
        NetworkManager.shared.request("/login", method: "POST", body: ["username": username, "password": password]) { (result: Result<LoginResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    NetworkManager.shared.setToken(response.token)
                    isLoggedIn = true
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct LoginResponse: Codable {
    let token: String
}
