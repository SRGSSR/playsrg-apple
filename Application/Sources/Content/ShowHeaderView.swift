//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import NukeUI
import SwiftUI

// MARK: Contract

@objc protocol ShowHeaderViewAction {
    func showMore(sender: Any?, event: ShowMoreEvent?)
}

class ShowMoreEvent: UIEvent {
    let content: String
    
    init(content: String) {
        self.content = content
        super.init()
    }
    
    override init() {
        fatalError("init() is not available")
    }
}

// MARK: View

/// Behavior: h-hug, v-hug
struct ShowHeaderView: View {
    @Binding private(set) var show: SRGShow?
    let horizontalPadding: CGFloat
    
    @StateObject private var model = ShowHeaderViewModel()
    
    fileprivate static let verticalSpacing: CGFloat = 24
    
    init(show: SRGShow?, horizontalPadding: CGFloat) {
        _show = .constant(show)
        self.horizontalPadding = horizontalPadding
    }
    
    var body: some View {
        MainView(model: model, horizontalPadding: horizontalPadding)
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
        let horizontalPadding: CGFloat
        @Environment(\.uiHorizontalSizeClass) private var horizontalSizeClass
        
        @State private var isLandscape: Bool
        
        private let compactDescriptionOffet: CGFloat = -12
        
        init(model: ShowHeaderViewModel, horizontalPadding: CGFloat) {
            self.model = model
            self.horizontalPadding = horizontalPadding
            self.isLandscape = (UIApplication.shared.mainWindow?.isLandscape ?? false)
        }
        
        private var descriptionHorizontalPadding: CGFloat {
            return horizontalSizeClass == .compact ? horizontalPadding : horizontalPadding * 2
        }
        
        var body: some View {
            Group {
                if horizontalSizeClass == .compact || !isLandscape {
                    VStack(alignment: .leading, spacing: 0) {
                        ImageView(source: model.imageUrl)
                            .aspectRatio(16 / 9, contentMode: .fit)
                            .overlay(ImageOverlay(isHorizontal: false))
                            .layoutPriority(1)
                        DescriptionView(model: model, compactLayout: horizontalSizeClass == .compact)
                            .padding(.horizontal, descriptionHorizontalPadding)
                            .offset(y: compactDescriptionOffet)
                    }
                    .padding(.bottom, 24 + compactDescriptionOffet)
                    .focusable()
                }
                else {
                    HStack(spacing: 0) {
                        DescriptionView(model: model, compactLayout: false)
                            .padding(.leading, descriptionHorizontalPadding)
                            .padding(.trailing, 16)
                        ImageView(source: model.imageUrl)
                            .aspectRatio(16 / 9, contentMode: .fit)
                            .overlay(ImageOverlay(isHorizontal: true))
                    }
                    .padding(.bottom, constant(iOS: 40, tvOS: 50))
                    .focusable()
                }
            }
            .readSize { _ in
                isLandscape = (UIApplication.shared.mainWindow?.isLandscape ?? false)
            }
        }
    }
    
    /// Behavior: h-exp, v-exp
    private struct ImageOverlay: View {
        let isHorizontal: Bool
        
        var body: some View {
            if isHorizontal {
                Group {
                    LinearGradient(colors: [.clear, .srgGray16], startPoint: UnitPoint(x: 0.1, y: 0.5), endPoint: .leading)
                    LinearGradient(colors: [.clear, .srgGray16], startPoint: UnitPoint(x: 0.5, y: 0.95), endPoint: .bottom)
                }
            }
            else {
                LinearGradient(colors: [.clear, .srgGray16], startPoint: UnitPoint(x: 0.5, y: 0.9), endPoint: .bottom)
            }
        }
    }
    
    /// Behavior: h-hug, v-hug
    private struct DescriptionView: View {
        @ObservedObject var model: ShowHeaderViewModel
        let compactLayout: Bool
        
        var body: some View {
            VStack(alignment: .leading, spacing: ShowHeaderView.verticalSpacing) {
                Text(model.title ?? "")
                    .srgFont(.H2)
                    .lineLimit(2)
                // Fix sizing issue, see https://swiftui-lab.com/bug-linelimit-ignored/. The size is correct
                // when calculated with a `UIHostingController`, but without this the text does not occupy
                // all lines it could.
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.white)
                HStack(spacing: 8) {
                    if compactLayout {
                        ExpandingButton(icon: model.favoriteIcon,
                                        label: model.favoriteLabel,
                                        accessibilityLabel: model.favoriteAccessibilityLabel,
                                        action: favoriteAction)
                        .alert(isPresented: $model.isFavoriteRemovalAlertDisplayed, content: favoriteRemovalAlert)
#if os(iOS)
                        if model.isSubscriptionPossible {
                            ExpandingButton(icon: model.subscriptionIcon,
                                            label: model.subscriptionLabel,
                                            accessibilityLabel: model.subscriptionAccessibilityLabel,
                                            action: subscriptionAction)
                        }
#endif
                    }
                    else {
                        SimpleButton(icon: model.favoriteIcon,
                                     label: model.favoriteLabel,
                                     labelMinimumScaleFactor: 1,
                                     accessibilityLabel: model.favoriteAccessibilityLabel,
                                     action: favoriteAction)
#if os(iOS)
                        if model.isSubscriptionPossible {
                            SimpleButton(icon: model.subscriptionIcon,
                                         label: model.subscriptionLabel,
                                         accessibilityLabel: model.subscriptionAccessibilityLabel,
                                         action: subscriptionAction)
                        }
#endif
                    }
                }
                .frame(height: constant(iOS: 40, tvOS: 70))
                .alert(isPresented: $model.isFavoriteRemovalAlertDisplayed, content: favoriteRemovalAlert)
                if let summary = model.show?.play_summary {
                    SummaryView(summary)
                    // See above
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let broadcastInformation = model.broadcastInformation {
                    Badge(text: broadcastInformation, color: Color(.srgGray96), textColor: Color(.srgGray16))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
        
        /// Behavior: h-exp, v-hug
        private struct SummaryView: View {
            let content: String
            
            @FirstResponder private var firstResponder
            
            var body: some View {
                TruncatableTextView(content: content, lineLimit: 3) {
                    firstResponder.sendAction(#selector(ShowHeaderViewAction.showMore(sender:event:)), for: ShowMoreEvent(content: content))
                }
                .responderChain(from: firstResponder)
            }
            
            init(_ content: String) {
                self.content = content
            }
        }
    }
}

// MARK: Size

enum ShowHeaderViewSize {
    static func recommended(for show: SRGShow?, horizontalPadding: CGFloat, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutSize {
        if let show {
            let fittingSize = CGSize(width: layoutWidth, height: UIView.layoutFittingExpandedSize.height)
            let model = ShowHeaderViewModel()
            model.show = show
            let size = ShowHeaderView.MainView(model: model, horizontalPadding: horizontalPadding).adaptiveSizeThatFits(in: fittingSize, for: horizontalSizeClass)
            return NSCollectionLayoutSize(widthDimension: .absolute(size.width), heightDimension: .absolute(size.height))
        }
        else {
            return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(LayoutHeaderHeightZero))
        }
    }
}

struct ShowHeaderView_Previews: PreviewProvider {
    private static let model1: ShowHeaderViewModel = {
        let model = ShowHeaderViewModel()
        model.show = Mock.show()
        return model
    }()
    
    private static let model2: ShowHeaderViewModel = {
        let model = ShowHeaderViewModel()
        model.show = Mock.show(.overflow)
        return model
    }()
    
    static var previews: some View {
#if os(tvOS)
        Group {
            ShowHeaderView.MainView(model: model1, horizontalPadding: 0)
            ShowHeaderView.MainView(model: model2, horizontalPadding: 0)
        }
        .previewLayout(.sizeThatFits)
#else
        Group {
            ShowHeaderView.MainView(model: model1, horizontalPadding: 16)
            ShowHeaderView.MainView(model: model2, horizontalPadding: 16)
        }
        .previewLayout(.sizeThatFits)
        .frame(width: 1000)
        .environment(\.horizontalSizeClass, .regular)
        
        Group {
            ShowHeaderView.MainView(model: model1, horizontalPadding: 16)
            ShowHeaderView.MainView(model: model2, horizontalPadding: 16)
        }
        .frame(width: 375)
        .previewLayout(.sizeThatFits)
        .environment(\.horizontalSizeClass, .compact)
#endif
    }
}
