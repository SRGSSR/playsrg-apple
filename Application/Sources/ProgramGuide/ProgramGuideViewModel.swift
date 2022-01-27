//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGDataProviderCombine
import Foundation

// MARK: View model

final class ProgramGuideViewModel: ObservableObject {
    @Published private(set) var bouquet: Bouquet = .empty
    @Published private(set) var day: SRGDay
    @Published private(set) var time: TimeInterval
    
    /// We store the time to which the user scrolled (reported with `didScrollToTime(of:)` not in `time`, but in a
    /// separate property. This avoids publishing unnecessary updates as a result of the user navigating the content.
    /// This separate value is only used to update the `time` when transitioning between days so that only meaningful
    /// updates are published.
    private(set) var scrollTime: TimeInterval
    
    static func time(from date: Date, relativeTo day: SRGDay) -> TimeInterval {
        return date.timeIntervalSince(day.date)
    }
    
    var channels: [SRGChannel] {
        return bouquet.channels
    }
    
    var firstPartyChannels: [SRGChannel] {
        return bouquet.firstPartyChannels
    }
    
    var thirdPartyChannels: [SRGChannel] {
        return bouquet.thirdPartyChannels
    }
    
    var selectedChannel: SRGChannel? {
        get {
            return bouquet.selectedChannel
        }
        set {
            if let newValue = newValue, channels.contains(newValue) {
                bouquet = Bouquet(firstPartyChannels: firstPartyChannels, thirdPartyChannels: thirdPartyChannels, selectedChannel: newValue)
            }
        }
    }
    
    func date(for time: TimeInterval) -> Date {
        return day.date.addingTimeInterval(time)
    }
    
    var dateString: String {
        return DateFormatter.play_relativeFull.string(from: day.date).capitalizedFirstLetter
    }
    
    init(date: Date) {
        let initialDay = SRGDay(from: date)
        day = initialDay
        
        let initialTime = Self.time(from: date, relativeTo: initialDay)
        time = initialTime
        scrollTime = initialTime
        
        Publishers.PublishAndRepeat(onOutputFrom: ApplicationSignal.wokenUp()) { [weak self] in
            // TODO: Should use a channel request without day dependency here
            return Self.bouquet(for: initialDay)
                .replaceError(with: self?.bouquet ?? Bouquet(firstPartyChannels: [], thirdPartyChannels: [], selectedChannel: nil))
        }
        .map { [weak self] data in
            if let selectedChannel = self?.selectedChannel, data.channels.contains(selectedChannel) {
                return Bouquet(firstPartyChannels: data.firstPartyChannels, thirdPartyChannels: data.thirdPartyChannels, selectedChannel: selectedChannel)
            }
            else {
                return Bouquet(firstPartyChannels: data.firstPartyChannels, thirdPartyChannels: data.thirdPartyChannels, selectedChannel: data.channels.first)
            }
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$bouquet)
    }
    
    private func switchToDate(_ date: Date) {
        day = SRGDay(from: date)
        time = Self.time(from: date, relativeTo: day)
        scrollTime = time
    }
    
    func switchToDay(_ day: SRGDay) {
        self.day = day
        time = scrollTime
    }
    
    func switchToPreviousDay() {
        switchToDay(SRGDay(byAddingDays: -1, months: 0, years: 0, to: day))
    }
    
    func switchToNextDay() {
        switchToDay(SRGDay(byAddingDays: 1, months: 0, years: 0, to: day))
    }
    
    func switchToTonight() {
        let date = Calendar.current.date(bySettingHour: 20, minute: 30, second: 0, of: Date())!
        switchToDate(date)
    }
    
    func switchToNow() {
        switchToDate(Date())
    }
    
    func didScrollToTime(of date: Date) {
        scrollTime = Self.time(from: date, relativeTo: day)
    }
}

// MARK: Types

extension ProgramGuideViewModel {
    struct Bouquet {
        let firstPartyChannels: [SRGChannel]
        let thirdPartyChannels: [SRGChannel]
        let selectedChannel: SRGChannel?
        
        static var empty: Self {
            return Self.init(firstPartyChannels: [], thirdPartyChannels: [], selectedChannel: nil)
        }
        
        var channels: [SRGChannel] {
            return firstPartyChannels + thirdPartyChannels
        }
    }
}

// MARK: Publishers

private extension ProgramGuideViewModel {
    static func bouquet(for day: SRGDay) -> AnyPublisher<Bouquet, Error> {
        let applicationConfiguration = ApplicationConfiguration.shared
        let vendor = applicationConfiguration.vendor
        
        if applicationConfiguration.areTvThirdPartyChannelsAvailable {
            return Publishers.CombineLatest(
                SRGDataProvider.current!.tvPrograms(for: vendor, day: day, minimal: true),
                SRGDataProvider.current!.tvPrograms(for: vendor, provider: .thirdParty, day: day, minimal: true)
            )
            .map { Bouquet(firstPartyChannels: $0.map(\.channel), thirdPartyChannels: $1.map(\.channel), selectedChannel: nil) }
            .eraseToAnyPublisher()
        }
        else {
            return SRGDataProvider.current!.tvPrograms(for: vendor, day: day, minimal: true)
                .map { Bouquet(firstPartyChannels: $0.map(\.channel), thirdPartyChannels: [], selectedChannel: nil) }
                .eraseToAnyPublisher()
        }
    }
}
