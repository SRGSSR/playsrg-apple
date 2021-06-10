//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

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
    
    var body: some View {
        #if os(tvOS)
        MainView(section: section, show: show)
            .focusable()
        #else
        MainView(section: section, show: show)
        #endif
    }
    
    /// Behavior: h-hug, v-hug
    private struct MainView: View {
        let section: Content.Section
        let show: SRGShow
        
        #if os(iOS)
        @Environment(\.horizontalSizeClass) var horizontalSizeClass
        #endif
        
        var uiHorizontalSizeClass: UIUserInterfaceSizeClass {
            #if os(iOS)
            return UIUserInterfaceSizeClass(horizontalSizeClass)
            #else
            return .regular
            #endif
        }
        
        private var direction: StackDirection {
            #if os(iOS)
            return (horizontalSizeClass == .compact) ? .vertical : .horizontal
            #else
            return .horizontal
            #endif
        }
        
        var body: some View {
            Stack(direction: direction, spacing: 0) {
                ImageView(url: show.imageUrl(for: .large))
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .background(Color.white.opacity(0.1))
                    .overlay(ImageOverlay(uiHorizontalSizeClass: uiHorizontalSizeClass))
                    .layoutPriority(1)
                VStack(spacing: SectionShowHeaderViewSize.verticalSpacing) {
                    DescriptionView(section: section)
                    ShowAccessButton(show: show, uiHorizontalSizeClass: uiHorizontalSizeClass)
                }
                .padding(.horizontal, constant(iOS: 16, tvOS: 80))
                .padding(.vertical)
                .frame(maxWidth: .infinity)
            }
            .adaptiveMainFrame(for: uiHorizontalSizeClass)
            .padding(.bottom, constant(iOS: 20, tvOS: 50))
        }
    }
    
    private struct ImageOverlay: View {
        let uiHorizontalSizeClass: UIUserInterfaceSizeClass
        
        var body: some View {
            if uiHorizontalSizeClass == .regular {
                LinearGradient(gradient: Gradient(colors: [.clear, .srgGray1]), startPoint: .center, endPoint: .trailing)
            }
        }
    }
    
    /// Behavior: h-hug, v-hug
    private struct DescriptionView: View {
        let section: Content.Section
        
        var body: some View {
            VStack(spacing: SectionShowHeaderViewSize.verticalSpacing) {
                if let title = section.properties.title {
                    Text(title)
                        .srgFont(.H2)
                        // Fix sizing issue, see https://swiftui-lab.com/bug-linelimit-ignored/. The size is correct
                        // when calculated with a `UIHostingController`, but without this the text does not occupy
                        // all lines it could.
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.srgGray5)
                }
                if let summary = section.properties.summary {
                    Text(summary)
                        .srgFont(.body)
                        // See above
                        .lineLimit(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.srgGray4)
                }
            }
        }
    }
    
    /// Behavior: h-hug, v-hug
    private struct ShowAccessButton: View {
        let show: SRGShow
        let uiHorizontalSizeClass: UIUserInterfaceSizeClass
        
        @State private var isFocused = false
        
        var accessibilityLabel: String? {
            return show.title
        }
        
        var accessibilityHint: String? {
            return PlaySRGAccessibilityLocalizedString("Opens show details.", "Show button hint")
        }
        
        var body: some View {
            ResponderChain { firstResponder in
                Button {
                    firstResponder.sendAction(#selector(SectionShowHeaderViewAction.openShow(sender:event:)), for: OpenShowEvent(show: show))
                } label: {
                    HStack(spacing: 15) {
                        Image("episodes-22")
                        Text(show.title)
                            .srgFont(.button)
                    }
                    .onParentFocusChange { isFocused = $0 }
                    .padding(.horizontal, constant(iOS: 10, tvOS: 16))
                    .padding(.vertical, constant(iOS: 8, tvOS: 12))
                    .adaptiveButtonFrame(height: 45, for: uiHorizontalSizeClass)
                    .foregroundColor(constant(iOS: .srgGray5, tvOS: isFocused ? .srgGray2 : .srgGray5))
                    .background(constant(iOS: Color.srgGray2, tvOS: Color.clear))
                    .cornerRadius(LayoutStandardViewCornerRadius)
                    .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: .isButton)
                }
            }
        }
    }
}

// MARK: Helpers

// TODO: With Swift 5.5 use #if support for postfix expressions
//       See https://github.com/apple/swift-evolution/blob/main/proposals/0308-postfix-if-config-expressions.md
//
//       That means:
//         - Remove this extension
//         - Remove uiHorizontalSizeClass
//         - Directly inline the modifiers above with a separate expression per platform
private extension View {
    func adaptiveMainFrame(for horizontalSizeClass: UIUserInterfaceSizeClass? = .regular) -> some View {
        return Group {
            if horizontalSizeClass == .compact {
                self
            }
            else {
                self.frame(height: constant(iOS: 300, tvOS: 500), alignment: .top)
            }
        }
    }
    
    func adaptiveButtonFrame(height: CGFloat, for horizontalSizeClass: UIUserInterfaceSizeClass? = .regular) -> some View {
        return Group {
            if horizontalSizeClass == .compact {
                self.frame(maxWidth: .infinity, minHeight: height, alignment: .leading)
            }
            else {
                self.frame(maxWidth: 300, minHeight: height, maxHeight: height)
            }
        }
    }
}

// MARK: Size

class SectionShowHeaderViewSize: NSObject {
    fileprivate static let verticalSpacing: CGFloat = constant(iOS: 18, tvOS: 24)
    
    static func recommended(for section: Content.Section, show: SRGShow?, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutSize {
        if let show = show {
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
