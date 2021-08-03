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
    let day: SRGDay
    
    init(day: SRGDay = .today) {
        self.day = day
    }
    
    private static func formattedDate(for day: SRGDay) -> String {
        return DateFormatter.play_relative.string(from: day.date).capitalizedFirstLetter
    }
    
    var body: some View {
        ResponderChain { firstResponder in
            VStack {
                HStack(spacing: 10) {
                    Button {
                        firstResponder.sendAction(#selector(ProgramGuideHeaderViewActions.yesterday))
                    } label: {
                        HStack {
                            Text(NSLocalizedString("Yesterday", comment: "Yesterday button in program guide"))
                                .srgFont(.button)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.srgGray23)
                        .cornerRadius(LayoutStandardViewCornerRadius)
                    }
                    .foregroundColor(.srgGrayC7)
                    .accessibilityElement(label: NSLocalizedString("Yesterday", comment: "Yesterday button in program guide"), traits: .isButton)
                    
                    Button {
                        // TODO
                    } label: {
                        HStack {
                            Image("calendar")
                            Text(NSLocalizedString("Calendar", comment: "Calendar button in program guide"))
                                .srgFont(.button)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.srgGray23)
                        .cornerRadius(LayoutStandardViewCornerRadius)
                    }
                    .foregroundColor(.srgGrayC7)
                    .accessibilityElement(label: NSLocalizedString("Calendar", comment: "Calendar button in program guide"), traits: .isButton)
                    
                    Button {
                        firstResponder.sendAction(#selector(ProgramGuideHeaderViewActions.now))
                    } label: {
                        HStack {
                            Text(NSLocalizedString("Now", comment: "Now button in program guide"))
                                .srgFont(.button)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.srgGray23)
                        .cornerRadius(LayoutStandardViewCornerRadius)
                    }
                    .foregroundColor(.srgGrayC7)
                    .accessibilityElement(label: NSLocalizedString("Now", comment: "Now button in program guide"), traits: .isButton)
                }
                .frame(maxWidth: .infinity)
                
                HStack(spacing: 10) {
                    SimpleButton(icon: "chevron_previous", accessibilityLabel: PlaySRGAccessibilityLocalizedString("Previous day", comment: "Previous day button label in program guide")) {
                        firstResponder.sendAction(#selector(ProgramGuideHeaderViewActions.previousDay))
                    }
                    Text(Self.formattedDate(for: day))
                        .srgFont(.H2)
                        .foregroundColor(.srgGrayC7)
                        .frame(maxWidth: .infinity)
                    SimpleButton(icon: "chevron_next", accessibilityLabel: PlaySRGAccessibilityLocalizedString("Next day", comment: "Next day button label in program guide")) {
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
        ProgramGuideHeaderView()
            .previewLayout(.fixed(width: 375, height: 100))
    }
}
