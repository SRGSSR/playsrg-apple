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
        let displaysBullets: Bool
        let footer: LocalizedStringKey?
        let action: Action?
        let isCancellable: Bool

        static let learnMore = Self(
            title: "Everything you like, even better",
            subtitle: "Your content synced across all devices.",
            displaysBullets: true,
            footer: nil,
            action: .learnMore,
            isCancellable: false
        )
        static let joinBeta = Self(
            title: "Help us improve the new App",
            subtitle: "Get ready for fresh features, a new design, and much more. Stay tuned!",
            displaysBullets: true,
            footer: "Important note: The beta app will replace your Play Suisse App",
            action: .joinBeta,
            isCancellable: true
        )
        static let download = Self(
            title: "This app will be replaced",
            subtitle: "You can’t use this app any longer from 04.01.2027. Please download the new app.",
            displaysBullets: true,
            footer: "Important note: The beta app will replace your Play Suisse App",
            action: downloadAction(),
            isCancellable: true
        )
        static let update = Self(
            title: "This app no longer exists",
            subtitle: "This app has been replaced by Play+. You can now update or re-download the Play+ app. All your data will be retained.",
            displaysBullets: false,
            footer: nil,
            action: updateAction(),
            isCancellable: false
        )

        private static func downloadAction() -> Action? {
            if #available(iOS 17, tvOS 17, *) {
                .download
            } else {
                nil
            }
        }

        private static func updateAction() -> Action? {
            if #available(iOS 17, tvOS 17, *) {
                .update
            } else {
                constant(iOS: .help, tvOS: nil)
            }
        }
    }

    enum Action {
        case learnMore
        case joinBeta
        case download
        case update
        case help

        var name: LocalizedStringKey {
            switch self {
            case .learnMore:
                "Okay"
            case .joinBeta:
                "Join Play+ Beta test"
            case .download:
                "Download Play+"
            case .update:
                "Update now"
            case .help:
                "How to get Play+"
            }
        }

        func callAsFunction() {
            switch self {
            case .learnMore:
                ()
            case .joinBeta:
                ApplicationConfiguration.shared.openPlayPlusTestFlight()
            case .download, .update:
                UIApplication.shared.open(ApplicationConfiguration.shared.playPlusStoreURL)
            case .help:
                UIApplication.shared.open(ApplicationConfiguration.shared.migrationHelpURL)
            }
        }
    }
}

struct MigrationView: View {
    @Environment(\.presentationMode) private var presentationMode

    let configuration: Configuration

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: constant(iOS: 30, tvOS: 60)) {
                    Spacer()
                    descriptionView()
                    Spacer()
                    actionsView()
                    footerView()
                }
                .padding(30)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                .accessibilityAction(.escape) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .background(background())
    }

    private func descriptionView() -> some View {
        VStack(spacing: constant(iOS: 24, tvOS: 48)) {
            appIcon()
            #if os(tvOS)
                .focusable()
            #endif

            Text(configuration.title)
                .srgFont(.H1)
                .multilineTextAlignment(.center)

            Text(configuration.subtitle)
                .srgFont(.body)
                .multilineTextAlignment(.center)

            if configuration.displaysBullets {
                bulletsView()
            }
        }
    }

    private func bulletsView() -> some View {
        VStack(spacing: 40) {
            bulletView(
                icon: .playPlusPlay,
                title: "Live channels now available",
                subtitle: "Sports, broadcast TV and more Sports, broadcast TV and more"
            )
            bulletView(
                icon: .playPlusLogo,
                title: "Live channels now available",
                subtitle: "Sports, broadcast TV and more Sports, broadcast TV and more"
            )
            bulletView(
                icon: .playPlusWaveform,
                title: "Live channels now available",
                subtitle: "Sports, broadcast TV and more Sports, broadcast TV and more"
            )
        }
    }

    private func bulletView(icon: ImageResource, title: LocalizedStringKey, subtitle: LocalizedStringKey) -> some View {
        HStack(spacing: constant(iOS: 20, tvOS: 40)) {
            Image(icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: constant(iOS: 32, tvOS: 64))
                .accessibilityHidden(true)

            VStack(alignment: .leading) {
                Text(title)
                    .srgFont(.H4)
                Text(subtitle)
                    .srgFont(.subtitle1)
            }
        }
    }

    private func appIcon() -> some View {
        Image(.playPlusAppIcon)
            .resizable()
            .frame(width: 120, height: 120)
            .shadow(color: .white, radius: 150)
            .shadow(color: .white, radius: 50)
            .accessibilityHidden(true)
    }

    private func actionsView() -> some View {
        VStack(spacing: 20) {
            if let action = configuration.action {
                Button {
                    action()
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text(action.name)
                    #if os(tvOS)
                        .srgFont(.H3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    #endif
                }
                #if os(iOS)
                .buttonStyle(.primary)
                #endif
            }

            if configuration.isCancellable {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .srgFont(.H3)
                .padding(.vertical, 14)
                #if os(iOS)
                    .foregroundColor(.white)
                #endif
            }
        }
    }

    private func background() -> some View {
        Image(.migrationBackground)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .overlay(LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom))
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func footerView() -> some View {
        if let footer = configuration.footer {
            Text(footer)
                .srgFont(.subtitle2)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: Objective-C bridge

@objc final class MigrationViewController: NSObject {
    @objc static func mandatoryUpdateViewController() -> UIViewController {
        viewController(configuration: .update)
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

#Preview("Download") {
    MigrationView(configuration: .download)
}

#Preview("Update") {
    MigrationView(configuration: .update)
}
