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
        VStack(alignment: stackAlignment, spacing: 0) {
            HStack(spacing: 0) {
                if let label = content.label {
                    Badge(text: label, color: Color(.play_greenTag))
                }
                if let introduction = content.introduction {
                    Text(introduction)
                        .srgFont(.H4)
                        .lineLimit(1)
                }
            }
            Text(content.title ?? "")
                .srgFont(.H2)
                .lineLimit(1)
            if let summary = content.summary {
                Text(summary)
                    .srgFont(.body)
                    .lineLimit(3)
                    .multilineTextAlignment(textAlignment)
                    .opacity(0.8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: frameAlignment)
        .foregroundColor(.white)
    }
}

extension FeaturedDescriptionView where Content == FeaturedMediaContent {
    init(media: SRGMedia?, label: String? = nil, alignment: Alignment) {
        self.init(content: FeaturedMediaContent(media: media, label: label), alignment: alignment)
    }
}

extension FeaturedDescriptionView where Content == FeaturedShowContent {
    init(show: SRGShow?, label: String? = nil, alignment: Alignment) {
        self.init(content: FeaturedShowContent(show: show, label: label), alignment: alignment)
    }
}

struct FeaturedDescriptionView_Previews: PreviewProvider {
    static let label = "New"
    
    static var previews: some View {
        Group {
            FeaturedDescriptionView(show: Mock.show(), label: label, alignment: .leading)
            FeaturedDescriptionView(show: Mock.show(), label: label, alignment: .topLeading)
            FeaturedDescriptionView(show: Mock.show(), label: label, alignment: .center)
        }
        .previewLayout(.fixed(width: 1000, height: 600))
        
        Group {
            FeaturedDescriptionView(media: Mock.media(), label: label, alignment: .leading)
            FeaturedDescriptionView(media: Mock.media(), label: label, alignment: .topLeading)
            FeaturedDescriptionView(media: Mock.media(), label: label, alignment: .center)
        }
        .previewLayout(.fixed(width: 1000, height: 600))
    }
}
