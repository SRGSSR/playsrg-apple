//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct ProgramGuideHeaderView: View {
    private(set) var day: SRGDay
    
    init(day: SRGDay = .today) {
        self.day = day
    }
    
    private static func formattedDate(for day: SRGDay) -> String {
        return DateFormatter.play_relative.string(from: day.date).capitalizedFirstLetter
    }
    
    var body: some View {
        Text(Self.formattedDate(for: day))
            .srgFont(.H2)
            .foregroundColor(.srgGrayC7)
    }
}

struct ProgramGuideHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        ProgramGuideHeaderView()
            .previewLayout(.fixed(width: 375, height: 50))
    }
}
