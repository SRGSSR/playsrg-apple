//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct ProgramGuideHeaderView: View {
    @ObservedObject var model: ProgramGuideViewModel
    
    private static func formattedDate(for date: Date) -> String {
        return DateFormatter.play_relative.string(from: date).capitalizedFirstLetter
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 10) {
                ExpandingButton(label: NSLocalizedString("Yesterday", comment: "Yesterday button in program guide")) {
                    model.yesterday()
                }
                ExpandingButton(icon: "calendar", label: NSLocalizedString("Calendar", comment: "Calendar button in program guide")) {
                    model.isDatePickerPresented.toggle()
                }
                ExpandingButton(label: NSLocalizedString("Now", comment: "Now button in program guide")) {
                    model.todayAtCurrentTime()
                }
            }
            .frame(maxWidth: .infinity)
            
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(model.items, id: \.self) { channelItem in
                        ChannelButton(channel: channelItem.channel) {
                            if let channel = channelItem.channel {
                                model.selectedChannel = channel
                            }
                        }
                        .environment(\.isSelected, channelItem.channel != nil && channelItem.channel == model.selectedChannel)
                    }
                }
            }
            .frame(height: 50)
            
            HStack(spacing: 10) {
                SimpleButton(icon: "chevron_previous", accessibilityLabel: PlaySRGAccessibilityLocalizedString("Previous day program", comment: "Previous day button label in program guide")) {
                    model.previousDay()
                }
                Text(Self.formattedDate(for: model.selectedDate))
                    .srgFont(.H2)
                    .foregroundColor(.srgGrayC7)
                    .frame(maxWidth: .infinity)
                SimpleButton(icon: "chevron_next", accessibilityLabel: PlaySRGAccessibilityLocalizedString("Next day program", comment: "Next day button label in program guide")) {
                    model.nextDay()
                }
            }
        }
        .padding(10)
        .fullScreenCover(isPresented: $model.isDatePickerPresented) {
            ZStack {
                Color.srgGray23
                    .edgesIgnoringSafeArea(.all)
                DatePickerView(isDatePickerPresented: $model.isDatePickerPresented, savedDate: $model.selectedDate)
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
