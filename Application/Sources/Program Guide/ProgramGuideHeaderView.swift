//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

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
        HStack(spacing: 10) {
            SimpleButton(icon: "chevron_previous", accessibilityLabel: PlaySRGAccessibilityLocalizedString("Previous day", comment: "Previous day button label in program guide")) {
                // TODO
            }
            Text(Self.formattedDate(for: day))
                .srgFont(.H2)
                .foregroundColor(.srgGrayC7)
                .frame(maxWidth: .infinity)
            SimpleButton(icon: "chevron_next", accessibilityLabel: PlaySRGAccessibilityLocalizedString("Next day", comment: "Next day button label in program guide")) {
                // TODO
            }
        }
        .padding(.horizontal, 10)
    }
}

struct ProgramGuideHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        ProgramGuideHeaderView()
            .previewLayout(.fixed(width: 375, height: 50))
    }
}
