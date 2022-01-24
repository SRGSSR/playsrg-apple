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
    @Published private(set) var state: State = .loading
    
    init(day: SRGDay) {
        self.day = day
        
        Publishers.PublishAndRepeat(onOutputFrom: ApplicationSignal.wokenUp()) { [weak self, $day] in
            $day
                .map { day in
                    return Self.state(for: day, from: self?.state ?? State.empty)
                }
                .switchToLatest()
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
            self.section = section
            self.items = items
        }
        
        init(from row: Row, in day: SRGDay) {
            let items = row.items.filter { $0.day == day }
            if !items.isEmpty {
                self.init(section: row.section, items: items)
            }
            else {
                self.init(section: row.section, items: [Item(.empty, in: row.section, day: day)])
            }
        }
        
        init(from programComposition: SRGProgramComposition, in day: SRGDay) {
            let channel = programComposition.channel
            if let programs = programComposition.programs, !programs.isEmpty {
                self.init(section: channel, items: programs.map { Item(.program($0), in: channel, day: day) })
            }
            else {
                self.init(section: channel, items: [Item(.empty, in: channel, day: day)])
            }
        }
    }
    
    enum State {
        struct Group {
            let rows: [Row]
            let isLoading: Bool
            
            static var loading: Self {
                return Self.loading(rows: [])
            }
            
            static var empty: Self {
                return Self.loaded(rows: [])
            }
            
            static func loading(rows: [Row]) -> Self {
                return Self.init(rows: rows, isLoading: true)
            }
            
            static func loaded(rows: [Row]) -> Self {
                return Self.init(rows: rows, isLoading: false)
            }
            
            private init(rows: [Row], isLoading: Bool) {
                self.rows = rows
                self.isLoading = isLoading
            }
            
            var isEmpty: Bool {
                return rows.isEmpty
            }
        }
        
        case content(srgGroup: Group, thirdPartyGroup: Group)
        case failed(error: Error)
        
        static var loading: State {
            return .content(srgGroup: .loading, thirdPartyGroup: .loading)
        }
        
        static var empty: State {
            return .content(srgGroup: .empty, thirdPartyGroup: .empty)
        }
        
        private var rows: [Row] {
            if case let .content(srgGroup: srgGroup, thirdPartyGroup: thirdPartyGroup) = self {
                return srgGroup.rows + thirdPartyGroup.rows
            }
            else {
                return []
            }
        }
        
        fileprivate var srgRows: [Row] {
            if case let .content(srgGroup: srgGroup, thirdPartyGroup: _) = self {
                return srgGroup.rows
            }
            else {
                return []
            }
        }
        
        fileprivate var thirdPartyRows: [Row] {
            if case let .content(srgGroup: _, thirdPartyGroup: thirdPartyGroup) = self {
                return thirdPartyGroup.rows
            }
            else {
                return []
            }
        }
        
        var sections: [Section] {
            return rows.map(\.section)
        }
        
        var isLoading: Bool {
            if case let .content(srgGroup: srgGroup, thirdPartyGroup: thirdPartyGroup) = self {
                return srgGroup.isLoading || thirdPartyGroup.isLoading
            }
            else {
                return false
            }
        }
        
        var isEmpty: Bool {
            if case let .content(srgGroup: srgGroup, thirdPartyGroup: thirdPartyGroup) = self {
                return srgGroup.isEmpty && thirdPartyGroup.isEmpty
            }
            else {
                return true
            }
        }
        
        func items(for section: Section) -> [Item] {
            if let row = rows.first(where: { $0.section == section }) {
                return Self.items(from: row)
            }
            else {
                return []
            }
        }
        
        private static func items(from row: Row) -> [Item] {
            return row.items.flatMap { item -> [Item] in
                if let subprograms = item.program?.subprograms {
                    return subprograms.map { Item(.program($0), in: item.section, day: item.day) }
                }
                else {
                    return [item]
                }
            }
        }
    }
}

// MARK: Publishers

private extension ProgramGuideDailyViewModel {
    private static func rows(for vendor: SRGVendor, provider: SRGProgramProvider, day: SRGDay, from rows: [Row]) -> AnyPublisher<State.Group, Error> {
        return SRGDataProvider.current!.tvPrograms(for: vendor, provider: provider, day: day, minimal: true)
            .append(SRGDataProvider.current!.tvPrograms(for: vendor, provider: provider, day: day))
            .map { programCompositions in
                let rows = programCompositions.map { Row(from: $0, in: day) }
                return .loaded(rows: rows)
            }
            .prepend(.loading(rows: rows.map { Row(from: $0, in: day) }))
            .eraseToAnyPublisher()
    }
    
    static func state(for day: SRGDay, from state: State) -> AnyPublisher<State, Never> {
        let applicationConfiguration = ApplicationConfiguration.shared
        let vendor = applicationConfiguration.vendor
        
        if applicationConfiguration.areTvThirdPartyChannelsAvailable {
            return Publishers.CombineLatest(
                rows(for: vendor, provider: .SRG, day: day, from: state.srgRows),
                rows(for: vendor, provider: .thirdParty, day: day, from: state.thirdPartyRows)
            )
            .map { .content(srgGroup: $0, thirdPartyGroup: $1) }
            .catch { error in
                return Just(.failed(error: error))
            }
            .eraseToAnyPublisher()
        }
        else {
            return rows(for: vendor, provider: .SRG, day: day, from: state.srgRows)
                .map { .content(srgGroup: $0, thirdPartyGroup: .empty) }
                .catch { error in
                    return Just(.failed(error: error))
                }
                .eraseToAnyPublisher()
        }
    }
}
