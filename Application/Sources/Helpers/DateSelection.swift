//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation
import SRGDataProviderModel

/**
 *  Relative dates are dates associated with some day but do not necessarily have to belong to it. Relative
 *  dates are stored using an offset from midnight of the reference day. They are especially useful in the
 *  context of TV program lists for which programs associated with a day might partially or entirely belong
 *  to the next day.
 */
struct RelativeDate: Hashable {
    let day: SRGDay
    let time: TimeInterval          // Offset from midnight
    
    static var now: RelativeDate {
        return atDate(Date())
    }
    
    static var tonight: RelativeDate {
        let date = Calendar.current.date(bySettingHour: 20, minute: 30, second: 0, of: Date())!
        return atDate(date)
    }
    
    static func atDate(_ date: Date) -> RelativeDate {
        let day = SRGDay(from: date)
        return RelativeDate(day: day, time: date.timeIntervalSince(day.date))
    }
    
    var date: Date {
        return day.date.addingTimeInterval(time)
    }
    
    var previousDay: RelativeDate {
        let previousDay = SRGDay(byAddingDays: -1, months: 0, years: 0, to: day)
        return RelativeDate(day: previousDay, time: time)
    }
    
    var nextDay: RelativeDate {
        let nextDay = SRGDay(byAddingDays: 1, months: 0, years: 0, to: day)
        return RelativeDate(day: nextDay, time: time)
    }
    
    func atDay(_ day: SRGDay) -> RelativeDate {
        return RelativeDate(day: day, time: time)
    }
    
    func atTime(_ time: TimeInterval) -> RelativeDate {
        return RelativeDate(day: day, time: time)
    }
    
    func atTime(of date: Date) -> RelativeDate {
        return atTime(date.timeIntervalSince(day.date))
    }
}
