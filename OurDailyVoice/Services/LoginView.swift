import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    let moodService: MoodService
    let onSignedIn: (String) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome")
                .font(.largeTitle).bold()

            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.caption)
                TextField("you@example.com", text: $email)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                Text("Password")
                    .font(.caption)
                SecureField("••••••••", text: $password)
                    .textContentType(.password)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }
            .padding(.horizontal)

            Button {
                // Placeholder: Hook up email/password auth if desired
                errorMessage = "Email/password login not implemented. Use Bypass for testing."
            } label: {
                Text("Log In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
            }
            .disabled(isLoading)
            .padding(.horizontal)

            Button {
                Task { await signInAnonymously() }
            } label: {
                Text(isLoading ? "Signing in…" : "Bypass (Anonymous)")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.tertiarySystemFill))
                    .cornerRadius(10)
            }
            .disabled(isLoading)
            .padding(.horizontal)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.top, 8)
            }

            Spacer()
        }
        .padding(.top, 40)
    }

    private func signInAnonymously() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            let uid = try await moodService.ensureSignedIn()
            onSignedIn(uid)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    LoginView(moodService: MoodService()) { _ in }
}
