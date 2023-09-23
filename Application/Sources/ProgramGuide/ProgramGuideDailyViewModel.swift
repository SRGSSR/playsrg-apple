//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGDataProviderCombine

// MARK: View model

final class ProgramGuideDailyViewModel: ObservableObject {
    @Published var day: SRGDay
    @Published private(set) var state: State
    
    /// Channels can be provided if available for more efficient content loading
    init(day: SRGDay, mainPartyChannels: [PlayChannel], otherPartyChannels: [PlayChannel]) {
        self.day = day
        self.state = .loading(mainPartyChannels: mainPartyChannels, otherPartyChannels: otherPartyChannels, day: day)
        
        Publishers.PublishAndRepeat(onOutputFrom: ApplicationSignal.wokenUp()) { [weak self, $day] in
            $day
                .map { day in
                    return Self.state(from: self?.state, for: day)
                        .catch { error in
                            return Just(.failed(error: error))
                        }
                }
                .switchToLatest()
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$state)
    }
}

// MARK: Types

extension ProgramGuideDailyViewModel {
    typealias Section = PlayChannel
    
    struct Item: Hashable {
        enum WrappedValue: Hashable {
            case program(_ program: SRGProgram)
            case empty
            case loading
        }
        
        let wrappedValue: WrappedValue
        let section: Section
        
        // Only attached to items so that `ProgramGuideGridLayout` can retrieve the current day from a snapshot
        let day: SRGDay
        
        fileprivate init(wrappedValue: WrappedValue, section: Section, day: SRGDay) {
            self.wrappedValue = wrappedValue
            self.section = section
            self.day = day
        }
        
        var program: SRGProgram? {
            switch wrappedValue {
            case let .program(program):
                return program
            default:
                return nil
            }
        }
        
        func endsAfter(_ date: Date) -> Bool {
            switch wrappedValue {
            case let .program(program):
                return program.endDate > date
            default:
                return false
            }
        }
    }
    
    enum Bouquet {
        case loading(channels: [PlayChannel])
        case content(programCompositions: [PlayProgramComposition])
        
        fileprivate static var empty: Self {
            return .content(programCompositions: [])
        }
        
        fileprivate var isLoading: Bool {
            switch self {
            case .loading:
                return true
            case .content:
                return false
            }
        }
        
        fileprivate var isEmpty: Bool {
            switch self {
            case .loading:
                return false
            case let .content(programCompositions: programCompositions):
                return programCompositions.allSatisfy { $0.programs?.isEmpty ?? true }
            }
        }
        
        fileprivate var hasPrograms: Bool {
            switch self {
            case .loading:
                return false
            case let .content(programCompositions: programCompositions):
                return programCompositions.contains { programComposition in
                    guard let programs = programComposition.programs else { return false }
                    return !programs.isEmpty
                }
            }
        }
        
        fileprivate var channels: [PlayChannel] {
            switch self {
            case let .loading(channels: channels):
                return channels
            case let .content(programCompositions: programCompositions):
                return programCompositions.map(\.channel)
            }
        }
        
        fileprivate func contains(channel: PlayChannel) -> Bool {
            return channels.contains(channel)
        }
        
        private static func programs(for channel: PlayChannel, in programCompositions: [PlayProgramComposition]) -> [SRGProgram] {
            return programCompositions.first(where: { $0.channel == channel })?.programs ?? []
        }
        
        fileprivate func isEmpty(for channel: PlayChannel) -> Bool {
            switch self {
            case .loading:
                return false
            case let .content(programCompositions: programCompositions):
                return Self.programs(for: channel, in: programCompositions).isEmpty
            }
        }
        
        fileprivate func items(for channel: PlayChannel, day: SRGDay) -> [Item] {
            switch self {
            case .loading:
                return [Item(wrappedValue: .loading, section: channel, day: day)]
            case let .content(programCompositions: programCompositions):
                let programs = Self.programs(for: channel, in: programCompositions)
                if !programs.isEmpty {
                    return programs.map { Item(wrappedValue: .program($0), section: channel, day: day) }
                }
                else {
                    return [Item(wrappedValue: .empty, section: channel, day: day)]
                }
            }
        }
    }
    
    enum State {
        case content(mainPartyBouquet: Bouquet, otherPartyBouquet: Bouquet, day: SRGDay)
        case failed(error: Error)
        
        fileprivate static func loading(mainPartyChannels: [PlayChannel], otherPartyChannels: [PlayChannel], day: SRGDay) -> Self {
            return .content(mainPartyBouquet: .loading(channels: mainPartyChannels), otherPartyBouquet: .loading(channels: otherPartyChannels), day: day)
        }
        
        private var day: SRGDay? {
            switch self {
            case let .content(mainPartyBouquet: _, otherPartyBouquet: _, day: day):
                return day
            case .failed:
                return nil
            }
        }
        
        private var bouquets: [Bouquet] {
            switch self {
            case let .content(mainPartyBouquet: mainPartyBouquet, otherPartyBouquet: otherPartyBouquet, day: _):
                return [mainPartyBouquet, otherPartyBouquet]
            case .failed:
                return []
            }
        }
        
        var sections: [Section] {
            return bouquets.flatMap(\.channels)
        }
        
        private func bouquet(for section: Section) -> Bouquet? {
            switch self {
            case let .content(mainPartyBouquet: mainPartyBouquet, otherPartyBouquet: otherPartyBouquet, day: _):
                if mainPartyBouquet.contains(channel: section) {
                    return mainPartyBouquet
                }
                else if otherPartyBouquet.contains(channel: section) {
                    return otherPartyBouquet
                }
                else {
                    return nil
                }
            case .failed:
                return nil
            }
        }
        
        func items(for section: Section) -> [Item] {
            guard let day, let bouquet = bouquet(for: section) else { return [] }
            return bouquet.items(for: section, day: day)
        }
        
        func isLoading(in section: Section?) -> Bool {
            if let section {
                guard let bouquet = bouquet(for: section) else { return false }
                return bouquet.isLoading
            }
            else {
                // Grid layout: Do not display any loading indicator when the channel list is known
                return sections.isEmpty
            }
        }
        
        var isLoading: Bool {
            return isLoading(in: nil)
        }
        
        func isEmpty(in section: Section?) -> Bool {
            if let section {
                guard let bouquet = bouquet(for: section) else { return false }
                return bouquet.isEmpty(for: section)
            }
            else {
                return bouquets.allSatisfy { $0.isEmpty }
            }
        }
        
        var isEmpty: Bool {
            return isEmpty(in: nil)
        }
    }
}

// MARK: Publishers

private extension ProgramGuideDailyViewModel {
    static func state(from state: State?, for day: SRGDay) -> AnyPublisher<State, Error> {
        let applicationConfiguration = ApplicationConfiguration.shared
        let vendor = applicationConfiguration.vendor
        if !applicationConfiguration.tvGuideOtherPartyBouquets.isEmpty {
            return Publishers.CombineLatest(
                Self.bouquet(for: vendor, mainProvider: true, day: day, from: state),
                Self.bouquet(for: vendor, mainProvider: false, day: day, from: state)
            )
            .map { .content(mainPartyBouquet: $0, otherPartyBouquet: $1, day: day) }
            .eraseToAnyPublisher()
        }
        else {
            return Self.bouquet(for: vendor, mainProvider: true, day: day, from: state)
                .map { .content(mainPartyBouquet: $0, otherPartyBouquet: .empty, day: day) }
                .eraseToAnyPublisher()
        }
    }
    
    static func bouquet(from state: State?, for mainProvider: Bool, day otherDay: SRGDay) -> Bouquet {
        guard let state else { return .empty }
        switch state {
        case let .content(mainPartyBouquet: mainPartyBouquet, otherPartyBouquet: otherPartyBouquet, day: day):
            guard otherDay.compare(day) == .orderedSame else {
                return mainProvider ? .loading(channels: mainPartyBouquet.channels) : .loading(channels: otherPartyBouquet.channels)
            }
            return mainProvider ? mainPartyBouquet : otherPartyBouquet
        case .failed:
            return .empty
        }
    }
    
    static func bouquet(for vendor: SRGVendor, mainProvider: Bool, day: SRGDay, from state: State?) -> AnyPublisher<Bouquet, Error> {
        let bouquet = bouquet(from: state, for: mainProvider, day: day)
        return SRGDataProvider.current!.tvProgramsPublisher(day: day, mainProvider: mainProvider, minimal: true)
            .append(SRGDataProvider.current!.tvProgramsPublisher(day: day, mainProvider: mainProvider))
            .map { .content(programCompositions: $0) }
            .tryCatch { error in
                guard bouquet.hasPrograms else { throw error }
                return Just(bouquet)
                    .eraseToAnyPublisher()
            }
            .prepend(bouquet)
            .eraseToAnyPublisher()
    }
}
