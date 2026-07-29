//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SwiftUI

// MARK: View

struct MigrationBanner: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isPresented = false

    var body: some View {
        ZStack {
            #if os(iOS)
                mainView()
                    .sheet(isPresented: $isPresented) {
                        MigrationView() // TODO: Put the right view in function of the scenario.
                    }
            #else
                Button(action: action) {
                    mainView()
                }
                .buttonStyle(.card)
                .fullScreenCover(isPresented: $isPresented) {
                    MigrationView() // TODO: Put the right view in function of the scenario.
                }
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
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
    }

    private func message() -> some View {
        VStack(alignment: constant(iOS: .leading, tvOS: .center)) {
            Text("Join the Beta Team")
                .lineLimit(1)
                .srgFont(.H2)
            Text("We're building the next version of our app")
                .lineLimit(2)
                .srgFont(.body)
            #if os(iOS)
                joinButton()
            #endif
        }
        .frame(maxWidth: .infinity)
    }

    #if os(iOS)
        private func joinButton() -> some View {
            Button(action: action) {
                Text("Join")
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
        isPresented.toggle()
    }
}

struct MigrationBanner_Previews: PreviewProvider {
    private static let size = MigrationBanner.size().previewSize

    static var previews: some View {
        MigrationBanner()
            .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
