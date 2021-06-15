//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

/// Behavior: h-exp, v-exp
struct FeaturedDescriptionView<Content: FeaturedContent>: View {
    enum Alignment {
        case leading
        case topLeading
        case center
    }
    
    let content: Content
    let alignment: Alignment
    let detailed: Bool
    
    private var stackAlignment: HorizontalAlignment {
        return alignment == .center ? .center : .leading
    }
    
    private var frameAlignment: SwiftUI.Alignment {
        switch alignment {
        case .leading:
            return .leading
        case .topLeading:
            return .topLeading
        case .center:
            return .center
        }
    }
    
    private var textAlignment: TextAlignment {
        return alignment == .center ? .center : .leading
    }
    
    var body: some View {
        VStack(alignment: stackAlignment, spacing: 6) {
            HStack(spacing: constant(iOS: 8, tvOS: 12)) {
                if let label = content.label {
                    Badge(text: label, color: Color(.play_green))
                }
                if let introduction = content.introduction {
                    Text(introduction)
                        .srgFont(.subtitle2)
                        .lineLimit(1)
                        .foregroundColor(Color.srgGray4)
                }
            }
            
            VStack(alignment: stackAlignment, spacing: 10) {
                Text(content.title ?? "")
                    .srgFont(.H3)
                    .lineLimit(2)
                    .foregroundColor(Color.srgGray5)
                if detailed, let summary = content.summary {
                    Text(summary)
                        .srgFont(.body)
                        .lineLimit(3)
                        .foregroundColor(Color.srgGray4)
                }
            }
            .multilineTextAlignment(textAlignment)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: frameAlignment)
    }
}

extension FeaturedDescriptionView where Content == FeaturedMediaContent {
    init(media: SRGMedia?, label: String? = nil, alignment: Alignment, detailed: Bool) {
        self.init(content: FeaturedMediaContent(media: media, label: label), alignment: alignment, detailed: detailed)
    }
}

extension FeaturedDescriptionView where Content == FeaturedShowContent {
    init(show: SRGShow?, label: String? = nil, alignment: Alignment, detailed: Bool) {
        self.init(content: FeaturedShowContent(show: show, label: label), alignment: alignment, detailed: detailed)
    }
}

struct FeaturedDescriptionView_Previews: PreviewProvider {
    static let label = "New"
    
    static var previews: some View {
        Group {
            FeaturedDescriptionView(show: Mock.show(), label: label, alignment: .leading, detailed: true)
            FeaturedDescriptionView(show: Mock.show(), label: label, alignment: .topLeading, detailed: true)
            FeaturedDescriptionView(show: Mock.show(), label: label, alignment: .center, detailed: true)
        }
        .previewLayout(.fixed(width: 800, height: 300))
        
        Group {
            FeaturedDescriptionView(media: Mock.media(), label: label, alignment: .leading, detailed: true)
            FeaturedDescriptionView(media: Mock.media(), label: label, alignment: .topLeading, detailed: true)
            FeaturedDescriptionView(media: Mock.media(), label: label, alignment: .center, detailed: true)
        }
        .previewLayout(.fixed(width: 800, height: 300))
    }
}
