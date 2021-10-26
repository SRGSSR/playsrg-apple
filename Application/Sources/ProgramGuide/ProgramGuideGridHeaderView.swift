//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: Contract

@objc protocol ProgramGuideGridHeaderViewActions: AnyObject {
    func openCalendar()
}

// MARK: View

/// Behavior: h-exp, v-exp
struct ProgramGuideGridHeaderView: View {
    @ObservedObject var model: ProgramGuideViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            NavigationBar(model: model)
            DaySelector(model: model)
        }
        .frame(height: 40)
        .padding(10)
    }
    
    /// Behavior: h-exp, v-exp
    private struct DaySelector: View {
        @ObservedObject var model: ProgramGuideViewModel
        @FirstResponder private var firstResponder
        
        var body: some View {
            HStack(spacing: 10) {
                ExpandingButton(icon: "calendar", label: NSLocalizedString("Calendar", comment: "Calendar button in program guide")) {
                    firstResponder.sendAction(#selector(ProgramGuideGridHeaderViewActions.openCalendar))
                }
                ExpandingButton(label: NSLocalizedString("Yesterday", comment: "Yesterday button in program guide")) {
                    model.switchToYesterday()
                }
                ExpandingButton(label: NSLocalizedString("Now", comment: "Now button in program guide")) {
                    model.switchToNow()
                }
            }
            .responderChain(from: firstResponder)
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
                    .foregroundColor(.srgGrayC7)
                    .frame(maxWidth: .infinity)
                SimpleButton(icon: "chevron_next", accessibilityLabel: PlaySRGAccessibilityLocalizedString("Next day", comment: "Next day button label in program guide")) {
                    model.switchToNextDay()
                }
            }
        }
    }
}

struct ProgramGuideGridHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        ProgramGuideGridHeaderView(model: ProgramGuideViewModel(date: Date()))
            .previewLayout(.fixed(width: 1024, height: 120))
    }
}
