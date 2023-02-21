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
struct TruncableTextView: View {
    let content: String
    let lineLimit: Int?
    
    let showMore: () -> Void
    
    @State private var isTruncated = false
#if os(tvOS)
    @State private var isFocused = false
#endif
    
    var body: some View {
#if os(iOS)
        MainView(content: content, lineLimit: lineLimit, isTruncated: $isTruncated) {
            showMore()
        }
#else
        Button {
            showMore()
        } label: {
            MainView(content: content, lineLimit: lineLimit, isTruncated: $isTruncated) {
                showMore()
            }
            .onParentFocusChange { isFocused = $0 }
        }
        .buttonStyle(TextButtonStyle(focused: isFocused))
        .disabled(!isTruncated)
#endif
    }
    
    /// Behavior: h-exp, v-hug
    fileprivate struct MainView: View {
        let content: String
        let lineLimit: Int?
        @Binding var isTruncated: Bool
        
        @State private var intrinsicSize: CGSize = .zero
        @State private var truncatedSize: CGSize = .zero
        
        let showMore: () -> Void
        
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
                            truncatedSize = size
                            isTruncated = truncatedSize != intrinsicSize
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
#if os(iOS)
                        Button(action: {
                            showMore()
                        }, label: {
                            Text(showMoreButtonString)
                                .srgFont(fontStyle)
                                .foregroundColor(.white)
                        })
#else
                        Text(showMoreButtonString)
                            .srgFont(fontStyle)
                            .foregroundColor(.white)
#endif
                    }
                }
                .background(
                    text(lineLimit: nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .hidden()
                        .readSize { size in
                            intrinsicSize = size
                            isTruncated = truncatedSize != intrinsicSize
                        }
                )
                Spacer(minLength: 0)
            }
        }
        
        /// Behavior: h-exp, v-hug
        struct BottomMask: View {
            let fontStyle: SRGFont.Style
            let showMoreButtonString: String
            
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
                    .frame(width: 32, height: showMoreButtonString.heightOfString(usingFont: fontToUIFont(font: SRGFont.font(fontStyle))))
                    
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: showMoreButtonString.widthOfString(usingFont: fontToUIFont(font: SRGFont.font(fontStyle))), alignment: .center)
                }
                .frame(height: showMoreButtonString.heightOfString(usingFont: fontToUIFont(font: SRGFont.font(fontStyle))))
            }
            
            private func fontToUIFont(font: Font) -> UIFont {
                switch font {
#if os(iOS)
                case .largeTitle:
                    return UIFont.preferredFont(forTextStyle: .largeTitle)
#endif
                case .title:
                    return UIFont.preferredFont(forTextStyle: .title1)
                case .title2:
                    return UIFont.preferredFont(forTextStyle: .title2)
                case .title3:
                    return UIFont.preferredFont(forTextStyle: .title3)
                case .headline:
                    return UIFont.preferredFont(forTextStyle: .headline)
                case .subheadline:
                    return UIFont.preferredFont(forTextStyle: .subheadline)
                case .callout:
                    return UIFont.preferredFont(forTextStyle: .callout)
                case .caption:
                    return UIFont.preferredFont(forTextStyle: .caption1)
                case .caption2:
                    return UIFont.preferredFont(forTextStyle: .caption2)
                case .footnote:
                    return UIFont.preferredFont(forTextStyle: .footnote)
                case .body:
                    return UIFont.preferredFont(forTextStyle: .body)
                default:
                    return UIFont.preferredFont(forTextStyle: .body)
                }
            }
        }
    }
}

// MARK: Preview

struct TruncableTextView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TruncableTextView(content: "Short description.", lineLimit: 3) {}
            TruncableTextView(content: String.loremIpsum, lineLimit: 3) {}
        }
        .frame(width: 375)
        .previewLayout(.sizeThatFits)
    }
}
