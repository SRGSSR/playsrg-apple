//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGDataProviderCombine

// MARK: View model

final class ProgramGuideViewModel: ObservableObject {
    @Published private(set) var bouquet = Bouquet(firstPartyChannels: [], thirdPartyChannels: [], selectedChannel: nil)
    @Published private(set) var relativeDate: RelativeDate
    
    private var scrollPositionRelativeDate: RelativeDate
    
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
    
    var dateString: String {
        return DateFormatter.play_relativeFull.string(from: relativeDate.day.date).capitalizedFirstLetter
    }
    
    init(date: Date) {
        relativeDate = RelativeDate.atDate(date)
        scrollPositionRelativeDate = RelativeDate.atDate(date)
        
        Publishers.PublishAndRepeat(onOutputFrom: ApplicationSignal.wokenUp()) { [weak self] in
            return Self.bouquet(for: SRGDay(from: date))
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
    struct Bouquet {
        let firstPartyChannels: [SRGChannel]
        let thirdPartyChannels: [SRGChannel]
        let selectedChannel: SRGChannel?
        
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
