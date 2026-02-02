//
//  ContentView.swift
//  ForgeTradePro
//
//  Created by Nasbeer Ahammed on 02/02/26.
//

import SwiftUI

struct ContentView: View {
    @State private var shouldNavigate = false

    var body: some View {
        Group {
            if shouldNavigate {
                RootView()
            } else {
                VStack {
                    // Prefer an asset named "AppIconImage" you add to Assets,
                    // falling back to the bundle app icon if available.
                    appIconView
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(radius: 6)

                    Text("ForgeTrade Pro")
                        .font(.title2)
                        .padding(.top, 12)
                }
                .frame(minWidth: 400, minHeight: 300)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(.easeInOut) {
                            shouldNavigate = true
                        }
                    }
                }
            }
        }
        .padding()
    }

    // Try to load a custom image named "AppIconImage" from Assets first.
    // If not present, attempt to load the primary app icon from the bundle on Apple platforms.
    private var appIconView: Image {
        if let _ = NSImage(named: "astraea_logo") {
            return Image("astraea_logo")
        }
        if let icon = NSApplication.shared.applicationIconImage {
            return Image(nsImage: icon)
        }
        // Fallback placeholder if no icon is found
        return Image(systemName: "app.fill")
    }
}

#Preview {
    ContentView()
}
