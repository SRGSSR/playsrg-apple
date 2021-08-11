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
    @Published var selectedDate: Date
    @Published var isDatePickerPresented: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private var placeholderItems: [Item] {
        return (0..<2).map { Item.channelPlaceholder(index: $0) }
    }
    
    init(date: Date) {
        self.selectedDate = date
        self.items = placeholderItems
        
        Publishers.PublishAndRepeat(onOutputFrom: ApplicationSignal.wokenUp()) { [weak self] in
            return SRGDataProvider.current!.tvPrograms(for: ApplicationConfiguration.shared.vendor, day: SRGDay(from: date))
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
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }
    
    func nextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
    }
    
    func yesterday() {
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: selectedDate)
        let today = Calendar.current.date(bySettingHour: components.hour!, minute: components.minute!, second: components.second!, of: Date()) ?? Date()
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
    }
    
    func todayAtCurrentTime() {
        selectedDate = Date()
    }
    
    func atDay(_ day: SRGDay) {
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: selectedDate)
        selectedDate = Calendar.current.date(bySettingHour: components.hour!, minute: components.minute!, second: components.second!, of: day.date) ?? day.date
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
