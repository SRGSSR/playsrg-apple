//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine

// MARK: View model

final class ProgramGuideViewModel: ObservableObject {
    @Published private(set) var items: [Item] = []
    @Published var selectedChannel: SRGChannel?
    @Published var selectedDay: (day: SRGDay, atCurrentTime: Bool)
    
    private var cancellables = Set<AnyCancellable>()
    
    private var placeholderItems: [Item] {
        return (0..<2).map { Item.channelPlaceholder(index: $0) }
    }
    
    init(day: SRGDay, atCurrentTime: Bool) {
        self.selectedDay = (day, atCurrentTime)
        self.items = placeholderItems
        
        Publishers.PublishAndRepeat(onOutputFrom: ApplicationSignal.wokenUp()) { [weak self] in
            return SRGDataProvider.current!.tvPrograms(for: ApplicationConfiguration.shared.vendor, day: day)
                .map { $0.map(\.channel) }
                .catch { _ in
                    return Just((self != nil) ? Item.channels(from: self!.items) : [])
                }
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] channels in
            guard let self = self else { return }
            if !channels.isEmpty {
                self.items = channels.map { Item.channel($0) }
                if self.selectedChannel == nil {
                    self.selectedChannel = channels.first
                }
            }
            else {
                self.items = self.placeholderItems
            }
        }
        .store(in: &cancellables)
    }
    
    func previousDay() {
        selectedDay = (SRGDay(byAddingDays: -1, months: 0, years: 0, to: selectedDay.day), false)
    }
    
    func nextDay() {
        selectedDay = (SRGDay(byAddingDays: 1, months: 0, years: 0, to: selectedDay.day), false)
    }
    
    func yesterday() {
        selectedDay = (SRGDay(byAddingDays: -1, months: 0, years: 0, to: SRGDay.today), false)
    }
    
    func todayAtCurrentTime() {
        selectedDay = (SRGDay.today, true)
    }
    
    enum Item: Hashable {
        case channelPlaceholder(index: Int)
        case channel(_ channel: SRGChannel)
        
        var channel: SRGChannel? {
            if case let .channel(channel) = self {
                return channel
            }
            else {
                return nil
            }
        }
        
        static func channels(from items: [Item]) -> [SRGChannel] {
            return items.compactMap { item in
                if case let .channel(channel) = item {
                    return channel
                }
                else {
                    return nil
                }
            }
        }
    }
}
