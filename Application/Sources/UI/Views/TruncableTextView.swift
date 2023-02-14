//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

/**
 *  View containing a text view that can display a "show more" button if text is troncated.
 *
 *  Borrowed from https://www.fivestars.blog/articles/trucated-text/ and https://github.com/NuPlay/ExpandableText
 */
struct TruncableTextView: View {
    let content: String
    let lineLimit: Int?
    
    @State private var intrinsicSize: CGSize = .zero
    @State private var truncatedSize: CGSize = .zero
    @State private var isTruncated = false
    
    let showMore: () -> Void
    
    private let fontStyle: SRGFont.Style = .body
    private let showMoreButtonString = NSLocalizedString("Show more", comment: "Show more button label")
    private let showMoreBackgroundColor: Color = .srgGray16
    
    private func text(lineLimit: Int?) -> some View {
        return Text(content)
            .srgFont(fontStyle)
            .lineLimit(lineLimit)
            .foregroundColor(.srgGray96)
            .multilineTextAlignment(.leading)
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            text(lineLimit: lineLimit)
                .readSize { size in
                    truncatedSize = size
                    isTruncated = truncatedSize != intrinsicSize
                }
                .mask(
                    VStack(spacing: 0) {
                        Rectangle()
                            .foregroundColor(showMoreBackgroundColor)
                        
                        HStack(spacing: 0) {
                            Rectangle()
                                .foregroundColor(showMoreBackgroundColor)
                            if isTruncated {
                                HStack(alignment: .bottom, spacing: 0) {
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            Gradient.Stop(color: showMoreBackgroundColor, location: 0),
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
                            }
                        }
                        .frame(height: showMoreButtonString.heightOfString(usingFont: fontToUIFont(font: SRGFont.font(fontStyle))))
                    }
                )
            
            if isTruncated {
                Button(action: {
                    showMore()
                }, label: {
                    Text(showMoreButtonString)
                        .srgFont(fontStyle)
                        .foregroundColor(.white)
                })
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
    }
    
    private func fontToUIFont(font: Font) -> UIFont {
        switch font {
        case .largeTitle:
            return UIFont.preferredFont(forTextStyle: .largeTitle)
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
