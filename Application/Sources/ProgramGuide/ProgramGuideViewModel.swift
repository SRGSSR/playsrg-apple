//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGDataProviderCombine

// MARK: View model

final class ProgramGuideViewModel: ObservableObject {
    @Published private(set) var data = Data(channels: [], selectedChannel: nil)
    @Published private(set) var dateSelection: DateSelection
    
    private var scrollingDateSelection: DateSelection
    
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
        return DateFormatter.play_relativeFull.string(from: dateSelection.day.date).capitalizedFirstLetter
    }
    
    init(date: Date) {
        dateSelection = DateSelection.atDate(date)
        scrollingDateSelection = DateSelection.atDate(date)
        
        Publishers.PublishAndRepeat(onOutputFrom: ApplicationSignal.wokenUp()) { [weak self] in
            return Self.tvPrograms(for: SRGDay(from: date))
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
        dateSelection = dateSelection.previousDay.atTime(scrollingDateSelection.time)
    }
    
    func switchToNextDay() {
        dateSelection = dateSelection.nextDay.atTime(scrollingDateSelection.time)
    }
    
    func switchToTonight() {
        dateSelection = DateSelection.tonight
    }
    
    func switchToNow() {
        dateSelection = DateSelection.now
    }
    
    func switchToDay(_ day: SRGDay) {
        dateSelection = dateSelection.atDay(day).atTime(scrollingDateSelection.time)
    }
    
    func didScrollToTime(of date: Date) {
        scrollingDateSelection = dateSelection.atTime(of: date)
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
        
        static var now: DateSelection {
            return atDate(Date())
        }
        
        static var tonight: DateSelection {
            let date = Calendar.current.date(bySettingHour: 20, minute: 30, second: 0, of: Date())!
            return atDate(date)
        }
        
        static func atDate(_ date: Date) -> DateSelection {
            let day = SRGDay(from: date)
            return DateSelection(day: day, time: date.timeIntervalSince(day.date))
        }
        
        var date: Date {
            return day.date.addingTimeInterval(time)
        }
        
        var previousDay: DateSelection {
            let previousDay = SRGDay(byAddingDays: -1, months: 0, years: 0, to: day)
            return DateSelection(day: previousDay, time: time)
        }
        
        var nextDay: DateSelection {
            let nextDay = SRGDay(byAddingDays: 1, months: 0, years: 0, to: day)
            return DateSelection(day: nextDay, time: time)
        }
        
        func atDay(_ day: SRGDay) -> DateSelection {
            return DateSelection(day: day, time: time)
        }
        
        func atTime(_ time: TimeInterval) -> DateSelection {
            return DateSelection(day: day, time: time)
        }
        
        func atTime(of date: Date) -> DateSelection {
            return atTime(date.timeIntervalSince(day.date))
        }
    }
}

// MARK: Publishers

private extension ProgramGuideViewModel {
    static func tvPrograms(for day: SRGDay) -> AnyPublisher<[SRGProgramComposition], Error> {
        let applicationConfiguration = ApplicationConfiguration.shared
        let vendor = applicationConfiguration.vendor
        
        if applicationConfiguration.areTvThirdPartyChannelsAvailable {
            return Publishers.CombineLatest(
                SRGDataProvider.current!.tvPrograms(for: vendor, day: day, minimal: true),
                SRGDataProvider.current!.tvPrograms(for: vendor, provider: .thirdParty, day: day, minimal: true)
            )
            .map { $0 + $1 }
            .eraseToAnyPublisher()
        }
        else {
            return SRGDataProvider.current!.tvPrograms(for: vendor, day: day, minimal: true)
        }
    }
}
