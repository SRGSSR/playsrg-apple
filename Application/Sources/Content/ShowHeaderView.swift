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
        @Environment(\.uiHorizontalSizeClass) private var horizontalSizeClass
        
        var body: some View {
            if horizontalSizeClass == .compact {
                VStack(alignment: .center, spacing: 0) {
                    ImageView(source: model.imageUrl)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .overlay(ImageOverlay(horizontalSizeClass: .compact))
                        .layoutPriority(1)
                    DescriptionView(model: model, horizontalSizeClass: .compact)
                        .padding(.horizontal, 16)
                        .padding(.vertical)
                        .offset(y: -30)
                }
                .padding(.bottom, 20)
                .focusable()
            }
            else {
                HStack(spacing: 0) {
                    DescriptionView(model: model, horizontalSizeClass: .regular)
                        .padding(.horizontal, 16)
                        .padding(.vertical)
                    ImageView(source: model.imageUrl)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .overlay(ImageOverlay(horizontalSizeClass: .regular))
                }
                .padding(.bottom, constant(iOS: 20, tvOS: 50))
                .focusable()
            }
        }
    }
    
    /// Behavior: h-exp, v-exp
    private struct ImageOverlay: View {
        let horizontalSizeClass: UIUserInterfaceSizeClass
        
        var body: some View {
            if horizontalSizeClass == .regular {
                LinearGradient(gradient: Gradient(colors: [.clear, .srgGray16]), startPoint: .center, endPoint: .leading)
            }
            else {
                LinearGradient(gradient: Gradient(colors: [.clear, .srgGray16]), startPoint: UnitPoint(x: 0.5, y: 0.85), endPoint: .bottom)
            }
        }
    }
    
    /// Behavior: h-hug, v-hug
    private struct DescriptionView: View {
        @ObservedObject var model: ShowHeaderViewModel
#if os(tvOS)
        @State var isFocused = false
#endif
        let horizontalSizeClass: UIUserInterfaceSizeClass
        
        private var stackAlignment: HorizontalAlignment {
            return (horizontalSizeClass == .compact) ? .center : .leading
        }
        
        private var titleAlignment: TextAlignment {
            return (horizontalSizeClass == .compact) ? .center : .leading
        }
        
        var body: some View {
            VStack(alignment: stackAlignment, spacing: ShowHeaderView.verticalSpacing) {
                Text(model.title ?? "")
                    .srgFont(.H2)
                    .lineLimit(2)
                    // Fix sizing issue, see https://swiftui-lab.com/bug-linelimit-ignored/. The size is correct
                    // when calculated with a `UIHostingController`, but without this the text does not occupy
                    // all lines it could.
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(titleAlignment)
                    .foregroundColor(.white)
                if let broadcastInformation = model.broadcastInformation {
                    Badge(text: broadcastInformation, color: Color(.play_green))
                }
                if horizontalSizeClass == .compact {
                    ExpandingButton(icon: model.favoriteIcon, label: model.favoriteLabel, accessibilityLabel: model.favoriteAccessibilityLabel, action: favoriteAction)
                        .frame(height: constant(iOS: 40, tvOS: 70))
                        .alert(isPresented: $model.isFavoriteRemovalAlertDisplayed, content: favoriteRemovalAlert)
                }
                else {
                    SimpleButton(icon: model.favoriteIcon, label: model.favoriteLabel, accessibilityLabel: model.favoriteAccessibilityLabel, action: favoriteAction)
                        .alert(isPresented: $model.isFavoriteRemovalAlertDisplayed, content: favoriteRemovalAlert)
                }
                if let lead = model.lead {
#if os(iOS)
                    LeadView(lead)
                        // See above
                        .fixedSize(horizontal: false, vertical: true)
#else
                    Button {
                        navigateToText(lead)
                    } label: {
                        LeadView(lead)
                            // See above
                            .fixedSize(horizontal: false, vertical: true)
                            .onParentFocusChange { isFocused = $0 }
                    }
                    .buttonStyle(TextButtonStyle(focused: isFocused))
#endif
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
        
        /// Behavior: h-exp, v-hug
        private struct LeadView: View {
            let content: String
            
            @FirstResponder private var firstResponder
            
            var body: some View {
                Group {
#if os(iOS)
                    TruncableTextView(content: content, lineLimit: 3) {
                        firstResponder.sendAction(#selector(ShowHeaderViewAction.showMore(sender:event:)), for: ShowMoreEvent(content: content))
                    }
#else
                    Text(content)
                        .srgFont(.body)
                        .lineLimit(6)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.srgGray96)
#endif
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
    static func recommended(for show: SRGShow, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutSize {
        let fittingSize = CGSize(width: layoutWidth, height: UIView.layoutFittingExpandedSize.height)
        let model = ShowHeaderViewModel()
        model.show = show
        let size = ShowHeaderView.MainView(model: model).adaptiveSizeThatFits(in: fittingSize, for: horizontalSizeClass)
        return NSCollectionLayoutSize(widthDimension: .absolute(layoutWidth), heightDimension: .absolute(size.height))
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
            ShowHeaderView.MainView(model: model1)
            ShowHeaderView.MainView(model: model2)
        }
        .previewLayout(.sizeThatFits)
#else
        Group {
            ShowHeaderView.MainView(model: model1)
            ShowHeaderView.MainView(model: model2)
        }
        .previewLayout(.sizeThatFits)
        .frame(width: 1000)
        .environment(\.horizontalSizeClass, .regular)
        
        Group {
            ShowHeaderView.MainView(model: model1)
            ShowHeaderView.MainView(model: model2)
        }
        .frame(width: 375)
        .previewLayout(.sizeThatFits)
        .environment(\.horizontalSizeClass, .compact)
#endif
    }
}
