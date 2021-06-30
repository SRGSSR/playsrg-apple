//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

/// Behavior: h-hug, v-hug
struct ShowHeaderView: View {
    @Binding private(set) var show: SRGShow?
    @StateObject private var model = ShowHeaderViewModel()
    
    init(show: SRGShow?) {
        _show = .constant(show)
    }
    
    var body: some View {
        MainView(model: model)
            .onAppear {
                model.show = show
            }
            .onChange(of: show) { newValue in
                model.show = newValue
            }
    }
    
    /// Behavior: h-hug, v-hug.
    fileprivate struct MainView: View {
        @ObservedObject var model: ShowHeaderViewModel
        
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
                ImageView(url: model.imageUrl)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .background(Color.white.opacity(0.1))
                    .overlay(ImageOverlay(uiHorizontalSizeClass: uiHorizontalSizeClass))
                    .layoutPriority(1)
                DescriptionView(model: model)
                    .padding(.horizontal, constant(iOS: 16, tvOS: 80))
                    .padding(.vertical)
                    .frame(maxWidth: .infinity)
            }
            .adaptiveMainFrame(for: uiHorizontalSizeClass)
            .padding(.bottom, constant(iOS: 20, tvOS: 50))
            .focusable()
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
        @ObservedObject var model: ShowHeaderViewModel
        
        private var isPushServiceEnabled: Bool {
            #if os(iOS)
            if let pushService = PushService.shared {
                return pushService.isEnabled
            }
            else {
                return false
            }
            #else
            return false
            #endif
        }
        
        private var favoriteIcon: String {
            return model.isFavorite ? "favorite_full" : "favorite"
        }
        
        private var favoriteLabel: String {
            if model.isFavorite {
                return NSLocalizedString("Favorites", comment: "Label displayed in the show view when a show has been favorited")
            }
            else {
                return NSLocalizedString("Add to favorites", comment: "Label displayed in the show view when a show can be favorited")
            }
        }
        
        #if os(iOS)
        private var subscriptionIcon: String {
            if isPushServiceEnabled {
                return model.isSubscribed ? "subscription_full" : "subscription"
            }
            else {
                return "subscription_disabled"
            }
        }
        
        private var subscriptionLabel: String {
            if isPushServiceEnabled && model.isSubscribed {
                return NSLocalizedString("Notified", comment: "Subscription label when notification enabled in the show view")
            }
            else {
                return NSLocalizedString("Notify me", comment: "Subscription label to be notified in the show view")
            }
        }
        #endif
        
        var body: some View {
            VStack {
                if let broadcastInformation = model.broadcastInformation {
                    Badge(text: broadcastInformation, color: .srgGray3)
                }
                Text(model.title ?? "")
                    .srgFont(.H2)
                    .lineLimit(2)
                    // Fix sizing issue, see https://swiftui-lab.com/bug-linelimit-ignored/. The size is correct
                    // when calculated with a `UIHostingController`, but without this the text does not occupy
                    // all lines it could.
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.srgGray5)
                if let lead = model.lead {
                    Text(lead)
                        .srgFont(.body)
                        .lineLimit(6)
                        // See above
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.srgGray4)
                }
                HStack(spacing: 20) {
                    SimpleButton(icon: favoriteIcon, label: favoriteLabel, action: favoriteAction)
                    #if os(iOS)
                    if model.isFavorite {
                        SimpleButton(icon: subscriptionIcon, label: subscriptionLabel, action: subscriptionAction)
                    }
                    #endif
                }
            }
        }
        
        private func favoriteAction() {
            model.toggleFavorite()
        }
        
        #if os(iOS)
        private func subscriptionAction() {
            model.toggleSubscription()
        }
        #endif
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
        let model = ShowHeaderViewModel()
        model.show = show
        let size = ShowHeaderView.MainView(model: model).adaptiveSizeThatFits(in: fittingSize, for: horizontalSizeClass)
        return NSCollectionLayoutSize(widthDimension: .absolute(layoutWidth), heightDimension: .absolute(size.height))
    }
}

struct ShowHeaderView_Previews: PreviewProvider {
    static let model: ShowHeaderViewModel = {
        let model = ShowHeaderViewModel()
        model.show = Mock.show()
        return model
    }()
    
    static var previews: some View {
        #if os(tvOS)
        ShowHeaderView.MainView(model: model)
            .previewLayout(.sizeThatFits)
        #else
        ShowHeaderView.MainView(model: model)
            .frame(width: 1000)
            .previewLayout(.sizeThatFits)
            .environment(\.horizontalSizeClass, .regular)
        
        ShowHeaderView.MainView(model: model)
            .frame(width: 375)
            .previewLayout(.sizeThatFits)
            .environment(\.horizontalSizeClass, .compact)
        #endif
    }
}
