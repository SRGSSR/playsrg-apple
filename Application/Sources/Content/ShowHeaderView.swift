//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

/// Behavior: h-hug, v-hug
struct ShowHeaderView: View {
    @Binding private(set) var show: SRGShow
    @StateObject private var model = ShowHeaderViewModel()
    
    fileprivate static let verticalSpacing: CGFloat = constant(iOS: 18, tvOS: 24)
    
    init(show: SRGShow) {
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
        
        private var alignment: StackAlignment {
#if os(iOS)
            return (horizontalSizeClass == .compact) ? .center : .leading
#else
            return .leading
#endif
        }
        
        var body: some View {
            Stack(direction: direction, alignment: alignment, spacing: 0) {
                ImageView(url: model.imageUrl)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .background(Color.placeholder)
                    .overlay(ImageOverlay(uiHorizontalSizeClass: uiHorizontalSizeClass))
                    .adaptiveMainFrame(for: uiHorizontalSizeClass)
                    .layoutPriority(1)
                DescriptionView(model: model)
                    .padding(.horizontal, constant(iOS: 16, tvOS: 80))
                    .padding(.vertical)
                    .frame(maxWidth: .infinity)
            }
            .padding(.bottom, constant(iOS: 20, tvOS: 50))
            .focusable()
        }
    }
    
    /// Behavior: h-exp, v-exp
    private struct ImageOverlay: View {
        let uiHorizontalSizeClass: UIUserInterfaceSizeClass
        
        var body: some View {
            if uiHorizontalSizeClass == .regular {
                LinearGradient(gradient: Gradient(colors: [.clear, .srgGray16]), startPoint: .center, endPoint: .trailing)
            }
        }
    }
    
    /// Behavior: h-hug, v-hug
    private struct DescriptionView: View {
        @ObservedObject var model: ShowHeaderViewModel
        
        var body: some View {
            VStack(spacing: ShowHeaderView.verticalSpacing) {
                if let broadcastInformation = model.broadcastInformation {
                    Badge(text: broadcastInformation, color: Color(.play_green))
                }
                Text(model.title ?? "")
                    .srgFont(.H2)
                    .lineLimit(2)
                    // Fix sizing issue, see https://swiftui-lab.com/bug-linelimit-ignored/. The size is correct
                    // when calculated with a `UIHostingController`, but without this the text does not occupy
                    // all lines it could.
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.srgGrayC7)
                if let lead = model.lead {
                    Text(lead)
                        .srgFont(.body)
                        .lineLimit(6)
                        // See above
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.srgGray96)
                }
                HStack(spacing: 20) {
                    SimpleButton(icon: model.favoriteIcon, label: model.favoriteLabel, accessibilityLabel: model.favoriteAccessibilityLabel, action: favoriteAction)
#if os(iOS)
                    if model.isSubscriptionPossible {
                        SimpleButton(icon: model.subscriptionIcon, label: model.subscriptionLabel, accessibilityLabel: model.subscriptionAccessibilityLabel, action: subscriptionAction)
                    }
#endif
                }
                .alert(isPresented: $model.isFavoriteRemovalAlertDisplayed, content: favoriteRemovalAlert)
            }
        }
        
        private func favoriteAction() {
            if model.shouldDisplayFavoriteRemovalAlert {
                model.isFavoriteRemovalAlertDisplayed = true
            }
            else {
                model.toggleFavorite()
            }
        }
        
        private func favoriteRemovalAlert() -> Alert {
            let primaryButton = Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "Title of a cancel button"))) {}
            let secondaryButton = Alert.Button.destructive(Text(NSLocalizedString("Delete", comment: "Title of a delete button"))) {
                model.toggleFavorite()
            }
            return Alert(title: Text(NSLocalizedString("Delete from favorites", comment: "Title of the confirmation pop-up displayed when the user is about to delete a favorite")),
                         message: Text(NSLocalizedString("The favorite and notification subscription will be deleted on all devices connected to your account.", comment: "Confirmation message displayed when a logged in user is about to delete a favorite")),
                         primaryButton: primaryButton,
                         secondaryButton: secondaryButton)
        }
        
#if os(iOS)
        private func subscriptionAction() {
            model.toggleSubscription()
        }
#endif
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

final class ShowHeaderViewSize: NSObject {
    static func recommended(for show: SRGShow, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutSize {
        let fittingSize = CGSize(width: layoutWidth, height: UIView.layoutFittingExpandedSize.height)
        let model = ShowHeaderViewModel()
        model.show = show
        let size = ShowHeaderView.MainView(model: model).adaptiveSizeThatFits(in: fittingSize, for: horizontalSizeClass)
        return NSCollectionLayoutSize(widthDimension: .absolute(layoutWidth), heightDimension: .absolute(size.height))
    }
}

struct ShowHeaderView_Previews: PreviewProvider {
    private static let model: ShowHeaderViewModel = {
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
