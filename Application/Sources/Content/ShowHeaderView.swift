//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import NukeUI
import SwiftUI

#if os(iOS)
import ExpandableText
import SRGAppearanceSwift
#endif

// MARK: Contract

@objc protocol ShowHeaderViewAction {
    func heightUpdate(sender: Any?, event: HeightUpdateEvent?)
}

class HeightUpdateEvent: UIEvent {
    let expanded: Bool
    
    init(expanded: Bool) {
        self.expanded = expanded
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
    
    @Environment(\.uiHorizontalSizeClass) private var horizontalSizeClass
    
    @State private var viewExpanded: Bool
    
    @FirstResponder private var firstResponder
    
    fileprivate static let verticalSpacing: CGFloat = constant(iOS: 18, tvOS: 24)
    
    init(show: SRGShow, viewExpanded: Bool) {
        _show = .constant(show)
        self.viewExpanded = viewExpanded
    }
    
    var body: some View {
        MainView(model: model, viewExpanded: $viewExpanded)
            .onAppear {
                model.show = show
            }
            .onChange(of: show) { newValue in
                model.show = newValue
            }
            .onChange(of: viewExpanded) { newValue in
                firstResponder.sendAction(#selector(ShowHeaderViewAction.heightUpdate(sender:event:)), for: HeightUpdateEvent(expanded: newValue))
            }
            .responderChain(from: firstResponder)
    }
    
    /// Behavior: h-hug, v-hug.
    fileprivate struct MainView: View {
        @ObservedObject var model: ShowHeaderViewModel
        @Environment(\.uiHorizontalSizeClass) private var horizontalSizeClass
        
        @Binding var viewExpanded: Bool
        
        var body: some View {
            if horizontalSizeClass == .compact {
                VStack(alignment: .center, spacing: 0) {
                    ImageView(source: model.imageUrl)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .overlay(ImageOverlay(horizontalSizeClass: .compact))
                        .layoutPriority(1)
                    DescriptionView(model: model, horizontalSizeClass: .compact, viewExpanded: $viewExpanded)
                        .padding(.horizontal, 16)
                        .padding(.vertical)
                        .offset(y: -30)
                }
                .padding(.bottom, 20)
                .focusable()
            }
            else {
                HStack(spacing: 0) {
                    DescriptionView(model: model, horizontalSizeClass: .regular, viewExpanded: $viewExpanded)
                        .padding(.horizontal, 16)
                        .padding(.vertical)
                    ImageView(source: model.imageUrl, contentMode: .aspectFitTop)
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
        
        @Binding var viewExpanded: Bool
        
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
                    LeadView(lead, expanded: $viewExpanded)
                        // See above
                        .fixedSize(horizontal: false, vertical: true)
#else
                    Button {
                        navigateToText(lead)
                    } label: {
                        LeadView(lead, expanded: $viewExpanded)
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
            
            @Binding var expanded: Bool
            
            private var lineLimit: Int {
                return !expanded ? constant(iOS: 3, tvOS: 6) : Int.max
            }
            
            var body: some View {
#if os(iOS)
                ExpandableText(text: content, expand: $expanded)
                    .expandButton(TextSet(text: NSLocalizedString("More", comment: "More button label"), font: SRGFont.font(.body), color: .white))
                    .font(SRGFont.font(.body))
                    .lineLimit(lineLimit)
                    .foregroundColor(.srgGray96)
#else
                Text(content)
                    .srgFont(.body)
                    .lineLimit(lineLimit)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.srgGray96)
#endif
            }
            
            init(_ content: String, expanded: Binding<Bool>) {
                self.content = content
                _expanded = expanded
            }
        }
    }
}

// MARK: Size

enum ShowHeaderViewSize {
    static func recommended(for show: SRGShow, layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass, viewExpanded: Bool) -> NSCollectionLayoutSize {
        let fittingSize = CGSize(width: layoutWidth, height: UIView.layoutFittingExpandedSize.height)
        let model = ShowHeaderViewModel()
        model.show = show
        let size = ShowHeaderView.MainView(model: model, viewExpanded: .constant(viewExpanded)).adaptiveSizeThatFits(in: fittingSize, for: horizontalSizeClass)
        return NSCollectionLayoutSize(widthDimension: .absolute(layoutWidth), heightDimension: .absolute(size.height))
    }
}

struct ShowHeaderView_Previews: PreviewProvider {
    private static let model: ShowHeaderViewModel = {
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
        ShowHeaderView.MainView(model: model, viewExpanded: .constant(false))
            .previewLayout(.sizeThatFits)
#else
        ShowHeaderView.MainView(model: model, viewExpanded: .constant(false))
            .frame(width: 1000)
            .previewLayout(.sizeThatFits)
            .environment(\.horizontalSizeClass, .regular)
        
        ShowHeaderView.MainView(model: model2, viewExpanded: .constant(false))
            .frame(width: 1000)
            .previewLayout(.sizeThatFits)
            .environment(\.horizontalSizeClass, .regular)
        
        ShowHeaderView.MainView(model: model, viewExpanded: .constant(false))
            .frame(width: 375)
            .previewLayout(.sizeThatFits)
            .environment(\.horizontalSizeClass, .compact)
#endif
    }
}
