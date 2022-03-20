//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

/// Behavior: h-exp, v-exp
struct TimelineView: View {
    let dateInterval: DateInterval?
    
    private static func label(for date: Date) -> String {
        return DateFormatter.play_time.string(from: date)
    }
    
    private func xPosition(for date: Date, width: CGFloat) -> CGFloat {
        guard let dateInterval = dateInterval else { return 0 }
        return ProgramGuideGridLayout.timelinePadding + ProgramGuideGridLayout.channelHeaderWidth
            + ProgramGuideGridLayout.horizontalSpacing + (width - ProgramGuideGridLayout.timelinePadding) * date.timeIntervalSince(dateInterval.start) / dateInterval.duration
    }
    
    private func enumerateDates(matching dateComponents: DateComponents) -> [Date] {
        guard let dateInterval = dateInterval else { return [] }
        
        var dates = [Date]()
        Calendar.current.enumerateDates(startingAfter: dateInterval.start, matching: dateComponents, matchingPolicy: .nextTime) { date, _, stop in
            guard let date = date else { return }
            if dateInterval.contains(date) {
                dates.append(date)
            }
            else {
                stop = true
            }
        }
        return dates
    }
    
    private var dates: [Date] {
        var dates = [Date]()
        
        var hourDateComponents = DateComponents()
        hourDateComponents.minute = 0
        dates.append(contentsOf: enumerateDates(matching: hourDateComponents))
        
        var halfHourDateComponents = DateComponents()
        halfHourDateComponents.minute = 30
        dates.append(contentsOf: enumerateDates(matching: halfHourDateComponents))
        
        return dates.sorted()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(dates, id: \.self) { date in
                VStack(spacing: 4) {
                    Text(Self.label(for: date))
                        .srgFont(.caption)
                        .foregroundColor(.white)
                    Rectangle()
                        .fill(Color.srgGray96)
                        .frame(width: 1, height: 15)
                }
                .position(x: xPosition(for: date, width: geometry.size.width), y: geometry.size.height / 2)
                .padding(.bottom, 8)
            }
        }
#if os(iOS)
        .background(Color.srgGray16)
#else
        .background(Color(white: 0, opacity: 0.2))
        .background(Blur(style: .dark))
#endif
        .accessibilityHidden(true)
    }
}

// MARK: Preview

struct TimelineView_Previews: PreviewProvider {
    private static let dateInterval = DateInterval(start: Date(), duration: 60 * 60 * 24)
    
    static var previews: some View {
        TimelineView(dateInterval: dateInterval)
            .previewLayout(.fixed(width: 4000, height: 100))
    }
}
