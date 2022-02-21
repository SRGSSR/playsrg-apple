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
    init(day: SRGDay, firstPartyChannels: [SRGChannel], thirdPartyChannels: [SRGChannel]) {
        self.day = day
        self.state = .loading(firstPartyChannels: firstPartyChannels, thirdPartyChannels: thirdPartyChannels, in: day)
        
        Publishers.PublishAndRepeat(onOutputFrom: ApplicationSignal.wokenUp()) { [weak self, $day] in
            $day
                .map { day -> AnyPublisher<State, Error> in
                    let applicationConfiguration = ApplicationConfiguration.shared
                    let vendor = applicationConfiguration.vendor
                    
                    if applicationConfiguration.areTvThirdPartyChannelsAvailable {
                        return Publishers.CombineLatest(
                            Self.rows(for: vendor, provider: .SRG, day: day, from: self?.state.firstPartyRows ?? []),
                            Self.rows(for: vendor, provider: .thirdParty, day: day, from: self?.state.thirdPartyRows ?? [])
                        )
                        .map { .content(firstPartyBouquet: $0, thirdPartyBouquet: $1) }
                        .eraseToAnyPublisher()
                    }
                    else {
                        return Self.rows(for: vendor, provider: .SRG, day: day, from: self?.state.firstPartyRows ?? [])
                            .map { .content(firstPartyBouquet: $0, thirdPartyBouquet: .empty) }
                            .eraseToAnyPublisher()
                    }
                }
                .switchToLatest()
                .catch { error in
                    return Just(.failed(error: error))
                }
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$state)
    }
}

// MARK: Types

extension ProgramGuideDailyViewModel {
    typealias Section = SRGChannel
    
    struct Item: Hashable {
        enum WrappedValue: Hashable {
            case program(_ program: SRGProgram)
            case empty
            case loading
        }
        
        let wrappedValue: WrappedValue
        let section: Section
        let day: SRGDay
        
        init(_ wrappedValue: WrappedValue, in section: Section, day: SRGDay) {
            self.wrappedValue = wrappedValue
            self.section = section
            self.day = day
        }
        
        var program: SRGProgram? {
            if case let .program(program) = wrappedValue {
                return program
            }
            else {
                return nil
            }
        }
        
        func endsAfter(_ date: Date) -> Bool {
            if let program = program {
                return program.endDate > date
            }
            else {
                return false
            }
        }
    }
    
    struct Row {
        let section: Section
        let items: [Item]
        
        private init(section: Section, items: [Item]) {
            // Empty rows must still contain an .empty item
            // FIXME: Can we write preconditions for empty / loading row = row with single empty / loading item
            precondition(!items.isEmpty)
            self.section = section
            self.items = items
        }
        
        fileprivate static func loading(channel: SRGChannel, in day: SRGDay) -> Row {
            return Self.init(section: channel, items: [Item(.loading, in: channel, day: day)])
        }
        
        fileprivate static func loading(from row: Row, in day: SRGDay) -> Row {
            return created(from: row, in: day, isLoading: true)
        }
        
        fileprivate static func loaded(from row: Row, in day: SRGDay) -> Row {
            return created(from: row, in: day, isLoading: false)
        }
        
        fileprivate static func loaded(from programComposition: SRGProgramComposition, in day: SRGDay) -> Row {
            let channel = programComposition.channel
            if let programs = programComposition.programs, !programs.isEmpty {
                return Self.init(section: channel, items: programs.map { Item(.program($0), in: channel, day: day) })
            }
            else {
                return Self.init(section: channel, items: [Item(.empty, in: channel, day: day)])
            }
        }
        
        private static func created(from row: Row, in day: SRGDay, isLoading: Bool) -> Row {
            let items = row.items.filter { $0.day == day }
            if !items.isEmpty {
                return Self.init(section: row.section, items: items)
            }
            else {
                return Self.init(section: row.section, items: [Item(isLoading ? .loading : .empty, in: row.section, day: day)])
            }
        }
        
        var isLoading: Bool {
            return items.allSatisfy { $0.wrappedValue == .loading }
        }
        
        var isEmpty: Bool {
            return items.allSatisfy { $0.wrappedValue == .empty }
        }
    }
    
    enum State {
        struct Bouquet {
            let rows: [Row]
            fileprivate let isLoadingWithoutRows: Bool
            
            fileprivate static var empty: Self {
                return Self.loaded(rows: [])
            }
            
            fileprivate static func loading(rows: [Row], in day: SRGDay) -> Self {
                return Self.init(rows: rows.map { Row.loading(from: $0, in: day) }, isLoading: true)
            }
            
            fileprivate static func loading(channels: [SRGChannel], in day: SRGDay) -> Self {
                return Self.init(rows: channels.map { Row.loading(channel: $0, in: day) }, isLoading: true)
            }
            
            fileprivate static func loaded(rows: [Row]) -> Self {
                return Self.init(rows: rows, isLoading: false)
            }
            
            private init(rows: [Row], isLoading: Bool) {
                self.rows = rows
                isLoadingWithoutRows = isLoading && rows.isEmpty
            }
            
            var isEmpty: Bool {
                return rows.allSatisfy { $0.isEmpty }
            }
            
            var isLoading: Bool {
                return rows.isEmpty ? isLoadingWithoutRows : rows.allSatisfy { $0.isLoading }
            }
        }
        
        case content(firstPartyBouquet: Bouquet, thirdPartyBouquet: Bouquet)
        case failed(error: Error)
        
        static func loading(firstPartyChannels: [SRGChannel], thirdPartyChannels: [SRGChannel], in day: SRGDay) -> State {
            return .content(firstPartyBouquet: .loading(channels: firstPartyChannels, in: day), thirdPartyBouquet: .loading(channels: thirdPartyChannels, in: day))
        }
        
        static var empty: State {
            return .content(firstPartyBouquet: .empty, thirdPartyBouquet: .empty)
        }
        
        private var rows: [Row] {
            switch self {
            case let .content(firstPartyBouquet: firstPartyBouquet, thirdPartyBouquet: thirdPartyBouquet):
                return firstPartyBouquet.rows + thirdPartyBouquet.rows
            case .failed:
                return []
            }
        }
        
        fileprivate var firstPartyRows: [Row] {
            switch self {
            case let .content(firstPartyBouquet: firstPartyBouquet, thirdPartyBouquet: _):
                return firstPartyBouquet.rows
            case .failed:
                return []
            }
        }
        
        fileprivate var thirdPartyRows: [Row] {
            switch self {
            case let .content(firstPartyBouquet: _, thirdPartyBouquet: thirdPartyBouquet):
                return thirdPartyBouquet.rows
            case .failed:
                return []
            }
        }
        
        private func row(for section: Section) -> Row? {
            return rows.first(where: { $0.section == section })
        }
        
        var sections: [Section] {
            switch self {
            case .content:
                return rows.map(\.section)
            case .failed:
                return []
            }
        }
        
        func isLoading(in section: Section?) -> Bool {
            switch self {
            case let .content(firstPartyBouquet: firstPartyBouquet, thirdPartyBouquet: thirdPartyBouquet):
                if let section = section, let row = row(for: section) {
                    return row.isLoading
                }
                else {
                    return isEmpty && firstPartyBouquet.isLoading && thirdPartyBouquet.isLoading
                }
            case .failed:
                return false
            }
        }
        
        var isLoading: Bool {
            return isLoading(in: nil)
        }
        
        func isEmpty(in section: Section?) -> Bool {
            switch self {
            case let .content(firstPartyBouquet: firstPartyBouquet, thirdPartyBouquet: thirdPartyBouquet):
                if let section = section, let row = row(for: section) {
                    return row.isEmpty
                }
                else {
                    return firstPartyBouquet.isEmpty && thirdPartyBouquet.isEmpty
                }
            case .failed:
                return false
            }
        }
        
        var isEmpty: Bool {
            return isEmpty(in: nil)
        }
        
        func items(for section: Section) -> [Item] {
            if let row = row(for: section) {
                return Self.items(from: row)
            }
            else {
                return []
            }
        }
        
        private static func items(from row: Row) -> [Item] {
            return removeDuplicates(in: row.items.flatMap { item -> [Item] in
                if let subprograms = item.program?.subprograms {
                    return subprograms.map { Item(.program($0), in: item.section, day: item.day) }
                }
                else {
                    return [item]
                }
            })
        }
    }
}

// MARK: Publishers

private extension ProgramGuideDailyViewModel {
    static func rows(for vendor: SRGVendor, provider: SRGProgramProvider, day: SRGDay, from rows: [Row]) -> AnyPublisher<State.Bouquet, Error> {
        return SRGDataProvider.current!.tvPrograms(for: vendor, provider: provider, day: day, minimal: true)
            .append(SRGDataProvider.current!.tvPrograms(for: vendor, provider: provider, day: day))
            .map { programCompositions in
                let rows = programCompositions.map { Row.loaded(from: $0, in: day) }
                return .loaded(rows: rows)
            }
            .tryCatch { error -> AnyPublisher<State.Bouquet, Never> in
                let availableRows = rows.map { Row.loaded(from: $0, in: day) }
                guard !availableRows.allSatisfy({ $0.isEmpty }) else { throw error }
                return Just(.loaded(rows: availableRows))
                    .eraseToAnyPublisher()
            }
            .prepend(.loading(rows: rows, in: day))
            .eraseToAnyPublisher()
    }
}
