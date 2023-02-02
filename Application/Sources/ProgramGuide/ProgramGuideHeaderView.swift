//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI
import SRGDataProviderModel

// MARK: Contract

#if os(iOS)
@objc protocol ProgramGuideHeaderViewActions: AnyObject {
    func openCalendar()
}
#endif

// MARK: View

/// Behavior: h-exp, v-exp
struct ProgramGuideHeaderView: View {
    @ObservedObject var model: ProgramGuideViewModel
    let layout: ProgramGuideLayout
    
    var body: some View {
#if os(tvOS)
        ZStack {
            ProgramPreview(program: model.focusedProgram)
                .accessibilityHidden(true)
            NavigationBar(model: model)
                .focusable()
                .padding(.horizontal, 56)
                .padding(.vertical, 40 + ProgramGuideGridLayout.timelineHeight)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
#else
        VStack(spacing: 0) {
            NavigationBar(model: model)
            Spacer(minLength: 20)
            if layout == .list {
                ChannelSelector(model: model)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
#endif
    }
    
    /// Behavior: h-exp, v-hug
    private struct NavigationBar: View {
        @ObservedObject var model: ProgramGuideViewModel
        @Environment(\.uiHorizontalSizeClass) private var horizontalSizeClass
        
        private static let itemHeight: CGFloat = constant(iOS: 40, tvOS: 70)
        private static let spacing: CGFloat = constant(iOS: 42, tvOS: 40)
        
        private var direction: StackDirection {
            return (horizontalSizeClass == .compact) ? .vertical : .horizontal
        }
        
        var body: some View {
            Group {
                if direction == .vertical {
                    VStack(spacing: Self.spacing) {
                        DaySelector(model: model)
                            .frame(height: Self.itemHeight)
                        DayNavigationBar(model: model)
                            .frame(height: Self.itemHeight)
                    }
                }
                else {
                    HStack(spacing: Self.spacing) {
                        DayNavigationBar(model: model)
                            .frame(maxWidth: constant(iOS: 400, tvOS: 750))
                        DaySelector(model: model)
                            .frame(maxWidth: 480)
                    }
                    .frame(maxWidth: .infinity, maxHeight: Self.itemHeight, alignment: .leading)
                }
            }
        }
    }
    
    /// Behavior: h-exp, v-exp
    private struct DaySelector: View {
        @ObservedObject var model: ProgramGuideViewModel
        @FirstResponder private var firstResponder
        
        var body: some View {
            HStack(spacing: constant(iOS: 10, tvOS: 40)) {
#if os(iOS)
                ExpandingButton(icon: "calendar", label: NSLocalizedString("Calendar", comment: "Calendar button in program guide")) {
                    firstResponder.sendAction(#selector(ProgramGuideHeaderViewActions.openCalendar))
                }
#endif
                ExpandingButton(label: NSLocalizedString("Now", comment: "Now button in program guide")) {
                    AnalyticsClickEvent.tvGuideNow().send()
                    model.switchToNow()
                }
                ExpandingButton(label: NSLocalizedString("Tonight", comment: "Tonight button in program guide")) {
                    AnalyticsClickEvent.tvGuideTonight().send()
                    model.switchToTonight()
                }
            }
            .responderChain(from: firstResponder)
        }
    }
    
    /// Behavior: h-exp, v-exp
    private struct DayNavigationBar: View {
        @ObservedObject var model: ProgramGuideViewModel
        @FirstResponder private var firstResponder
        
        private static let buttonWidth: CGFloat = constant(iOS: 43, tvOS: 70)
        
        var body: some View {
            HStack(spacing: constant(iOS: 10, tvOS: 40)) {
                ExpandingButton(icon: "chevron_previous", accessibilityLabel: PlaySRGAccessibilityLocalizedString("Previous day", comment: "Previous day button label in program guide")) {
                    AnalyticsClickEvent.tvGuidePreviousDay().send()
                    model.switchToPreviousDay()
                }
                .frame(width: Self.buttonWidth)
                
#if os(iOS)
                Button(action: action) {
                    DateView(model: model)
                }
#else
                DateView(model: model)
#endif
                
                ExpandingButton(icon: "chevron_next", accessibilityLabel: PlaySRGAccessibilityLocalizedString("Next day", comment: "Next day button label in program guide")) {
                    AnalyticsClickEvent.tvGuideNextDay().send()
                    model.switchToNextDay()
                }
                .frame(width: Self.buttonWidth)
            }
            .responderChain(from: firstResponder)
        }
        
        /// Behavior: h-exp, v-hug
        private struct DateView: View {
            @ObservedObject var model: ProgramGuideViewModel
            
            var body: some View {
                Text(model.dateString)
                    .srgFont(.H2)
                    .minimumScaleFactor(0.8)
                    .foregroundColor(.srgGrayC7)
                    .frame(maxWidth: .infinity)
            }
        }
        
#if os(iOS)
        private func action() {
            firstResponder.sendAction(#selector(ProgramGuideHeaderViewActions.openCalendar))
        }
#endif
    }
    
#if os(iOS)
    /// Behavior: h-exp, v-hug
    private struct ChannelSelector: View {
        @ObservedObject var model: ProgramGuideViewModel
        
        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { proxy in
                    HStack(spacing: 10) {
                        if !model.channels.isEmpty {
                            ForEach(model.channels, id: \.uid) { channel in
                                ChannelButton(channel: channel) {
                                    model.selectedChannel = channel
                                }
                                .environment(\.isSelected, channel == model.selectedChannel)
                            }
                            .onAppear {
                                if let selectedChannel = model.selectedChannel {
                                    proxy.scrollTo(selectedChannel.uid)
                                }
                            }
                        }
                        else {
                            ForEach(0..<2) { _ in
                                ChannelButton(channel: nil, action: {})
                            }
                        }
                    }
                }
            }
            .frame(height: 50)
            .padding(.bottom, 6)
        }
    }
#endif
}

// MARK: Size

enum ProgramGuideHeaderViewSize {
    static func height(for layout: ProgramGuideLayout, horizontalSizeClass: UIUserInterfaceSizeClass) -> CGFloat {
#if os(iOS)
        switch layout {
        case .grid:
            return (horizontalSizeClass == .compact) ? 160 : 80
        case .list:
            return (horizontalSizeClass == .compact) ? 216 : 136
        }
#else
        return ApplicationConfiguration.shared.areTvThirdPartyChannelsAvailable ? 650 : 760
#endif
    }
}

// MARK: Preview

struct ProgramGuideHeaderView_Previews: PreviewProvider {
    static var previews: some View {
#if os(tvOS)
        ProgramGuideHeaderView(model: ProgramGuideViewModel(date: Date()), layout: .grid)
            .previewLayout(.fixed(width: 1920, height: 600))
#else
        ProgramGuideHeaderView(model: ProgramGuideViewModel(date: Date()), layout: .grid)
            .previewLayout(.fixed(width: 1000, height: ProgramGuideHeaderViewSize.height(for: .grid, horizontalSizeClass: .regular)))
            .environment(\.horizontalSizeClass, .regular)
            .previewDisplayName("Grid, regular")
        ProgramGuideHeaderView(model: ProgramGuideViewModel(date: Date()), layout: .grid)
            .previewLayout(.fixed(width: 375, height: ProgramGuideHeaderViewSize.height(for: .grid, horizontalSizeClass: .compact)))
            .environment(\.horizontalSizeClass, .compact)
            .previewDisplayName("Grid, compact")
        ProgramGuideHeaderView(model: ProgramGuideViewModel(date: Date()), layout: .list)
            .previewLayout(.fixed(width: 1000, height: ProgramGuideHeaderViewSize.height(for: .list, horizontalSizeClass: .regular)))
            .environment(\.horizontalSizeClass, .regular)
            .previewDisplayName("List, regular")
        ProgramGuideHeaderView(model: ProgramGuideViewModel(date: Date()), layout: .list)
            .previewLayout(.fixed(width: 375, height: ProgramGuideHeaderViewSize.height(for: .list, horizontalSizeClass: .compact)))
            .environment(\.horizontalSizeClass, .compact)
            .previewDisplayName("List, compact")
#endif
    }
}
