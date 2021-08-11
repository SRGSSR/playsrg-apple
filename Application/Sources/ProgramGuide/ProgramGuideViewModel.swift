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
    @Published private(set) var dateSelection: DateSelection
    @Published var isDatePickerPresented: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private var placeholderItems: [Item] {
        return (0..<2).map { Item.channelPlaceholder(index: $0) }
    }
    
    var dateString: String {
        return DateFormatter.play_relative.string(from: dateSelection.day.date).capitalizedFirstLetter
    }
    
    init(date: Date) {
        self.dateSelection = DateSelection.atDate(date)
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

extension ProgramGuideViewModel {
    struct DateSelection: Hashable {
        let day: SRGDay
        let time: TimeInterval
        
        var date: Date {
            return day.date.addingTimeInterval(time)
        }
        
        fileprivate func previousDay() -> DateSelection {
            let previousDay = SRGDay(byAddingDays: -1, months: 0, years: 0, to: day)
            return DateSelection(day: previousDay, time: time)
        }
        
        fileprivate func nextDay() -> DateSelection {
            let nextDay = SRGDay(byAddingDays: 1, months: 0, years: 0, to: day)
            return DateSelection(day: nextDay, time: time)
        }
        
        fileprivate func yesterday() -> DateSelection {
            let yesterday = SRGDay(byAddingDays: -1, months: 0, years: 0, to: SRGDay.today)
            return DateSelection(day: yesterday, time: time)
        }
        
        fileprivate func atDay(_ day: SRGDay) -> DateSelection {
            return DateSelection(day: day, time: time)
        }
        
        fileprivate func atTime(of date: Date) -> DateSelection {
            return DateSelection(day: day, time: date.timeIntervalSince(day.date))
        }
        
        static func now() -> DateSelection {
            return DateSelection.atDate(Date())
        }
        
        fileprivate static func atDate(_ date: Date) -> DateSelection {
            let day = SRGDay(from: date)
            return DateSelection(day: day, time: date.timeIntervalSince(day.date))
        }
    }
}
