//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import NukeUI
import SRGAppearanceSwift
import SwiftUI

// MARK: Contract

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

// MARK: View

/// Behavior: h-hug, v-hug
struct SectionShowHeaderView: View {
    let section: Content.Section
    let show: SRGShow
    
    fileprivate static let verticalSpacing: CGFloat = constant(iOS: 18, tvOS: 24)
    
    @Environment(\.uiHorizontalSizeClass) private var horizontalSizeClass
    
    private var direction: StackDirection {
        return (horizontalSizeClass == .compact) ? .vertical : .horizontal
    }
    
    private var alignment: StackAlignment {
        return (horizontalSizeClass == .compact) ? .center : .leading
    }
    
    private var imageUrl: URL? {
        return url(for: show.image, size: .medium)
    }
    
    var body: some View {
        Stack(direction: direction, alignment: alignment, spacing: 0) {
            ImageView(source: imageUrl)
                .aspectRatio(16 / 9, contentMode: .fit)
                .overlay(ImageOverlay(horizontalSizeClass: horizontalSizeClass))
                .adaptiveMainFrame(for: horizontalSizeClass)
                .layoutPriority(1)
            VStack(spacing: Self.verticalSpacing) {
                DescriptionView(section: section)
                ShowAccessButton(show: show)
            }
            .padding(.horizontal, constant(iOS: 16, tvOS: 80))
            .padding(.vertical)
            .frame(maxWidth: .infinity)
        }
        .padding(.bottom, constant(iOS: 20, tvOS: 50))
        .focusable()
    }
    
    /// Behavior: h-exp, v-exp
    private struct ImageOverlay: View {
        let horizontalSizeClass: UIUserInterfaceSizeClass
        
        var body: some View {
            if horizontalSizeClass == .regular {
                LinearGradient(colors: [.clear, .srgGray16], startPoint: .center, endPoint: .trailing)
            }
        }
    }
    
    /// Behavior: h-hug, v-hug
    private struct DescriptionView: View {
        let section: Content.Section
        
        var body: some View {
            VStack(spacing: SectionShowHeaderView.verticalSpacing) {
                if let title = section.properties.title {
                    Text(title)
                        .srgFont(.H2)
                        .lineLimit(2)
                        // Fix sizing issue, see https://swiftui-lab.com/bug-linelimit-ignored/. The size is correct
                        // when calculated with a `UIHostingController`, but without this the text does not occupy
                        // all lines it could.
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.srgGrayD2)
                }
                if let summary = section.properties.summary {
                    Text(summary)
                        .srgFont(.body)
                        .lineLimit(6)
                        // See above
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.srgGray96)
                }
            }
        }
    }
    
    /// Behavior: h-hug, v-hug
    private struct ShowAccessButton: View {
        let show: SRGShow
        
        @State private var isFocused = false
        @FirstResponder private var firstResponder
        
        var accessibilityLabel: String? {
            return show.title
        }
        
        var accessibilityHint: String? {
            return PlaySRGAccessibilityLocalizedString("Opens show details.", comment: "Show button hint")
        }
        
        var body: some View {
            SimpleButton(icon: .episodes, label: show.title) {
                firstResponder.sendAction(#selector(SectionShowHeaderViewAction.openShow(sender:event:)), for: OpenShowEvent(show: show))
            }
            .frame(maxWidth: 350)
            .responderChain(from: firstResponder)
        }
    }
}

// MARK: Helpers

private extension View {
    func adaptiveMainFrame(for horizontalSizeClass: UIUserInterfaceSizeClass?) -> some View {
        return Group {
            if horizontalSizeClass == .compact {
                self
            }
            else {
                frame(height: constant(iOS: 200, tvOS: 400), alignment: .top)
            }
        }
    }
}

// MARK: Size

enum SectionShowHeaderViewSize {
    static func recommended(for section: Content.Section, show: SRGShow?, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutSize {
        if let show {
            let fittingSize = CGSize(width: layoutWidth, height: UIView.layoutFittingExpandedSize.height)
            let size = SectionShowHeaderView(section: section, show: show).adaptiveSizeThatFits(in: fittingSize, for: horizontalSizeClass)
            return NSCollectionLayoutSize(widthDimension: .absolute(layoutWidth), heightDimension: .absolute(size.height))
        }
        else {
            return NSCollectionLayoutSize(widthDimension: .absolute(layoutWidth), heightDimension: .absolute(LayoutHeaderHeightZero))
        }
    }
}

// MARK: Preview

struct SectionShowHeaderView_Previews: PreviewProvider {
    static var previews: some View {
#if os(tvOS)
        SectionShowHeaderView(section: .content(Mock.contentSection()), show: Mock.show())
            .previewLayout(.sizeThatFits)
#else
        SectionShowHeaderView(section: .content(Mock.contentSection()), show: Mock.show())
            .frame(width: 1000)
            .previewLayout(.sizeThatFits)
            .environment(\.horizontalSizeClass, .regular)
        
        SectionShowHeaderView(section: .content(Mock.contentSection()), show: Mock.show())
            .frame(width: 375)
            .previewLayout(.sizeThatFits)
            .environment(\.horizontalSizeClass, .compact)
#endif
    }
}
