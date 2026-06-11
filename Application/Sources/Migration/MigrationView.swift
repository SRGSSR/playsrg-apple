//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct MigrationView: View {
    private let appConfiguration = ApplicationConfiguration.shared

    @Environment(\.openURL) private var openURL

    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 32
    @ScaledMetric(relativeTo: .body) private var descriptionSize: CGFloat = 14

    var body: some View {
        VStack(spacing: .zero) {
            VStack(spacing: 24) {
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

                Text(appConfiguration.migrationScreenTitle)
                    .srgFont(family: .text, weight: .srg_bold, fixedSize: titleSize)

                Text(appConfiguration.migrationScreenDescription)
                    .srgFont(family: .text, weight: .srg_medium, fixedSize: descriptionSize)
            }
            .multilineTextAlignment(.center)
            .frame(maxHeight: .infinity)

            Group {
                if #available(iOS 17, *) {
                    Button(appConfiguration.migrationScreenPrimaryAction) {
                        if let url = appConfiguration.playPlusStoreURL {
                            openURL(url)
                        }
                    }
                } else {
                    Button(appConfiguration.migrationScreenSecondaryAction) {
                        if let url = appConfiguration.migrationHelpURL {
                            openURL(url)
                        }
                    }
                }
            }
            .buttonStyle(MigrationPrimaryButtonStyle())
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Image(.migrationBackground)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
        )
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
