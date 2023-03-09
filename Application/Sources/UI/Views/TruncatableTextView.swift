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
    
    @State private var isTruncated = false
    @State private var isFocused = false
    
    init(content: String, lineLimit: Int?, showMore: @escaping () -> Void) {
        // Compact the content to not have "show more" button floating alone at bottom right.
        self.content = content
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .newlines)
        
        self.lineLimit = lineLimit
        self.showMore = showMore
    }
    
    var body: some View {
        Button {
            showMore()
        } label: {
            MainView(content: content, lineLimit: lineLimit, isTruncated: $isTruncated) {
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
        @Binding private(set) var isTruncated: Bool
        
        let showMore: () -> Void
        
        @State private var intrinsicSize: CGSize = .zero
        @State private var truncatedSize: CGSize = .zero
        
        private let fontStyle: SRGFont.Style = .body
        private let showMoreButtonString = NSLocalizedString("More", comment: "More button label")
        
        private func text(lineLimit: Int?) -> some View {
            return Text(content)
                .srgFont(fontStyle)
                .lineLimit(lineLimit)
                .foregroundColor(.srgGray96)
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
                            .foregroundColor(.white)
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
                    .frame(width: 32, height: showMoreButtonString.heightOfString(usingFontStyle: fontStyle))
                    
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
        }
        .frame(width: 375)
        .previewLayout(.sizeThatFits)
    }
}
