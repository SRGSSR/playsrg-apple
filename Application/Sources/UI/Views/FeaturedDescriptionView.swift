//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

/// Behavior: h-exp, v-exp
struct FeaturedDescriptionView<Content: FeaturedContent>: View, PrimaryColorSettable, SecondaryColorSettable {
    enum Alignment {
        case leading
        case topLeading
        case center
    }

    let content: Content
    let alignment: Alignment
    let detailed: Bool

    var primaryColor: Color = .srgGrayD2
    var secondaryColor: Color = .srgGray96

    private var stackAlignment: HorizontalAlignment {
        alignment == .center ? .center : .leading
    }

    private var frameAlignment: SwiftUI.Alignment {
        switch alignment {
        case .leading:
            .leading
        case .topLeading:
            .topLeading
        case .center:
            .center
        }
    }

    private var textAlignment: TextAlignment {
        alignment == .center ? .center : .leading
    }

    var body: some View {
        VStack(alignment: stackAlignment, spacing: 6) {
            HStack(spacing: constant(iOS: 8, tvOS: 12)) {
                if let label = content.label {
                    Badge(text: label, color: Color(.srgDarkRed))
                        .layoutPriority(1)
                }
                if let introduction = content.introduction {
                    Text(introduction)
                        .srgFont(.subtitle1)
                        .lineLimit(1)
                        .foregroundColor(secondaryColor)
                }
            }

            VStack(alignment: stackAlignment, spacing: 10) {
                Text(content.title ?? "")
                    .srgFont(.H3)
                    .lineLimit(2)
                    .foregroundColor(primaryColor)
                if detailed, let summary = content.summary {
                    Text(summary)
                        .srgFont(.body)
                        .lineLimit(3)
                        .foregroundColor(secondaryColor)
                }
            }
            .multilineTextAlignment(textAlignment)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: frameAlignment)
    }
}

// MARK: Initializers

extension FeaturedDescriptionView where Content == FeaturedMediaContent {
    init(media: SRGMedia?, style: FeaturedContentCell<FeaturedMediaContent>.Style, label: String? = nil, alignment: Alignment, detailed: Bool) {
        self.init(content: FeaturedMediaContent(media: media, style: style, label: label), alignment: alignment, detailed: detailed)
    }
}

extension FeaturedDescriptionView where Content == FeaturedShowContent {
    init(show: SRGShow?, label: String? = nil, alignment: Alignment, detailed: Bool) {
        self.init(content: FeaturedShowContent(show: show, label: label), alignment: alignment, detailed: detailed)
    }
}

// MARK: Preview

struct FeaturedDescriptionView_Previews: PreviewProvider {
    private static let label = "New label with long text, quite long"

    static var previews: some View {
        Group {
            FeaturedDescriptionView(show: Mock.show(), label: label, alignment: .leading, detailed: true)
            FeaturedDescriptionView(show: Mock.show(), label: label, alignment: .topLeading, detailed: true)
            FeaturedDescriptionView(show: Mock.show(), label: label, alignment: .center, detailed: true)
        }
        .previewLayout(.fixed(width: 800, height: 300))

        Group {
            FeaturedDescriptionView(media: Mock.media(), style: .show, label: label, alignment: .leading, detailed: true)
            FeaturedDescriptionView(media: Mock.media(), style: .show, label: label, alignment: .topLeading, detailed: true)
            FeaturedDescriptionView(media: Mock.media(), style: .show, label: label, alignment: .center, detailed: true)
        }
        .previewLayout(.fixed(width: 800, height: 300))

        Group {
            FeaturedDescriptionView(media: Mock.media(), style: .show, label: label, alignment: .leading, detailed: true)
            FeaturedDescriptionView(media: Mock.media(), style: .show, label: label, alignment: .topLeading, detailed: true)
            FeaturedDescriptionView(media: Mock.media(), style: .show, label: label, alignment: .center, detailed: true)
        }
        .previewLayout(.fixed(width: 300, height: 300))
    }
}
