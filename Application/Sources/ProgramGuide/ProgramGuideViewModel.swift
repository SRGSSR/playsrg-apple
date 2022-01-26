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
    @Published private(set) var relativeDate: RelativeDate
    
    private var scrollPositionRelativeDate: RelativeDate
    
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
        return DateFormatter.play_relativeFull.string(from: relativeDate.day.date).capitalizedFirstLetter
    }
    
    init(date: Date) {
        relativeDate = RelativeDate.atDate(date)
        scrollPositionRelativeDate = RelativeDate.atDate(date)
        
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
        relativeDate = relativeDate.previousDay.atTime(scrollPositionRelativeDate.time)
    }
    
    func switchToNextDay() {
        relativeDate = relativeDate.nextDay.atTime(scrollPositionRelativeDate.time)
    }
    
    func switchToTonight() {
        relativeDate = RelativeDate.tonight
    }
    
    func switchToNow() {
        relativeDate = RelativeDate.now
    }
    
    func switchToDay(_ day: SRGDay) {
        relativeDate = relativeDate.atDay(day).atTime(scrollPositionRelativeDate.time)
    }
    
    func didScrollToTime(of date: Date) {
        scrollPositionRelativeDate = relativeDate.atTime(of: date)
    }
}

// MARK: Types

extension ProgramGuideViewModel {
    struct Data {
        let channels: [SRGChannel]
        let selectedChannel: SRGChannel?
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
