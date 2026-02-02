//
//  GoogleAuth.swift
//  ForgeTradePro
//
//  Created by Nasbeer Ahammed on 02/02/26.
//


import AppKit
import GoogleSignIn

class GoogleAuth {

    static func login(cb: @escaping () -> Void) {
        DispatchQueue.main.async {
            guard NSApplication.shared.activationPolicy() != .prohibited else {
                print("App is not in a UI-capable activation policy.")
                return
            }

            guard let clientID = Bundle.main
                .object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String
            else {
                assertionFailure("GOOGLE_CLIENT_ID not found in Info.plist")
                print("GOOGLE_CLIENT_ID not found in Info.plist")
                return
            }

            // Configure Google Sign-In
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

            // Prefer the key window; fall back to any visible window.
            let window = NSApplication.shared.keyWindow
                ?? NSApplication.shared.windows.first(where: { $0.isVisible })

            guard let presentingWindow = window else {
                print("No visible window available to present Google Sign-In.")
                NSApplication.shared.activate(ignoringOtherApps: true)
                return
            }

            // Present sign-in from the window on the main thread
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingWindow) { result, error in
                if let error {
                    let nsError = error as NSError

                    // Treat common user-cancel cases as benign:
                    // - NSUserCancelledError from Cocoa
                    // - ASWebAuthenticationSession canceledLogin (code 1)
                    let isUserCancelled =
                        (nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError)
                        || (nsError.domain == "com.apple.AuthenticationServices.WebAuthenticationSession" && nsError.code == 1)

                    if isUserCancelled {
                        print("Google Sign-In cancelled by user.")
                        return
                    }

                    print("Google Sign-In error: \(nsError) \(nsError.userInfo)")
                    return
                }

                guard
                    let result = result,
                    let idToken = result.user.idToken?.tokenString
                else {
                    print("Google Sign-In: No result or ID token returned.")
                    return
                }

                // Send ID token to backend
                let body = try! JSONSerialization.data(
                    withJSONObject: ["id_token": idToken]
                )

                API.post("/auth/google", body: body) { res in
                    guard
                        let json = res as? [String: Any],
                        let jwt = json["access_token"] as? String
                    else {
                        print("Invalid backend response")
                        return
                    }

                    API.token = jwt
                    Keychain.save(jwt)
                    cb()
                }
            }
        }
    }
}
