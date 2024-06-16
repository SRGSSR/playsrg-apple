//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import Foundation
import SRGDataProviderCombine

// MARK: View model

final class ProgramGuideViewModel: ObservableObject {
    @Published private(set) var data: Data = .empty

    /// Only significant changes are published. Noisy changes (e.g. because of scrolling) are not published.
    @Published private(set) var change: Change = .none

    #if os(iOS)
        @Published var isHeaderUserInteractionEnabled = true
    #else
        @Published var focusedProgramAndChannel: ProgramAndChannel?
    #endif

    private(set) var day: SRGDay
    private(set) var time: TimeInterval // Position in day (distance from midnight)

    static func time(from date: Date, relativeTo day: SRGDay) -> TimeInterval {
        date.timeIntervalSince(day.date)
    }

    var channels: [PlayChannel] {
        data.channels
    }

    var mainPartyChannels: [PlayChannel] {
        data.mainPartyChannels
    }

    var otherPartyChannels: [PlayChannel] {
        data.otherPartyChannels
    }

    var selectedChannel: PlayChannel? {
        get {
            data.selectedChannel
        }
        set {
            if let newValue, channels.contains(newValue), newValue != data.selectedChannel {
                data = Data(mainPartyChannels: mainPartyChannels, otherPartyChannels: otherPartyChannels, selectedChannel: newValue)
                change = .channel(newValue)
            }
        }
    }

    func date(for time: TimeInterval) -> Date {
        day.date.addingTimeInterval(time)
    }

    var dateString: String {
        DateFormatter.play_relativeFullDate.string(from: day.date).capitalizedFirstLetter
    }

    init(date: Date) {
        let initialDay = SRGDay(from: date)
        day = initialDay
        time = Self.time(from: date, relativeTo: initialDay)

        Publishers.PublishAndRepeat(onOutputFrom: ApplicationSignal.wokenUp()) { [weak self] in
            Self.data(for: initialDay, from: self?.data ?? .empty)
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$data)
    }

    private func switchToDay(_ day: SRGDay, atTime time: TimeInterval?) {
        let previousDay = self.day
        let previousTime = self.time

        self.day = day
        self.time = time ?? self.time

        if self.day != previousDay, self.time != previousTime {
            change = .dayAndTime(day: self.day, time: self.time)
        } else if self.day != previousDay {
            change = .day(self.day)
        } else if self.time != previousTime {
            change = .time(self.time)
        }
    }

    private func switchToDate(_ date: Date) {
        let day = SRGDay(from: date)
        switchToDay(day, atTime: Self.time(from: date, relativeTo: day))
    }

    func switchToDay(_ day: SRGDay) {
        switchToDay(day, atTime: nil)
    }

    func switchToPreviousDay() {
        switchToDay(SRGDay(byAddingDays: -1, months: 0, years: 0, to: day))
    }

    func switchToNextDay() {
        switchToDay(SRGDay(byAddingDays: 1, months: 0, years: 0, to: day))
    }

    func switchToTonight() {
        let date = Calendar.srgDefault.date(bySettingHour: 20, minute: 30, second: 0, of: Date())!
        switchToDate(date)
    }

    func switchToNow() {
        switchToDate(Date())
    }

    func didScrollToTime(_ time: TimeInterval) {
        self.time = time
    }
}

// MARK: Types

extension ProgramGuideViewModel {
    struct Data {
        let mainPartyChannels: [PlayChannel]
        let otherPartyChannels: [PlayChannel]
        let selectedChannel: PlayChannel?

        static var empty: Self {
            Self(mainPartyChannels: [], otherPartyChannels: [], selectedChannel: nil)
        }

        var channels: [PlayChannel] {
            mainPartyChannels + otherPartyChannels
        }
    }

    enum Change {
        case none
        case day(SRGDay)
        case time(TimeInterval)
        case dayAndTime(day: SRGDay, time: TimeInterval)
        case channel(PlayChannel)
    }
}

// MARK: Publishers

private extension ProgramGuideViewModel {
    static func matchingChannel(_ channel: PlayChannel?, in channels: [PlayChannel]) -> PlayChannel? {
        if let channel, channels.contains(channel) {
            channel
        } else {
            channels.first
        }
    }

    // TODO: Once an IL request is available to get the channel list without any day, use this request and
    //       remove the day parameter.
    static func channels(for _: SRGVendor, mainProvider: Bool, day: SRGDay) -> AnyPublisher<[PlayChannel], Error> {
        SRGDataProvider.current!.tvProgramsPublisher(day: day, mainProvider: mainProvider, minimal: true)
            .map { $0.map(\.channel) }
            .eraseToAnyPublisher()
    }

    static func data(for day: SRGDay, from data: Data) -> AnyPublisher<Data, Never> {
        let applicationConfiguration = ApplicationConfiguration.shared
        let vendor = applicationConfiguration.vendor

        if !applicationConfiguration.tvGuideOtherBouquets.isEmpty {
            return Publishers.CombineLatest(
                channels(for: vendor, mainProvider: true, day: day),
                channels(for: vendor, mainProvider: false, day: day)
            )
            .map { Data(mainPartyChannels: $0, otherPartyChannels: $1, selectedChannel: matchingChannel(data.selectedChannel, in: $0 + $1)) }
            .replaceError(with: data)
            .eraseToAnyPublisher()
        } else {
            return channels(for: vendor, mainProvider: true, day: day)
                .map { Data(mainPartyChannels: $0, otherPartyChannels: [], selectedChannel: matchingChannel(data.selectedChannel, in: $0)) }
                .replaceError(with: data)
                .eraseToAnyPublisher()
        }
    }
}
