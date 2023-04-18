//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

/**
 *  View containing a text view that can display a "show more" button if text is troncated.
 *
 *  Borrowed from https://www.fivestars.blog/articles/trucated-text/ and https://github.com/NuPlay/ExpandableText
 */

/// Behavior: h-exp, v-hug
struct TruncatableTextView: View {
    let content: String
    let lineLimit: Int?
    
    let showMore: () -> Void
    
    var foregroundColor: Color = .srgGray96
    var secondaryColor: Color = .white
    
    @State private var isTruncated = false
    @State private var isFocused = false
    
    init(content: String, lineLimit: Int?, showMore: @escaping () -> Void) {
        // Compact the content to not have "show more" button floating alone at bottom right.
        self.content = content.compacted
        
        self.lineLimit = lineLimit
        self.showMore = showMore
    }
    
    func foregroundColor(_ color: Color) -> Self {
        var truncatableTextView = self
        
        truncatableTextView.foregroundColor = color
        return truncatableTextView
    }
    
    func secondaryColor(_ color: Color) -> Self {
        var truncatableTextView = self
        
        truncatableTextView.secondaryColor = color
        return truncatableTextView
    }
    
    var body: some View {
        Button {
            showMore()
        } label: {
            MainView(content: content, lineLimit: lineLimit, foregroundColor: foregroundColor, secondaryColor: secondaryColor, isTruncated: $isTruncated) {
                showMore()
            }
            .onParentFocusChange { isFocused = $0 }
        }
#if os(tvOS)
        .buttonStyle(TextButtonStyle(focused: isFocused))
#endif
        .disabled(!isTruncated)
    }
    
    /// Behavior: h-exp, v-hug
    fileprivate struct MainView: View {
        let content: String
        let lineLimit: Int?
        let foregroundColor: Color
        let secondaryColor: Color
        @Binding private(set) var isTruncated: Bool
        
        let showMore: () -> Void
        
        @State private var intrinsicSize: CGSize = .zero
        @State private var truncatedSize: CGSize = .zero
        
        private let fontStyle: SRGFont.Style = .body
        private let showMoreButtonString = NSLocalizedString("More", comment: "More label on truncatable text view")
        private let showMoreButtonStringAccessibilityLabel = PlaySRGAccessibilityLocalizedString("More", comment: "More label on truncatable text view")
        
        private func text(lineLimit: Int?) -> some View {
            return Text(content)
                .srgFont(fontStyle)
                .lineLimit(lineLimit)
                .foregroundColor(foregroundColor)
                .multilineTextAlignment(.leading)
        }
        
        var body: some View {
            HStack(spacing: 0) {
                ZStack(alignment: .bottomTrailing) {
                    text(lineLimit: lineLimit)
                        .readSize { size in
                            if size != .zero {
                                truncatedSize = size
                                isTruncated = truncatedSize != intrinsicSize
                            }
                        }
                        .mask(
                            VStack(spacing: 0) {
                                Rectangle()
                                    .foregroundColor(.black)
                                if isTruncated {
                                    BottomMask(fontStyle: fontStyle, showMoreButtonString: showMoreButtonString)
                                }
                            }
                        )
                    
                    if isTruncated {
                        Text(showMoreButtonString)
                            .srgFont(fontStyle)
                            .foregroundColor(secondaryColor)
                            .accessibilityLabel(showMoreButtonStringAccessibilityLabel)
                    }
                }
                .background(
                    text(lineLimit: nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .hidden()
                        .readSize { size in
                            if size != .zero {
                                intrinsicSize = size
                                isTruncated = truncatedSize != intrinsicSize
                            }
                        }
                )
                Spacer(minLength: 0)
            }
        }
        
        /// Behavior: h-exp, v-hug
        struct BottomMask: View {
            let fontStyle: SRGFont.Style
            let showMoreButtonString: String
            
            // Content size changes are tracked to update mask.
            @Environment(\.sizeCategory) private var sizeCategory
            
            var body: some View {
                HStack(alignment: .bottom, spacing: 0) {
                    Rectangle()
                        .foregroundColor(.black)
                    
                    LinearGradient(
                        gradient: Gradient(stops: [
                            Gradient.Stop(color: .black, location: 0),
                            Gradient.Stop(color: .clear, location: 0.8)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: constant(iOS: 32, tvOS: 60), height: showMoreButtonString.heightOfString(usingFontStyle: fontStyle))
                    
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: showMoreButtonString.widthOfString(usingFontStyle: fontStyle), alignment: .center)
                }
                .frame(height: showMoreButtonString.heightOfString(usingFontStyle: fontStyle))
            }
        }
    }
}

// MARK: Preview

struct TruncableTextView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TruncatableTextView(content: "Short description.", lineLimit: 3) {}
            TruncatableTextView(content: String.loremIpsum, lineLimit: 3) {}
            TruncatableTextView(content: String.loremIpsum, lineLimit: 3) {}
                .foregroundColor(.white)
                .secondaryColor(.srgGray96)
            TruncatableTextView(content: String.loremIpsumWithSpacesAndNewLine, lineLimit: 3) {}
        }
        .frame(width: 375)
        .previewLayout(.sizeThatFits)
    }
}
