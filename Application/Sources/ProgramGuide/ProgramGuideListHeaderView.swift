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
    
    var body: some View {
        VStack(spacing: 20) {
            DaySelector(model: model)
            ChannelSelector(model: model)
            NavigationBar(model: model)
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
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    if !model.channels.isEmpty {
                        ForEach(model.channels, id: \.uid) { channel in
                            ChannelButton(channel: channel) {
                                model.selectedChannel = channel
                            }
                            .environment(\.isSelected, channel == model.selectedChannel)
                        }
                    }
                    else {
                        ForEach(0..<2) { _ in
                            ChannelButton(channel: nil, action: {})
                        }
                    }
                }
            }
            .frame(height: 50)
        }
    }
    
    /// Behavior: h-exp, v-hug
    private struct NavigationBar: View {
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
}

struct ProgramGuideListHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        ProgramGuideListHeaderView(model: ProgramGuideViewModel(date: Date()))
            .previewLayout(.fixed(width: 375, height: 180))
    }
}
