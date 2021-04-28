//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

protocol FeaturedContent {
    var introduction: String? { get }
    var title: String? { get }
    var summary: String? { get }
    var tags: [FeaturedDescriptionView.Tag] { get }
}

/// Behavior: h-exp, v-exp
struct FeaturedDescriptionView: View {
    enum Alignment {
        case leading
        case topLeading
        case center
    }
    
    struct Tag {
        let text: String
        let color: UIColor
    }
    
    let content: FeaturedContent
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
        VStack(alignment: stackAlignment) {
            Text(content.introduction ?? "")
                .srgFont(.H4)
                .lineLimit(1)
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

extension FeaturedDescriptionView {
    struct MediaContent: FeaturedContent {
        let media: SRGMedia?
        
        var introduction: String? {
            return MediaDescription.title(for: media, style: .show)
        }
        
        var title: String? {
            return MediaDescription.subtitle(for: media, style: .show)
        }
        
        var summary: String? {
            return MediaDescription.summary(for: media)
        }
        
        var tags: [FeaturedDescriptionView.Tag] {
            return []
        }
    }
    
    init(media: SRGMedia?, alignment: Alignment) {
        self.init(content: MediaContent(media: media), alignment: alignment)
    }
}

extension FeaturedDescriptionView {
    struct ShowContent: FeaturedContent {
        let show: SRGShow?
        
        var introduction: String? {
            return nil
        }
        
        var title: String? {
            return show?.title
        }
        
        var summary: String? {
            return show?.summary
        }
        
        var tags: [FeaturedDescriptionView.Tag] {
            return []
        }
    }
    
    init(show: SRGShow?, alignment: Alignment) {
        self.init(content: ShowContent(show: show), alignment: alignment)
    }
}

struct FeaturedDescriptionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FeaturedDescriptionView(show: Mock.show(), alignment: .leading)
            FeaturedDescriptionView(show: Mock.show(), alignment: .topLeading)
            FeaturedDescriptionView(show: Mock.show(), alignment: .center)
        }
        .previewLayout(.fixed(width: 1000, height: 600))
        
        Group {
            FeaturedDescriptionView(media: Mock.media(), alignment: .leading)
            FeaturedDescriptionView(media: Mock.media(), alignment: .topLeading)
            FeaturedDescriptionView(media: Mock.media(), alignment: .center)
        }
        .previewLayout(.fixed(width: 1000, height: 600))
    }
}
