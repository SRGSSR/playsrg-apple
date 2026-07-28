//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SwiftUI

// MARK: View

struct MigrationBanner: View {
    var body: some View {
        mainView()
            .padding(.horizontal, constant(iOS: 20, tvOS: 50))
            .padding(.vertical, constant(iOS: 20, tvOS: 30))
            .background(background())
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            #if os(iOS)
                .onTapGesture(perform: action)
            #endif
    }

    static func size() -> NSCollectionLayoutSize {
        let fontMetrics = SRGFont.metricsForFont(with: .body)
        let height = fontMetrics.scaledValue(for: constant(iOS: 150, tvOS: 220))
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
        #if os(iOS)
            HStack(spacing: 16) {
                icon()
                message()
            }
        #else
            HStack(spacing: 16) {
                message()
                icon()
            }
        #endif
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
                HStack {
                    Spacer()
                    Text("Join")
                        .foregroundColor(.white)
                        .srgFont(.H3)
                        .padding(2)
                }
            #endif
        }
        .frame(maxWidth: .infinity)
    }

    private func action() {}
}

struct MigrationBanner_Previews: PreviewProvider {
    private static let size = MigrationBanner.size().previewSize

    static var previews: some View {
        MigrationBanner()
            .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
