//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SwiftUI

// MARK: Contract

@objc protocol MigrationBannerActions: AnyObject {
    func openMigrationView(sender: Any?, event: MigrationBannerEvent?)
}

final class MigrationBannerEvent: UIEvent {
    let action: MigrationBanner.Action

    init(action: MigrationBanner.Action) {
        self.action = action
        super.init()
    }

    override init() {
        fatalError("init() is not available")
    }
}

// MARK: View

extension MigrationBanner {
    struct Configuration {
        let title: LocalizedStringKey
        let subtitle: LocalizedStringKey
        let icon: ImageResource
        let action: Action

        static let learnMore = Self(
            title: "Play SRG is becoming Play+",
            subtitle: "Soon you'll find everything from SRG and more on Play+!",
            icon: .playPlusAppIcon,
            action: .learnMore
        )
        static let joinBeta = Self(
            title: "Play+ is coming soon",
            subtitle: "Discover the new app in preview and share your opinion with us!",
            icon: .playPlusAppIcon,
            action: .joinBeta
        )
        static let download = Self(
            title: "Play SRG is becoming Play+",
            subtitle: "In a few days, you can find all of SRG's offerings, and more, on Play+.",
            icon: .playPlusAppIcon,
            action: .download
        )
        static let feedback = Self(
            title: "What do you think of Play?",
            subtitle: "We'd love to hear your opinion!",
            icon: .appIcon,
            action: .feedback
        )
    }

    enum Action {
        case learnMore
        case joinBeta
        case download
        case feedback

        var name: LocalizedStringKey {
            switch self {
            case .learnMore:
                "Learn more"
            case .joinBeta:
                "Learn more"
            case .download:
                "Learn more"
            case .feedback:
                "To the survey"
            }
        }
    }
}

struct MigrationBanner: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @FirstResponder private var firstResponder
    let configuration: Configuration

    private var multilineTextAlignment: TextAlignment {
        horizontalSizeClass == .compact ? .leading : .center
    }

    var body: some View {
        ZStack {
            #if os(iOS)
                mainView()
            #else
                Button(action: action) {
                    mainView()
                }
                .buttonStyle(.card)
            #endif
        }
        .padding(.top, 40)
        .responderChain(from: firstResponder)
    }

    static func size(for configuration: Configuration, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutSize {
        let fittingSize = CGSize(width: layoutWidth, height: UIView.layoutFittingExpandedSize.height)
        let size = Self(configuration: configuration).adaptiveSizeThatFits(in: fittingSize, for: horizontalSizeClass)
        return NSCollectionLayoutSize(widthDimension: .absolute(size.width), heightDimension: .absolute(size.height))
    }

    private func background() -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(colors: [
                    .migrationBannerTopLeading, .migrationBannerBottomTrailing
                ], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .shadow(color: .white.opacity(0.1), radius: 1)
    }

    private func mainView() -> some View {
        ZStack {
            #if os(iOS)
                if horizontalSizeClass == .compact {
                    compactMainView()
                        .onTapGesture(perform: action)
                } else {
                    regularMainView()
                }
            #else
                tvMainView()
            #endif
        }
        .padding(.horizontal, constant(iOS: 20, tvOS: 50))
        .padding(.vertical, constant(iOS: 20, tvOS: 30))
        .background(background())
    }

    #if os(iOS)
        private func compactMainView() -> some View {
            HStack(alignment: .top, spacing: 16) {
                icon()

                VStack(alignment: .leading) {
                    title()
                    subtitle()
                    link()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }

        private func regularMainView() -> some View {
            HStack(spacing: 16) {
                VStack(alignment: .center) {
                    title()
                    subtitle()
                    button()
                }
                .frame(maxWidth: .infinity, alignment: .center)

                icon()
            }
        }
    #else
        private func tvMainView() -> some View {
            ZStack {
                VStack {
                    title()
                    subtitle()
                }
                .frame(width: 1000)

                icon()
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    #endif

    private func icon() -> some View {
        Image(configuration.icon)
            .resizable()
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .scaledToFit()
            .frame(height: constant(iOS: 75, tvOS: 123))
            .accessibilityHidden(true)
    }

    private func title() -> some View {
        Text(configuration.title)
            .srgFont(.H3)
            .multilineTextAlignment(multilineTextAlignment)
    }

    private func subtitle() -> some View {
        Text(configuration.subtitle)
            .srgFont(.body)
            .multilineTextAlignment(multilineTextAlignment)
    }

    #if os(iOS)
        private func link() -> some View {
            Text(configuration.action.name)
                .padding(2)
                .foregroundColor(.white)
                .srgFont(.H3)
                .accessibilityAddTraits(.isButton)
        }

        private func button() -> some View {
            Button(action: action) {
                Text(configuration.action.name)
                    .padding(2)
            }
            .buttonStyle(.borderedProminent)
            .tint(.srgRed)
            .foregroundColor(.white)
            .srgFont(.H3)
        }
    #endif

    private func action() {
        firstResponder.sendAction(#selector(MigrationBannerActions.openMigrationView(sender:event:)), for: MigrationBannerEvent(action: configuration.action))
    }
}

#Preview("Learn more") {
    MigrationBanner(configuration: .learnMore)
}

#Preview("Join beta") {
    MigrationBanner(configuration: .joinBeta)
}

#Preview("Download") {
    MigrationBanner(configuration: .download)
}

#Preview("Update") {
    MigrationBanner(configuration: .feedback)
}
