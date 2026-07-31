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
        let action: Action

        static let learnMore = Self(
            title: "Our new app comes soon!",
            subtitle: "We’re building the next version of our app",
            action: .learnMore
        )
        static let joinBeta = Self(
            title: "Join the Beta Test",
            subtitle: "We’re building the next version of our app",
            action: .joinBeta
        )
        static let download = Self(
            title: "Our new app comes on 2nd of January",
            subtitle: "Update now",
            action: .download
        )
    }

    enum Action {
        case learnMore
        case joinBeta
        case download

        var name: LocalizedStringKey {
            switch self {
            case .learnMore:
                "Learn more"
            case .joinBeta:
                "Join"
            case .download:
                "Download"
            }
        }
    }
}

struct MigrationBanner: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @FirstResponder private var firstResponder
    let configuration: Configuration

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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .responderChain(from: firstResponder)
    }

    static func size() -> NSCollectionLayoutSize {
        let fontMetrics = SRGFont.metricsForFont(with: .body)
        let height = fontMetrics.scaledValue(for: constant(iOS: 120, tvOS: 220)) + 60
        return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(height))
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
                    HStack(spacing: 16) {
                        icon()
                        message()
                    }
                } else {
                    ZStack(alignment: .leading) {
                        message()
                        icon()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            #else
                ZStack {
                    message()
                        .frame(width: 1000)
                    icon()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            #endif
        }
        .padding(.horizontal, constant(iOS: 20, tvOS: 50))
        .padding(.vertical, constant(iOS: 20, tvOS: 30))
        .background(background())
    }

    private func icon() -> some View {
        Image(.playPlusAppIcon)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: constant(iOS: 75, tvOS: 123))
            .accessibilityHidden(true)
    }

    private func message() -> some View {
        VStack(alignment: constant(iOS: .leading, tvOS: .center)) {
            Text(configuration.title)
                .srgFont(.H2)
                .lineLimit(2)
                .layoutPriority(1)
            Text(configuration.subtitle)
                .srgFont(.body)
                .lineLimit(2)
            #if os(iOS)
                button()
            #endif
        }
        .frame(maxWidth: .infinity)
    }

    #if os(iOS)
        private func button() -> some View {
            Button(action: action) {
                Text(configuration.action.name)
                    .foregroundColor(.white)
                    .srgFont(.H3)
                    .padding(2)
            }
            .buttonStyle(.borderedProminent)
            .tint(.srgRed)
            .frame(maxWidth: .infinity, alignment: horizontalSizeClass == .compact ? .trailing : .leading)
        }
    #endif

    private func action() {
        firstResponder.sendAction(#selector(MigrationBannerActions.openMigrationView(sender:event:)), for: MigrationBannerEvent(action: configuration.action))
    }
}

struct MigrationBanner_Previews: PreviewProvider {
    private static let size = MigrationBanner.size().previewSize
    static var previews: some View {
        Group {
            MigrationBanner(configuration: .learnMore)
            MigrationBanner(configuration: .joinBeta)
            MigrationBanner(configuration: .download)
        }
        .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
