//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

/// Behavior: h-exp, v-exp
struct ProgramGuideHeaderView: View {
    @ObservedObject var model: ProgramGuideViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            DaySelector(model: model)
            ChannelSelector(model: model)
            NavigationBar(model: model)
        }
        .padding(10)
        .fullScreenCover(isPresented: $model.isDatePickerPresented) {
            ZStack {
                Color.srgGray23
                    .edgesIgnoringSafeArea(.all)
                DatePickerView(model: model)
            }
        }
    }
    
    /// Behavior: h-exp, v-exp
    private struct DaySelector: View {
        @ObservedObject var model: ProgramGuideViewModel
        
        var body: some View {
            HStack(spacing: 10) {
                ExpandingButton(label: NSLocalizedString("Yesterday", comment: "Yesterday button in program guide")) {
                    model.switchToYesterday()
                }
                ExpandingButton(icon: "calendar", label: NSLocalizedString("Calendar", comment: "Calendar button in program guide")) {
                    model.isDatePickerPresented.toggle()
                }
                ExpandingButton(label: NSLocalizedString("Now", comment: "Now button in program guide")) {
                    model.switchToNow()
                }
            }
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
                SimpleButton(icon: "chevron_previous", accessibilityLabel: PlaySRGAccessibilityLocalizedString("Previous day program", comment: "Previous day button label in program guide")) {
                    model.switchToPreviousDay()
                }
                Text(model.dateString)
                    .srgFont(.H2)
                    .foregroundColor(.srgGrayC7)
                    .frame(maxWidth: .infinity)
                SimpleButton(icon: "chevron_next", accessibilityLabel: PlaySRGAccessibilityLocalizedString("Next day program", comment: "Next day button label in program guide")) {
                    model.switchToNextDay()
                }
            }
        }
    }
}

struct ProgramGuideHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        ProgramGuideHeaderView(model: ProgramGuideViewModel(date: Date()))
            .previewLayout(.fixed(width: 375, height: 180))
    }
}
