//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI
import SRGDataProviderModel

// MARK: Contract

@objc protocol ProgramGuideGridHeaderViewActions: AnyObject {
    func openCalendar()
}

// MARK: View

/// Behavior: h-exp, v-exp
struct ProgramGuideGridHeaderView: View {
    @ObservedObject var model: ProgramGuideViewModel
    
#if os(tvOS)
    let focusedProgram: SRGProgram?
#endif
    
    var body: some View {
        ZStack {
#if os(tvOS)
            ProgramPreview(program: focusedProgram)
#endif
            NavigationBar(model: model)
        }
    }
    
    /// Behavior: h-exp, v-exp
    private struct NavigationBar: View {
        @ObservedObject var model: ProgramGuideViewModel
        
#if os(iOS)
        @Environment(\.horizontalSizeClass) var horizontalSizeClass
#endif
        
        private static let itemHeight: CGFloat = constant(iOS: 40, tvOS: 80)
        private static let spacing: CGFloat = constant(iOS: 20, tvOS: 40)
        
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
                        DaySelector(model: model)
                    }
                    .frame(height: Self.itemHeight)
                }
            }
            .padding(.horizontal, constant(iOS: 10, tvOS: 20))
            .padding(.vertical, Self.spacing)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
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
    private struct DayNavigationBar: View {
        @ObservedObject var model: ProgramGuideViewModel
        
        private static let buttonWidth: CGFloat = constant(iOS: 40, tvOS: 60)
        
        var body: some View {
            HStack(spacing: constant(iOS: 10, tvOS: 40)) {
                ExpandingButton(icon: "chevron_previous", accessibilityLabel: PlaySRGAccessibilityLocalizedString("Previous day", comment: "Previous day button label in program guide")) {
                    model.switchToPreviousDay()
                }
                .frame(width: Self.buttonWidth)
                
                Text(model.dateString)
                    .srgFont(.H2)
                    .foregroundColor(.srgGrayC7)
                    .frame(maxWidth: .infinity)
                
                ExpandingButton(icon: "chevron_next", accessibilityLabel: PlaySRGAccessibilityLocalizedString("Next day", comment: "Next day button label in program guide")) {
                    model.switchToNextDay()
                }
                .frame(width: Self.buttonWidth)
            }
        }
    }
}

struct ProgramGuideGridHeaderView_Previews: PreviewProvider {
    static var previews: some View {
#if os(tvOS)
        ProgramGuideGridHeaderView(model: ProgramGuideViewModel(date: Date()), focusedProgram: Mock.program())
            .previewLayout(.fixed(width: 1920, height: 600))
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
