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
    @Published var isDatePickerPresented: Bool = false
    
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
        self.dateSelection = DateSelection.atDate(date, animated: false)
        
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
    
    func previousDay() {
        dateSelection = dateSelection.previousDay()
    }
    
    func nextDay() {
        dateSelection = dateSelection.nextDay()
    }
    
    func yesterday() {
        dateSelection = dateSelection.yesterday()
    }
    
    func now() {
        dateSelection = DateSelection.now()
    }
    
    func atDay(_ day: SRGDay) {
        dateSelection = dateSelection.atDay(day)
    }
    
    func atTime(of date: Date) {
        dateSelection = dateSelection.atTime(of: date)
    }
}

// MARK: Types

extension ProgramGuideViewModel {
    struct Data {
        let channels: [SRGChannel]
        let selectedChannel: SRGChannel?
    }
    
    struct DateSelection: Hashable {
        let day: SRGDay
        let time: TimeInterval      // Offset from midnight
        let animated: Bool
        
        var date: Date {
            return day.date.addingTimeInterval(time)
        }
        
        fileprivate func previousDay() -> DateSelection {
            let previousDay = SRGDay(byAddingDays: -1, months: 0, years: 0, to: day)
            return DateSelection(day: previousDay, time: time, animated: false)
        }
        
        fileprivate func nextDay() -> DateSelection {
            let nextDay = SRGDay(byAddingDays: 1, months: 0, years: 0, to: day)
            return DateSelection(day: nextDay, time: time, animated: false)
        }
        
        fileprivate func yesterday() -> DateSelection {
            let yesterday = SRGDay(byAddingDays: -1, months: 0, years: 0, to: SRGDay.today)
            return DateSelection(day: yesterday, time: time, animated: false)
        }
        
        fileprivate func atDay(_ day: SRGDay) -> DateSelection {
            return DateSelection(day: day, time: time, animated: false)
        }
        
        fileprivate func atTime(of date: Date) -> DateSelection {
            return DateSelection(day: day, time: date.timeIntervalSince(day.date), animated: false)
        }
        
        static func now() -> DateSelection {
            return atDate(Date(), animated: true)
        }
        
        fileprivate static func atDate(_ date: Date, animated: Bool) -> DateSelection {
            let day = SRGDay(from: date)
            return DateSelection(day: day, time: date.timeIntervalSince(day.date), animated: animated)
        }
    }
}
