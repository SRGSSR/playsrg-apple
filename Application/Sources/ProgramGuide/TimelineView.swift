//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

/// Behavior: h-exp, v-exp
struct TimelineView: View {
    let dateInterval: DateInterval?
    
    private static let dateComponents: DateComponents = {
        var dateComponents = DateComponents()
        dateComponents.minute = 0
        return dateComponents
    }()
    
    private static func label(for date: Date) -> String {
        return DateFormatter.play_time.string(from: date)
    }
    
    private func xPosition(for date: Date, width: CGFloat) -> CGFloat {
        guard let dateInterval = dateInterval else { return 0 }
        return width * date.timeIntervalSince(dateInterval.start) / dateInterval.duration
    }
    
    private var dates: [Date] {
        guard let dateInterval = dateInterval else { return [] }
        
        var dates = [Date]()
        Calendar.current.enumerateDates(startingAfter: dateInterval.start, matching: Self.dateComponents, matchingPolicy: .nextTime) { date, _, stop in
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
    }
}

// MARK: Preview

struct TimelineView_Previews: PreviewProvider {
    private static let dateInterval = DateInterval(start: Date(), duration: 60 * 60 * 24)
    
    static var previews: some View {
        TimelineView(dateInterval: dateInterval)
            .previewLayout(.fixed(width: 2000, height: 100))
    }
}
