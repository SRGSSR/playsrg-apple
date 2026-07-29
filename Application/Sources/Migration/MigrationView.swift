//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

extension MigrationView {
    struct Configuration {
        let title: LocalizedStringKey
        let subtitle: LocalizedStringKey
        let footer: LocalizedStringKey?
        let action: Action

        static let learnMore = Configuration(
            title: "Everything you like, even better",
            subtitle: "Your content synced across all devices.",
            footer: nil,
            action: .learnMore
        )
        static let joinBeta = Configuration(
            title: "Help us improve the new App",
            subtitle: "Get ready for fresh features, a new design, and much more. Stay tuned!",
            footer: "Important note: The beta app will replace your Play Suisse App",
            action: .joinBeta
        )
        static let update = Configuration(
            title: "This app will be replaced",
            subtitle: "You can’t use this app any longer from 04.01.2027. Please download the new app.",
            footer: "Important note: The beta app will replace your Play Suisse App",
            action: .update
        )
        static let mandatoryUpdate = Configuration(
            title: "This app no longer exists",
            subtitle: "This app has been replaced by Play+. You can now update or re-download the Play+ app. All your data will be retained.",
            footer: nil,
            action: .mandatoryUpdate
        )
    }

    enum Action {
        case learnMore
        case joinBeta
        case update
        case mandatoryUpdate

        var name: LocalizedStringKey {
            switch self {
            case .learnMore:
                "Okay"
            case .joinBeta:
                "Join Play+ Beta test"
            case .update:
                "Download Play+"
            case .mandatoryUpdate:
                if #available(iOS 17, tvOS 17, *) {
                    "Update now"
                }
                else {
                    "How to get Play+"
                }
            }
        }

        var isCancellable: Bool {
            switch self {
            case .learnMore, .mandatoryUpdate:
                false
            default:
                true
            }
        }
    }
}

struct MigrationView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    let configuration: Configuration

    var body: some View {
        VStack(spacing: 20) {
            descriptionView()
            actionsView()
            footerView()
        }
        .padding(30)
        .background(background())
    }

    private func descriptionView() -> some View {
        VStack(spacing: 24) {
            appIcon()

            Text(configuration.title)
                .srgFont(.H1)

            Text(configuration.subtitle)
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

    private func actionsView() -> some View {
        VStack(spacing: 20) {
            ZStack {
                if #available(iOS 17, tvOS 17, *) {
                    Button(configuration.action.name) {
                        openURL(
                            constant(
                                iOS: ApplicationConfiguration.shared.playPlusStoreURL,
                                tvOS: ApplicationConfiguration.shared.tvPlayPlusStoreURL
                            )
                        )
                    }
                } else {
#if os(iOS)
                    Button(configuration.action.name) {
                        openURL(ApplicationConfiguration.shared.migrationHelpURL)
                    }
#endif
                }
            }
            .buttonStyle(.primary)

            if configuration.action.isCancellable {
                Button("Cancel", action: dismiss.callAsFunction)
                    .srgFont(.H3)
                    .padding(.vertical, 14)
                    .foregroundColor(.white)
            }
        }
    }

    private func background() -> some View {
        Image(.migrationBackground)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .overlay(LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom))
            .ignoresSafeArea()
    }

    @ViewBuilder
    private func footerView() -> some View {
        if let footer = configuration.footer {
            Text(footer)
                .srgFont(.caption)
        }
    }
}

// MARK: Objective-C bridge

@objc final class MigrationViewController: NSObject {
    @objc static func mandatoryUpdateViewController() -> UIViewController {
        viewController(configuration: .mandatoryUpdate)
    }

    static func viewController(configuration: MigrationView.Configuration) -> UIViewController {
        UIHostingController(rootView: MigrationView(configuration: configuration))
    }
}

#Preview("Learn more") {
    MigrationView(configuration: .learnMore)
}

#Preview("Join Beta") {
    MigrationView(configuration: .joinBeta)
}

#Preview("Update") {
    MigrationView(configuration: .update)
}

#Preview("Mandatory update") {
    MigrationView(configuration: .mandatoryUpdate)
}
