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
    
    var titleColor: Color = .white
    var foregroundColor: Color = .srgGrayD2
    
    static let imageAspectRatio: CGFloat = 16 / 9
    
    static func isVerticalLayout(horizontalSizeClass: UIUserInterfaceSizeClass, isLandscape: Bool) -> Bool {
        return horizontalSizeClass == .compact || !isLandscape
    }
    
    @StateObject private var model = ShowHeaderViewModel()
    
    fileprivate static let verticalSpacing: CGFloat = 24
    
    init(_ show: SRGShow?, horizontalPadding: CGFloat) {
        _show = .constant(show)
        self.horizontalPadding = horizontalPadding
    }
    
    func titleColor(_ color: Color) -> Self {
        var view = self
        
        view.titleColor = color
        return view
    }
    
    func foregroundColor(_ color: Color) -> Self {
        var view = self
        
        view.foregroundColor = color
        return view
    }
    
    var body: some View {
        MainView(model: model, horizontalPadding: horizontalPadding)
            .titleColor(titleColor)
            .foregroundColor(foregroundColor)
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
        
        var titleColor: Color = .white
        var foregroundColor: Color = .srgGrayD2
        
        init(model: ShowHeaderViewModel, horizontalPadding: CGFloat) {
            self.model = model
            self.horizontalPadding = horizontalPadding
            self.isLandscape = (UIApplication.shared.mainWindow?.isLandscape ?? false)
        }
        
        func titleColor(_ color: Color) -> Self {
            var view = self
            
            view.titleColor = color
            return view
        }
        
        func foregroundColor(_ color: Color) -> Self {
            var view = self
            
            view.foregroundColor = color
            return view
        }
        
        private var padding: CGFloat {
            return horizontalSizeClass == .compact ? horizontalPadding : horizontalPadding * 2
        }
        
        var body: some View {
            Group {
                if isVerticalLayout(horizontalSizeClass: horizontalSizeClass, isLandscape: isLandscape) {
                    VStack(alignment: .leading, spacing: 0) {
                        ImageView(source: model.imageUrl)
                            .aspectRatio(ShowHeaderView.imageAspectRatio, contentMode: .fit)
                            .layoutPriority(1)
                        DescriptionView(model: model, compactLayout: horizontalSizeClass == .compact)
                            .titleColor(titleColor)
                            .foregroundColor(foregroundColor)
                            .padding(.top, padding)
                            .padding(.horizontal, padding)
                    }
                    .padding(.bottom, 24)
                }
                else {
                    HStack(spacing: constant(iOS: padding, tvOS: 50)) {
                        DescriptionView(model: model, compactLayout: false)
                            .titleColor(titleColor)
                            .foregroundColor(foregroundColor)
                        ImageView(source: model.imageUrl)
                            .aspectRatio(ShowHeaderView.imageAspectRatio, contentMode: .fit)
                            .frame(width: UIScreen.main.bounds.width * 0.35)
                    }
                    .padding(.top, padding)
                    .padding(.horizontal, padding)
                    .padding(.bottom, constant(iOS: 40, tvOS: 50))
                }
            }
            .readSize { _ in
                isLandscape = (UIApplication.shared.mainWindow?.isLandscape ?? false)
            }
        }
    }
    
    /// Behavior: h-hug, v-hug
    private struct DescriptionView: View {
        @ObservedObject var model: ShowHeaderViewModel
        let compactLayout: Bool
        
        var titleColor: Color = .white
        var foregroundColor: Color = .srgGrayD2
        
        func titleColor(_ color: Color) -> Self {
            var view = self
            
            view.titleColor = color
            return view
        }
        
        func foregroundColor(_ color: Color) -> Self {
            var view = self
            
            view.foregroundColor = color
            return view
        }
        
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
                    .foregroundColor(titleColor)
                if let broadcastInformation = model.broadcastInformation {
                    Badge(text: broadcastInformation, color: Color(.srgDarkRed))
                }
                if let summary = model.show?.play_summary {
                    SummaryView(summary)
                        .foregroundColor(foregroundColor)
                    // See above
                        .fixedSize(horizontal: false, vertical: true)
                }
                ActionsView(model: model, compactLayout: compactLayout)
                    .foregroundColor(foregroundColor)
                    .frame(height: constant(iOS: 40, tvOS: 70))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .focusable()
        }
        
        /// Behavior: h-exp, v-hug
        private struct SummaryView: View {
            let content: String
            
            var foregroundColor: Color = .srgGrayD2
            
            @FirstResponder private var firstResponder
            
            init(_ content: String) {
                self.content = content
            }
            
            func foregroundColor(_ color: Color) -> Self {
                var view = self
                
                view.foregroundColor = color
                return view
            }
            
            var body: some View {
                TruncatableTextView(content: content, lineLimit: 3) {
                    firstResponder.sendAction(#selector(ShowHeaderViewAction.showMore(sender:event:)), for: ShowMoreEvent(content: content))
                }
                .foregroundColor(foregroundColor)
                .responderChain(from: firstResponder)
            }
        }
        
        private struct ActionsView: View {
            @ObservedObject var model: ShowHeaderViewModel
            let compactLayout: Bool
            
            var foregroundColor: Color = .srgGrayD2
            
            func foregroundColor(_ color: Color) -> Self {
                var view = self
                
                view.foregroundColor = color
                return view
            }
            
            var body: some View {
                HStack(spacing: 8) {
                    if compactLayout {
                        ExpandingButton(icon: model.favoriteIcon,
                                        label: model.favoriteLabel,
                                        accessibilityLabel: model.favoriteAccessibilityLabel,
                                        action: favoriteAction)
                        .foregroundColor(foregroundColor)
                        .alert(isPresented: $model.isFavoriteRemovalAlertDisplayed, content: favoriteRemovalAlert)
#if os(iOS)
                        if model.isSubscriptionPossible {
                            ExpandingButton(icon: model.subscriptionIcon,
                                            label: model.subscriptionLabel,
                                            accessibilityLabel: model.subscriptionAccessibilityLabel,
                                            action: subscriptionAction)
                            .foregroundColor(foregroundColor)
                        }
#endif
                    }
                    else {
                        SimpleButton(icon: model.favoriteIcon,
                                     label: model.favoriteLabel,
                                     labelMinimumScaleFactor: 1,
                                     accessibilityLabel: model.favoriteAccessibilityLabel,
                                     action: favoriteAction)
                        .foregroundColor(foregroundColor)
#if os(iOS)
                        if model.isSubscriptionPossible {
                            SimpleButton(icon: model.subscriptionIcon,
                                         label: model.subscriptionLabel,
                                         accessibilityLabel: model.subscriptionAccessibilityLabel,
                                         action: subscriptionAction)
                            .foregroundColor(foregroundColor)
                        }
#endif
                    }
                }
                .alert(isPresented: $model.isFavoriteRemovalAlertDisplayed, content: favoriteRemovalAlert)
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
