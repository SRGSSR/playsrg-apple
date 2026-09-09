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
            title: "Play SRG becomes Play+",
            subtitle: "Play+ is the new Swiss live streaming platform. Soon, discover stories from your region and all over Switzerland.",
            displaysBullets: true,
            footer: nil,
            action: .learnMore,
            isCancellable: false
        )
        static let joinBeta = Self(
            title: "Play SRG becomes Play+",
            subtitle: "Try out the new Swiss live and streaming platform and share your opinion with us!",
            displaysBullets: true,
            footer: "Important note: The beta app will replace your Play Suisse App",
            action: .joinBeta,
            isCancellable: true
        )
        static let download = Self(
            title: "Play SRG becomes Play+",
            subtitle: "Play+ is the new Swiss live streaming platform. Soon, discover stories from your region and all over Switzerland.",
            displaysBullets: true,
            footer: "Important note: The beta app will replace your Play Suisse App",
            action: downloadAction(),
            isCancellable: true
        )
        static let update = Self(
            title: "This app is no longer available",
            subtitle: "Play SRG has been replaced by Play+. You can now update or download the Play+. All your data will remain saved.",
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
                "Back"
            case .joinBeta:
                "I'm testing the app"
            case .download:
                "Learn more"
            case .update:
                "Install Play+"
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
        VStack(alignment: .leading, spacing: 40) {
            bulletView(
                icon: .playPlusPlay,
                title: "All of Switzerland in one app",
                subtitle: "Find RTS, RSI, RTR, SRF, and Play Suisse all in one place"
            )
            bulletView(
                icon: .playPlusLogo,
                title: "More choices for you",
                subtitle: "Live sports, movies, shows, series, podcasts, and more"
            )
            bulletView(
                icon: .playPlusWaveform,
                title: "Free. No subscription required",
                subtitle: "Play+ remains funded by the SSR media license fee"
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
