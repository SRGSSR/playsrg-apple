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
        HStack(spacing: 16) {
            icon()
            message()
        }
        .padding()
        .background(background())
        #if os(iOS)
            .onTapGesture(perform: action)
        #endif
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    static func size() -> NSCollectionLayoutSize {
        let fontMetrics = SRGFont.metricsForFont(with: .body)
        let height = fontMetrics.scaledValue(for: 150)
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

    private func icon() -> some View {
        Image(.playPlusAppIcon)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 75)
    }

    private func message() -> some View {
        VStack(alignment: .leading) {
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
