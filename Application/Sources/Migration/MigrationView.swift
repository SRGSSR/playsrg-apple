//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct MigrationView: View {
    @Environment(\.openURL) private var openURL

    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 32
    @ScaledMetric(relativeTo: .body) private var descriptionSize: CGFloat = 14

    var body: some View {
        VStack(spacing: .zero) {
            VStack(spacing: 24) {
                appIconView

                Text("This app no longer exists")
                    .srgFont(family: .text, weight: .srg_bold, fixedSize: titleSize)

                Text("This app has been replaced by Play+. You can now update or re-download the Play+ app. All your data will be retained.")
                    .srgFont(family: .text, weight: .srg_medium, fixedSize: descriptionSize)
            }
            .multilineTextAlignment(.center)
            .frame(maxHeight: .infinity)

            ctaButtonView
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundImage)
    }

    @ViewBuilder
    private var appIconView: some View {
        Image(.playPlusAppIcon)
            .resizable()
            .frame(width: 120, height: 120)
            .shadow(color: .white, radius: 180, x: 0, y: 0)
            .shadow(
                color: Color(red: 1, green: 0.82, blue: 0.82).opacity(0.7),
                radius: 83,
                x: 0,
                y: 0
            )
    }

    @ViewBuilder
    private var ctaButtonView: some View {
        Group {
            if #available(iOS 17, *) {
                Button("Update now") {
                    openURL(ApplicationConfiguration.shared.playPlusStoreURL)
                }
            } else {
                Button("How to get Play+") {
                    openURL(ApplicationConfiguration.shared.migrationHelpURL)
                }
            }
        }
        .buttonStyle(MigrationPrimaryButtonStyle())
    }

    @ViewBuilder
    private var backgroundImage: some View {
        Image(.migrationBackground)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .ignoresSafeArea()
    }
}

private struct MigrationPrimaryButtonStyle: ButtonStyle {
    @ScaledMetric(relativeTo: .body) private var titleSize: CGFloat = 16

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .srgFont(family: .text, weight: .srg_bold, fixedSize: titleSize)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
            .background(Color.white)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
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
