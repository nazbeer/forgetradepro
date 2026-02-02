//
//  ContentView 2.swift
//  ForgeTradePro
//
//  Created by Nasbeer Ahammed on 02/02/26.
//

import SwiftUI

struct RootView: View {
    @State private var loggedIn = API.token != nil
    @State private var isRegister = false
    @State private var mobile: String = ""
    @State private var password: String = ""
    @State private var email: String = ""
    @State private var status: String = ""
    @State private var isLoading: Bool = false

    var body: some View {
        if loggedIn {
            DashboardView()
        } else {
            VStack(spacing: 14) {
                Text("ForgeTrade Pro")
                    .font(.largeTitle)

                Text(isRegister ? "Create account" : "Sign in")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 10) {
                    TextField("Mobile number", text: $mobile)
                        .textFieldStyle(.roundedBorder)

                    if isRegister {
                        TextField("Email (optional)", text: $email)
                            .textFieldStyle(.roundedBorder)
                    }

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                .frame(width: 320)

                HStack(spacing: 10) {
                    Button(isRegister ? "Register" : "Login") {
                        submitPhoneAuth()
                    }
                    .keyboardShortcut(.return)
                    .disabled(isLoading)

                    Button(isRegister ? "Have an account? Login" : "New here? Register") {
                        withAnimation(.easeInOut) {
                            isRegister.toggle()
                            status = ""
                        }
                    }
                    .buttonStyle(.link)
                    .disabled(isLoading)
                }

                Divider()
                    .frame(width: 320)

                Button("Sign in with Google") {
                    status = ""
                    isLoading = true
                    GoogleAuth.login {
                        isLoading = false
                        loggedIn = true
                    }
                }
                .disabled(isLoading)

                Button("Continue as Guest") {
                    // Immediately show Dashboard (guest/offline mode).
                    API.token = nil
                    Keychain.delete()
                    loggedIn = true

                    // Best-effort: get a guest token to unlock analytics/trading if backend is reachable.
                    status = ""
                    isLoading = true
                    API.post("/auth/guest", body: nil) { res in
                        isLoading = false

                        guard
                            let json = res as? [String: Any],
                            let jwt = json["access_token"] as? String
                        else {
                            // Non-blocking: dashboard still shows market chart without auth.
                            return
                        }

                        API.token = jwt
                        Keychain.save(jwt)
                    }
                }
                .disabled(isLoading)

                if !status.isEmpty {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(width: 360)
                }

                Spacer(minLength: 0)
            }
            .padding(20)
            .frame(width: 420, height: 360)
        }
    }

    private func submitPhoneAuth() {
        status = ""

        let trimmedMobile = mobile.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password

        guard !trimmedMobile.isEmpty else {
            status = "Please enter your mobile number."
            return
        }
        guard trimmedPassword.count >= 6 else {
            status = "Password must be at least 6 characters."
            return
        }

        var payload: [String: Any] = [
            "mobile": trimmedMobile,
            "password": trimmedPassword
        ]
        if isRegister {
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedEmail.isEmpty {
                payload["email"] = trimmedEmail
            }
        }

        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            status = "Failed to build request."
            return
        }

        isLoading = true
        let path = isRegister ? "/auth/register" : "/auth/login"
        API.post(path, body: body) { res in
            isLoading = false

            guard
                let json = res as? [String: Any],
                let jwt = json["access_token"] as? String
            else {
                if let json = res as? [String: Any], let detail = json["detail"] as? String {
                    status = detail
                } else {
                    status = "Auth failed."
                }
                return
            }

            API.token = jwt
            Keychain.save(jwt)
            loggedIn = true
        }
    }
}
