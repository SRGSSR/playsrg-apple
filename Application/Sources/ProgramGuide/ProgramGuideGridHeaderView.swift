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
    
#if os(iOS)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
#endif
    
    private var direction: StackDirection {
#if os(iOS)
        return (horizontalSizeClass == .compact) ? .vertical : .horizontal
#else
        return .horizontal
#endif
    }
    
    var body: some View {
        Group {
            if direction == .vertical {
                VStack(spacing: constant(iOS: 20, tvOS: 40)) {
                    DaySelector(model: model)
                    NavigationBar(model: model)
                }
                .frame(height: constant(iOS: 40, tvOS: 80))
            }
            else {
                HStack(spacing: constant(iOS: 20, tvOS: 40)) {
                    NavigationBar(model: model)
                    DaySelector(model: model)
                }
                .frame(height: constant(iOS: 40, tvOS: 80))
            }
        }
        .padding(constant(iOS: 10, tvOS: 20))
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
    
    /// Behavior: h-exp, v-exp
    private struct DaySelector: View {
        @ObservedObject var model: ProgramGuideViewModel
        @FirstResponder private var firstResponder
        
        var body: some View {
            HStack(spacing: constant(iOS: 10, tvOS: 40)) {
                ExpandingButton(label: NSLocalizedString("Yesterday", comment: "Yesterday button in program guide")) {
                    model.switchToYesterday()
                }
#if os(iOS)
                ExpandingButton(icon: "calendar", label: NSLocalizedString("Calendar", comment: "Calendar button in program guide")) {
                    firstResponder.sendAction(#selector(ProgramGuideGridHeaderViewActions.openCalendar))
                }
#endif
                ExpandingButton(label: NSLocalizedString("Now", comment: "Now button in program guide")) {
                    model.switchToNow()
                }
            }
            .responderChain(from: firstResponder)
        }
    }
    
    /// Behavior: h-exp, v-exp
    private struct NavigationBar: View {
        @ObservedObject var model: ProgramGuideViewModel
        
        private static let itemWidth: CGFloat = constant(iOS: 40, tvOS: 60)
        
        var body: some View {
            HStack(spacing: constant(iOS: 10, tvOS: 40)) {
                ExpandingButton(icon: "chevron_previous", accessibilityLabel: PlaySRGAccessibilityLocalizedString("Previous day", comment: "Previous day button label in program guide")) {
                    model.switchToPreviousDay()
                }
                .frame(width: Self.itemWidth)
                
                Text(model.dateString)
                    .srgFont(.H2)
                    .foregroundColor(.srgGrayC7)
                    .frame(maxWidth: .infinity)
                
                ExpandingButton(icon: "chevron_next", accessibilityLabel: PlaySRGAccessibilityLocalizedString("Next day", comment: "Next day button label in program guide")) {
                    model.switchToNextDay()
                }
                .frame(width: Self.itemWidth)
            }
        }
    }
}

struct ProgramGuideGridHeaderView_Previews: PreviewProvider {
    static var previews: some View {
#if os(tvOS)
        ProgramGuideGridHeaderView(model: ProgramGuideViewModel(date: Date()))
            .previewLayout(.sizeThatFits)
#else
        ProgramGuideGridHeaderView(model: ProgramGuideViewModel(date: Date()))
            .previewLayout(.fixed(width: 1000, height: 120))
            .environment(\.horizontalSizeClass, .regular)
        
        ProgramGuideGridHeaderView(model: ProgramGuideViewModel(date: Date()))
            .previewLayout(.fixed(width: 375, height: 240))
            .environment(\.horizontalSizeClass, .compact)
#endif
    }
}
