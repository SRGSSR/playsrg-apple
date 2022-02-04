//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: Contract

@objc protocol ProgramGuideListHeaderViewActions: AnyObject {
    func openCalendar()
}

// MARK: View

/// Behavior: h-exp, v-exp
struct ProgramGuideListHeaderView: View {
    @ObservedObject var model: ProgramGuideViewModel
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var direction: StackDirection {
        return (horizontalSizeClass == .compact) ? .vertical : .horizontal
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if direction == .vertical {
                DaySelector(model: model)
                ChannelSelector(model: model)
                DayNavigationBar(model: model)
            }
            else {
                ChannelSelector(model: model)
                NavigationBar(model: model)
            }
        }
        .padding(10)
    }
    
    /// Behavior: h-exp, v-exp
    private struct DaySelector: View {
        @ObservedObject var model: ProgramGuideViewModel
        @FirstResponder private var firstResponder
        
        var body: some View {
            HStack(spacing: 10) {
                ExpandingButton(icon: "calendar", label: NSLocalizedString("Calendar", comment: "Calendar button in program guide")) {
                    firstResponder.sendAction(#selector(ProgramGuideListHeaderViewActions.openCalendar))
                }
                ExpandingButton(label: NSLocalizedString("Now", comment: "Now button in program guide")) {
                    model.switchToNow()
                }
                ExpandingButton(label: NSLocalizedString("Tonight", comment: "Tonight button in program guide")) {
                    model.switchToTonight()
                }
            }
            .responderChain(from: firstResponder)
        }
    }
    
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
        }
    }
    
    /// Behavior: h-exp, v-hug
    private struct DayNavigationBar: View {
        @ObservedObject var model: ProgramGuideViewModel
        
        var body: some View {
            HStack(spacing: 10) {
                SimpleButton(icon: "chevron_previous", accessibilityLabel: PlaySRGAccessibilityLocalizedString("Previous day", comment: "Previous day button label in program guide")) {
                    model.switchToPreviousDay()
                }
                Text(model.dateString)
                    .srgFont(.H2)
                    .minimumScaleFactor(0.8)
                    .foregroundColor(.srgGrayC7)
                    .frame(maxWidth: .infinity)
                SimpleButton(icon: "chevron_next", accessibilityLabel: PlaySRGAccessibilityLocalizedString("Next day", comment: "Next day button label in program guide")) {
                    model.switchToNextDay()
                }
            }
        }
    }
    
    /// Behavior: h-exp, v-exp
    private struct NavigationBar: View {
        @ObservedObject var model: ProgramGuideViewModel
                
        private static let itemHeight: CGFloat = 40
        private static let spacing: CGFloat = 42
        
        var body: some View {
            Group {
                HStack(spacing: Self.spacing) {
                    DayNavigationBar(model: model)
                        .frame(maxWidth: 400)
                    DaySelector(model: model)
                        .frame(maxWidth: 480)
                }
                .frame(maxWidth: .infinity, maxHeight: Self.itemHeight, alignment: .leading)
            }
            .padding(.horizontal, 10)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}

struct ProgramGuideListHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        ProgramGuideListHeaderView(model: ProgramGuideViewModel(date: Date()))
            .previewLayout(.fixed(width: 375, height: 180))
            .environment(\.horizontalSizeClass, .compact)
        ProgramGuideListHeaderView(model: ProgramGuideViewModel(date: Date()))
            .previewLayout(.fixed(width: 1000, height: 120))
            .environment(\.horizontalSizeClass, .regular)
    }
}
