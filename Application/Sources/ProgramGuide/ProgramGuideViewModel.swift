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
    @Published private(set) var data: Data = .empty
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
        return data.channels
    }
    
    var firstPartyChannels: [SRGChannel] {
        return data.firstPartyChannels
    }
    
    var thirdPartyChannels: [SRGChannel] {
        return data.thirdPartyChannels
    }
    
    var selectedChannel: SRGChannel? {
        get {
            return data.selectedChannel
        }
        set {
            if let newValue = newValue, channels.contains(newValue) {
                data = Data(firstPartyChannels: firstPartyChannels, thirdPartyChannels: thirdPartyChannels, selectedChannel: newValue)
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
            return Self.data(for: initialDay, from: self?.data ?? .empty)
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$data)
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
    
    func didScrollToTime(_ time: TimeInterval) {
        scrollTime = time
    }
}

// MARK: Types

extension ProgramGuideViewModel {
    struct Data {
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
    static func matchingChannel(_ channel: SRGChannel?, in channels: [SRGChannel]) -> SRGChannel? {
        if let channel = channel, channels.contains(channel) {
            return channel
        }
        else {
            return channels.first
        }
    }
    
    // TODO: Once an IL request is available to get the channel list without any day, use this request and
    //       remove the day parameter.
    static func channels(for vendor: SRGVendor, provider: SRGProgramProvider, day: SRGDay) -> AnyPublisher<[SRGChannel], Error> {
        return SRGDataProvider.current!.tvPrograms(for: vendor, provider: provider, day: day, minimal: true)
            .map { $0.map(\.channel) }
            .eraseToAnyPublisher()
    }
    
    static func data(for day: SRGDay, from data: Data) -> AnyPublisher<Data, Never> {
        let applicationConfiguration = ApplicationConfiguration.shared
        let vendor = applicationConfiguration.vendor
        
        if applicationConfiguration.areTvThirdPartyChannelsAvailable {
            return Publishers.CombineLatest(
                channels(for: vendor, provider: .SRG, day: day),
                channels(for: vendor, provider: .thirdParty, day: day)
            )
            .map { Data(firstPartyChannels: $0, thirdPartyChannels: $1, selectedChannel: matchingChannel(data.selectedChannel, in: $0 + $1)) }
            .replaceError(with: data)
            .eraseToAnyPublisher()
        }
        else {
            return channels(for: vendor, provider: .SRG, day: day)
                .map { Data(firstPartyChannels: $0, thirdPartyChannels: [], selectedChannel: matchingChannel(data.selectedChannel, in: $0)) }
                .replaceError(with: data)
                .eraseToAnyPublisher()
        }
    }
}
