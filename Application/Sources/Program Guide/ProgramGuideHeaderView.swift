//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: Contract

@objc protocol ProgramGuideHeaderViewActions: AnyObject {
    func previousDay()
    func nextDay()
    func yesterday()
    func now()
}

// MARK: View

struct ProgramGuideHeaderView: View {
    @ObservedObject var model: ProgramGuideViewModel
    
    private static func formattedDate(for day: SRGDay) -> String {
        return DateFormatter.play_relative.string(from: day.date).capitalizedFirstLetter
    }
    
    var body: some View {
        ResponderChain { firstResponder in
            VStack {
                HStack(spacing: 10) {
                    ExpandedButton(label: NSLocalizedString("Yesterday", comment: "Yesterday button in program guide")) {
                        firstResponder.sendAction(#selector(ProgramGuideHeaderViewActions.yesterday))
                    }
                    ExpandedButton(icon: "calendar", label: NSLocalizedString("Calendar", comment: "Calendar button in program guide")) {
                        // TODO
                    }
                    ExpandedButton(label: NSLocalizedString("Now", comment: "Now button in program guide")) {
                        firstResponder.sendAction(#selector(ProgramGuideHeaderViewActions.now))
                    }
                }
                .frame(maxWidth: .infinity)
                
                HStack(spacing: 10) {
                    SimpleButton(icon: "chevron_previous", accessibilityLabel: PlaySRGAccessibilityLocalizedString("Previous day program", comment: "Previous day button label in program guide")) {
                        firstResponder.sendAction(#selector(ProgramGuideHeaderViewActions.previousDay))
                    }
                    Text(Self.formattedDate(for: model.day))
                        .srgFont(.H2)
                        .foregroundColor(.srgGrayC7)
                        .frame(maxWidth: .infinity)
                    SimpleButton(icon: "chevron_next", accessibilityLabel: PlaySRGAccessibilityLocalizedString("Next day program", comment: "Next day button label in program guide")) {
                        firstResponder.sendAction(#selector(ProgramGuideHeaderViewActions.nextDay))
                    }
                }
            }
            .padding(10)
        }
    }
}

struct ProgramGuideHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        ProgramGuideHeaderView(model: ProgramGuideViewModel(day: SRGDay.today))
            .previewLayout(.fixed(width: 375, height: 100))
    }
}
