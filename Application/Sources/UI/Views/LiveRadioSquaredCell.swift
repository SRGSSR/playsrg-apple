//
//  LiveRadioSquaredCell.swift
//  PlaySRG
//
//  Created by Mustapha Tarek BEN LECHHAB on 27.01.2025.
//  Copyright © 2025 SRG SSR. All rights reserved.
//

import NukeUI
import SwiftUI

// MARK: View

struct LiveRadioSquaredCell: View {
    @Binding private(set) var media: SRGMedia?

    private let imageSize = CGSize(width: 80, height: 80)
    init(media: SRGMedia?) {
        _media = .constant(media)
    }

    var body: some View {
        VStack {
            if let logoImage = media?.channel?.play_largeLogoImage {
                Image(uiImage: logoImage)
                    .resizable()
                    .frame(size: imageSize)
            }
            Text(media?.channel?.title ?? "")
                .srgFont(.subtitle1, maximumSize: constant(iOS: 15, tvOS: nil))
                .lineLimit(2)
                .foregroundColor(.srgGray96)
            Spacer()
        }
        .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint)
        .redactedIfNil(media)
    }
}

// MARK: Accessibility

private extension LiveRadioSquaredCell {
    var accessibilityLabel: String? {
        media?.channel?.title
    }

    var accessibilityHint: String? {
        PlaySRGAccessibilityLocalizedString("Plays the content.", comment: "Media cell hint")
    }
}

// MARK: Size

enum LiveRadioSquaredCellSize {
    fileprivate static let aspectRatio: CGFloat = 1 / 1.5

    private static let defaultItemWidth: CGFloat = constant(iOS: 88, tvOS: 160)

    static func swimlane(itemWidth: CGFloat = defaultItemWidth) -> NSCollectionLayoutSize {
        LayoutSwimlaneCellSize(itemWidth, aspectRatio, 0)
    }
}

// MARK: Preview

struct LiveRadioSquaredCell_Previews: PreviewProvider {
    private static let media = Mock.media(.square)
    private static let size = LiveRadioSquaredCellSize.swimlane().previewSize

    static var previews: some View {
        LiveRadioSquaredCell(media: media)
            .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
