import SwiftUI

struct PasswordField: View {
    @Binding var password: String
    @State private var showPassword = false
    let placeholder: String

    var body: some View {
        HStack {
            if showPassword {
                TextField(placeholder, text: $password)
            } else {
                SecureField(placeholder, text: $password)
            }
            
            Button(action: {
                showPassword.toggle()
            }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.secondary)
            }
        }
    }
}