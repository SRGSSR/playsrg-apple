//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

/// Behavior: h-hug, v-hug
struct ShowHeaderView: View {
    let show: SRGShow
    
    var body: some View {
        #if os(tvOS)
        MainView(show: show)
            .focusable()
        #else
        MainView(show: show)
        #endif
    }
    
    private struct MainView: View {
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
                DescriptionView(show: show)
                    .padding(.horizontal, constant(iOS: 16, tvOS: 80))
                    .padding(.vertical)
                    .frame(maxWidth: .infinity)
            }
            .adaptiveMainFrame(for: uiHorizontalSizeClass)
            .padding(.bottom, constant(iOS: 20, tvOS: 50))
        }
    }
    
    /// Behavior: h-exp, v-exp
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
        let show: SRGShow
        
        var body: some View {
            VStack {
                Text(show.title)
                    .srgFont(.H2)
                    // Fix sizing issue, see https://swiftui-lab.com/bug-linelimit-ignored/. The size is correct
                    // when calculated with a `UIHostingController`, but without this the text does not occupy
                    // all lines it could.
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.srgGray5)
                if let lead = show.lead {
                    Text(lead)
                        .srgFont(.body)
                        .lineLimit(6)
                        // See above
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.srgGray4)
                }
                HStack(spacing: 20) {
                    Button(action: favoriteAction, label: {
                        HStack(spacing: 5) {
                            Image("show_favorite")
                            Text("Add to favorites")
                                .srgFont(.button)
                        }
                    })
                    Button(action: subscriptionAction, label: {
                        HStack(spacing: 5) {
                            Image("show_subscription")
                            Text("Subscribe")
                                .srgFont(.button)
                        }
                    })
                }
                .foregroundColor(.srgGray5)
            }
        }
        
        private func favoriteAction() {
            
        }
        
        private func subscriptionAction() {
            
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
}

// MARK: Size

class ShowHeaderViewSize: NSObject {
    static func recommended(for show: SRGShow, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutSize {
        let fittingSize = CGSize(width: layoutWidth, height: UIView.layoutFittingExpandedSize.height)
        let size = ShowHeaderView(show: show).adaptiveSizeThatFits(in: fittingSize, for: horizontalSizeClass)
        return NSCollectionLayoutSize(widthDimension: .absolute(layoutWidth), heightDimension: .absolute(size.height))
    }
}

struct ShowHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        #if os(tvOS)
        ShowHeaderView(show: Mock.show())
            .previewLayout(.sizeThatFits)
        #else
        ShowHeaderView(show: Mock.show())
            .frame(width: 1000)
            .previewLayout(.sizeThatFits)
            .environment(\.horizontalSizeClass, .regular)
        
        ShowHeaderView(show: Mock.show())
            .frame(width: 375)
            .previewLayout(.sizeThatFits)
            .environment(\.horizontalSizeClass, .compact)
        #endif
    }
}
