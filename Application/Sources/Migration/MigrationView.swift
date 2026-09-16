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
            footer: nil,
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
                "Install Play+"
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
        ZStack {
            #if os(iOS)
                mobileBody()
            #else
                tvBody()
            #endif
        }
        .background(background())
    }

    #if os(iOS)
        private func mobileBody() -> some View {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 30) {
                        Spacer()
                        descriptionView()
                        Spacer()
                        actionsView()
                        footerView()
                    }
                    .padding(30)
                    .frame(maxWidth: geometry.size.width, minHeight: geometry.size.height)
                    .accessibilityAction(.escape) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    #else
        private func tvBody() -> some View {
            VStack(spacing: 40) {
                Spacer()
                descriptionView()
                Spacer()
                actionsView()
                footerView()
            }
            .padding(30)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    #endif

    private func descriptionView() -> some View {
        VStack(spacing: constant(iOS: 32, tvOS: 48)) {
            appIcon()

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
        .frame(maxWidth: constant(iOS: 600, tvOS: 1200))
        .fixedSize(horizontal: false, vertical: true)
    }

    private func bulletsView() -> some View {
        VStack(alignment: .leading, spacing: 60) {
            bulletView(
                icon: .playPlusLogo,
                title: "All of Switzerland in one app",
                subtitle: "Find RTS, RSI, RTR, SRF, and Play Suisse all in one place"
            )
            bulletView(
                icon: .playPlusWaveform,
                title: "More choices for you",
                subtitle: "Live sports, movies, shows, series, podcasts, and more"
            )
            bulletView(
                icon: .playPlusPlay,
                title: "Free. No subscription required",
                subtitle: "Play+ remains funded by the SSR media license fee"
            )
        }
    }

    private func bulletView(icon: ImageResource, title: LocalizedStringKey, subtitle: LocalizedStringKey) -> some View {
        HStack(spacing: constant(iOS: 20, tvOS: 40)) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(height: constant(iOS: 32, tvOS: 64))
                .accessibilityHidden(true)

            VStack(alignment: .leading) {
                Text(title)
                    .srgFont(.H4)
                Text(subtitle)
                    .srgFont(constant(iOS: .subtitle1, tvOS: .subtitle2))
            }
        }
    }

    private func appIcon() -> some View {
        let size: CGFloat = constant(iOS: 120, tvOS: 150)
        return Image(.playPlusAppIcon)
            .resizable()
            .frame(width: size, height: size)
            .shadow(color: .white, radius: 150)
            .shadow(color: .white, radius: 50)
            .accessibilityHidden(true)
    }

    private func actionsView() -> some View {
        #if os(iOS)
            mobileActionsView()
        #else
            tvActionsView()
        #endif
    }

    #if os(iOS)
        private func mobileActionsView() -> some View {
            VStack(spacing: 20) {
                if let action = configuration.action {
                    Button {
                        action()
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text(action.name)
                    }
                    .buttonStyle(.primary)
                }

                if configuration.isCancellable {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Okay")
                            .srgFont(.H3)
                    }
                    .padding(.vertical, 14)
                    .foregroundColor(.white)
                }
            }
        }
    #else
        private func tvActionsView() -> some View {
            HStack(spacing: 40) {
                if let action = configuration.action {
                    Button {
                        action()
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text(action.name)
                            .srgFont(.H3)
                    }
                }

                if configuration.isCancellable {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Cancel")
                            .srgFont(.H3)
                    }
                }
            }
        }
    #endif

    private func background() -> some View {
        Image(.migrationBackground)
            .resizable()
            .scaledToFill()
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
        HostingController(rootView: MigrationView(configuration: configuration))
    }
}

#Preview("Learn more") {
    MigrationView(configuration: .learnMore)
}

#Preview("Join beta") {
    MigrationView(configuration: .joinBeta)
}

#Preview("Download") {
    MigrationView(configuration: .download)
}

#Preview("Update") {
    MigrationView(configuration: .update)
}
