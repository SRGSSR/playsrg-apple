//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

@objc protocol SectionShowHeaderViewAction {
    func openShow(sender: Any?, event: OpenShowEvent?)
}

class OpenShowEvent: UIEvent {
    let show: SRGShow
    
    init(show: SRGShow) {
        self.show = show
        super.init()
    }
    
    override init() {
        fatalError("init() is not available")
    }
}

// Behavior: h-hug, v-hug
struct SectionShowHeaderView: View {
    let section: Content.Section
    let show: SRGShow
    
    var body: some View {
        VStack(spacing: 20) {
            ImageView(url: show.imageUrl(for: .large))
                .aspectRatio(SectionShowHeaderViewSize.aspectRatio, contentMode: .fit)
                .background(Color.white.opacity(0.1))
            VStack(spacing: 12) {
                DescriptionView(section: section)
                ShowAccessButton(show: show)
            }
            .padding(.horizontal, SectionShowHeaderViewSize.horizontalMargin)
            .padding(.bottom, SectionShowHeaderViewSize.verticalMargin)
            .frame(maxWidth: .infinity)
        }
    }
    
    // Behavior: h-hug, v-hug
    private struct DescriptionView: View {
        let section: Content.Section
        
        var body: some View {
            VStack {
                if let title = section.properties.title {
                    Text(title)
                        .srgFont(.H2)
                        .foregroundColor(.white)
                }
                if let summary = section.properties.summary {
                    Text(summary)
                        .srgFont(.body)
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    // Behavior: h-hug, v-hug
    private struct ShowAccessButton: View {
        let show: SRGShow
        
        var body: some View {
            ResponderChain { firstResponder in
                Button {
                    firstResponder.sendAction(#selector(SectionShowHeaderViewAction.openShow(sender:event:)), for: OpenShowEvent(show: show))
                } label: {
                    HStack(spacing: 15) {
                        Image("episodes-22")
                        Text(show.title)
                    }
                    .padding(.horizontal, SectionShowHeaderViewSize.horizontalButtonPadding)
                    .padding(.vertical, SectionShowHeaderViewSize.verticalButtonPadding)
                    .frame(maxWidth: .infinity, minHeight: 45, alignment: .leading)
                    .foregroundColor(.gray)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(LayoutStandardViewCornerRadius)
                }
            }
        }
    }
}

class SectionShowHeaderViewSize: NSObject {
    fileprivate static let aspectRatio: CGFloat = 16 / 9
    
    fileprivate static let horizontalMargin: CGFloat = constant(iOS: 16, tvOS: 80)
    fileprivate static let verticalMargin: CGFloat = constant(iOS: 16, tvOS: 80)
    fileprivate static let horizontalButtonPadding: CGFloat = constant(iOS: 10, tvOS: 16)
    fileprivate static let verticalButtonPadding: CGFloat = constant(iOS: 8, tvOS: 12)
    
    static func recommended(for section: Content.Section, show: SRGShow?, layoutWidth: CGFloat) -> NSCollectionLayoutSize {
        if let show = show {
            let hostController = UIHostingController(rootView: SectionShowHeaderView(section: section, show: show))
            let size = hostController.sizeThatFits(in: CGSize(width: layoutWidth, height: UIView.layoutFittingExpandedSize.height))
            return NSCollectionLayoutSize(widthDimension: .absolute(layoutWidth), heightDimension: .absolute(size.height))
        }
        else {
            return NSCollectionLayoutSize(widthDimension: .absolute(layoutWidth), heightDimension: .absolute(LayoutHeaderHeightZero))
        }
    }
}

struct SectionShowHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        SectionShowHeaderView(section: .content(Mock.contentSection()), show: Mock.show())
            .previewLayout(.sizeThatFits)
    }
}
