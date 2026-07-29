//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct MigrationView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack {
            descriptionView()
            actionView()
        }
        .padding(30)
        .background(background())
    }

    private func descriptionView() -> some View {
        VStack(spacing: 24) {
            appIcon()

            Text("This app no longer exists")
                .srgFont(.H1)

            Text("This app has been replaced by Play+. You can now update or re-download the Play+ app. All your data will be retained.")
                .srgFont(.body)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func appIcon() -> some View {
        VStack(spacing: 50) {
            Image(.playPlusAppIcon)
                .resizable()
                .frame(width: 120, height: 120)
                .shadow(color: .white, radius: 150)
                .shadow(color: .white, radius: 50)
        }
    }

    private func actionView() -> some View {
        ZStack {
            if #available(iOS 17, tvOS 17, *) {
                Button("Update now") {
                    openURL(
                        constant(
                            iOS: ApplicationConfiguration.shared.playPlusStoreURL,
                            tvOS: ApplicationConfiguration.shared.tvPlayPlusStoreURL
                        )
                    )
                }
            } else {
                #if os(iOS)
                    Button("How to get Play+") {
                        openURL(ApplicationConfiguration.shared.migrationHelpURL)
                    }
                #endif
            }
        }
        .buttonStyle(.primary)
    }

    private func background() -> some View {
        Image(.migrationBackground)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .overlay(LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom))
            .ignoresSafeArea()
    }
}

// MARK: Objective-C bridge

@objc final class MigrationViewController: NSObject {
    @objc static func viewController() -> UIViewController {
        UIHostingController(rootView: MigrationView())
    }
}

#Preview {
    MigrationView()
}
