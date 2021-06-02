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
        #if os(tvOS)
        MainView(section: section, show: show)
            .focusable()
        #else
        MainView(section: section, show: show)
        #endif
    }
    
    // Behavior: h-hug, v-hug
    private struct MainView: View {
        let section: Content.Section
        let show: SRGShow
        
        #if os(iOS)
        @Environment(\.horizontalSizeClass) var horizontalSizeClass
        #endif
        
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
                    .aspectRatio(SectionShowHeaderViewSize.aspectRatio, contentMode: .fit)
                    .background(Color.white.opacity(0.1))
                VStack(spacing: SectionShowHeaderViewSize.verticalSpacing) {
                    DescriptionView(section: section)
                    ShowAccessButton(show: show)
                }
                .padding(.horizontal, SectionShowHeaderViewSize.horizontalMargin)
                .padding(.vertical)
                .frame(maxWidth: .infinity)
            }
            .padding(.bottom, SectionShowHeaderViewSize.verticalMargin)
        }
    }
    
    // Behavior: h-hug, v-hug
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
                        .foregroundColor(.white)
                }
                if let summary = section.properties.summary {
                    Text(summary)
                        .srgFont(.body)
                        // See above
                        .lineLimit(8)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    // Behavior: h-hug, v-hug
    private struct ShowAccessButton: View {
        let show: SRGShow
        
        #if os(iOS)
        @Environment(\.horizontalSizeClass) var horizontalSizeClass
        #endif
        
        @State private var isFocused = false
        
        var uiHorizontalSizeClass: UIUserInterfaceSizeClass {
            #if os(iOS)
            return UIUserInterfaceSizeClass(horizontalSizeClass)
            #else
            return .regular
            #endif
        }
        
        var body: some View {
            ResponderChain { firstResponder in
                Button {
                    firstResponder.sendAction(#selector(SectionShowHeaderViewAction.openShow(sender:event:)), for: OpenShowEvent(show: show))
                } label: {
                    HStack(spacing: 15) {
                        Image("episodes-22")
                        Text(show.title)
                    }
                    .onParentFocusChange { isFocused = $0 }
                    .padding(.horizontal, SectionShowHeaderViewSize.horizontalButtonPadding)
                    .padding(.vertical, SectionShowHeaderViewSize.verticalButtonPadding)
                    .adaptiveFrame(height: 45, for: uiHorizontalSizeClass)
                    .foregroundColor(constant(iOS: .gray, tvOS: isFocused ? .darkGray : .white))
                    .background(constant(iOS: Color.white.opacity(0.1), tvOS: Color.clear))
                    .cornerRadius(LayoutStandardViewCornerRadius)
                }
            }
        }
    }
}

// TODO: With Swift 5.5 use #if support for postfix expressions
//       See https://github.com/apple/swift-evolution/blob/main/proposals/0308-postfix-if-config-expressions.md
//
//       That means:
//         - Remove this extension
//         - Remove uiHorizontalSizeClass
//         - Directly inline it above with a separate expression per platform
private extension View {
    func adaptiveFrame(height: CGFloat, for horizontalSizeClass: UIUserInterfaceSizeClass? = .regular) -> some View {
        return Group {
            if horizontalSizeClass == .compact {
                self.frame(maxWidth: .infinity, minHeight: height, alignment: .leading)
            }
            else {
                self.frame(height: height)
            }
        }
    }
}

class SectionShowHeaderViewSize: NSObject {
    fileprivate static let aspectRatio: CGFloat = 16 / 9
    
    fileprivate static let verticalSpacing: CGFloat = constant(iOS: 18, tvOS: 24)
    fileprivate static let horizontalMargin: CGFloat = constant(iOS: 16, tvOS: 80)
    fileprivate static let verticalMargin: CGFloat = constant(iOS: 50, tvOS: 80)
    fileprivate static let horizontalButtonPadding: CGFloat = constant(iOS: 10, tvOS: 16)
    fileprivate static let verticalButtonPadding: CGFloat = constant(iOS: 8, tvOS: 12)
    
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
