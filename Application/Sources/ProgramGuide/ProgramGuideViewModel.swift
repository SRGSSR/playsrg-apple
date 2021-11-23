//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine

// MARK: View model

final class ProgramGuideViewModel: ObservableObject {
    @Published private(set) var data = Data(channels: [], selectedChannel: nil)
    @Published private(set) var dateSelection: DateSelection
    
    var channels: [SRGChannel] {
        return data.channels
    }
    
    var selectedChannel: SRGChannel? {
        get {
            return data.selectedChannel
        }
        set {
            if let newValue = newValue, channels.contains(newValue) {
                data = Data(channels: channels, selectedChannel: newValue)
            }
        }
    }
    
    var dateString: String {
        return DateFormatter.play_relative.string(from: dateSelection.day.date).capitalizedFirstLetter
    }
    
    init(date: Date) {
        self.dateSelection = DateSelection.atDate(date, transition: .none)
        
        Publishers.PublishAndRepeat(onOutputFrom: ApplicationSignal.wokenUp()) { [weak self] in
            return SRGDataProvider.current!.tvPrograms(for: ApplicationConfiguration.shared.vendor, day: SRGDay(from: date))
                .map { $0.map(\.channel) }
                .replaceError(with: self?.channels ?? [])
        }
        .map { [weak self] channels in
            if let selectedChannel = self?.selectedChannel, channels.contains(selectedChannel) {
                return Data(channels: channels, selectedChannel: selectedChannel)
            }
            else {
                return Data(channels: channels, selectedChannel: channels.first)
            }
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$data)
    }
    
    func switchToPreviousDay() {
        dateSelection = dateSelection.previousDay(transition: .day)
    }
    
    func switchToNextDay() {
        dateSelection = dateSelection.nextDay(transition: .day)
    }
    
    func switchToTonight() {
        dateSelection = DateSelection.tonight(from: dateSelection)
    }
    
    func switchToNow() {
        dateSelection = DateSelection.now(from: dateSelection)
    }
    
    func switchToDay(_ day: SRGDay) {
        dateSelection = dateSelection.atDay(day, transition: .day)
    }
    
    func scrollToDay(_ day: SRGDay) {
        dateSelection = dateSelection.atDay(day, transition: .none)
    }
    
    func didScrollToTime(of date: Date) {
        dateSelection = dateSelection.atTime(of: date, transition: .none)
    }
}

// MARK: Types

extension ProgramGuideViewModel {
    struct Data {
        let channels: [SRGChannel]
        let selectedChannel: SRGChannel?
    }
    
    struct DateSelection: Hashable {
        enum Transition {
            case none
            case day
            case time
        }
        
        let day: SRGDay
        let time: TimeInterval      // Offset from midnight
        let transition: Transition
        
        var date: Date {
            return day.date.addingTimeInterval(time)
        }
        
        fileprivate func previousDay(transition: Transition) -> DateSelection {
            let previousDay = SRGDay(byAddingDays: -1, months: 0, years: 0, to: day)
            return DateSelection(day: previousDay, time: time, transition: transition)
        }
        
        fileprivate func nextDay(transition: Transition) -> DateSelection {
            let nextDay = SRGDay(byAddingDays: 1, months: 0, years: 0, to: day)
            return DateSelection(day: nextDay, time: time, transition: transition)
        }
        
        fileprivate func atDay(_ day: SRGDay, transition: Transition) -> DateSelection {
            return DateSelection(day: day, time: time, transition: transition)
        }
        
        fileprivate func atTime(of date: Date, transition: Transition) -> DateSelection {
            return DateSelection(day: day, time: date.timeIntervalSince(day.date), transition: transition)
        }
        
        fileprivate static func now(from dateSelection: DateSelection) -> DateSelection {
            return updatedDateSelection(from: dateSelection, for: Date())
        }
        
        fileprivate static func tonight(from dateSelection: DateSelection) -> DateSelection {
            let date = Calendar.current.date(bySettingHour: 20, minute: 30, second: 0, of: Date())!
            return updatedDateSelection(from: dateSelection, for: date)
        }
        
        private static func updatedDateSelection(from dateSelection: DateSelection, for date: Date) -> DateSelection {
            let transition: Transition = Calendar.current.isDate(date, inSameDayAs: dateSelection.day.date) ? .time : .day
            return atDate(date, transition: transition)
        }
        
        fileprivate static func atDate(_ date: Date, transition: Transition) -> DateSelection {
            let day = SRGDay(from: date)
            return DateSelection(day: day, time: date.timeIntervalSince(day.date), transition: transition)
        }
    }
}
