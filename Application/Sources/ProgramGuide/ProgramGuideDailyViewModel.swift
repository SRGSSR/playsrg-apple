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
    @Published private(set) var state: State = .loaded(srgState: .loading(rows: []), thirdPartyState: .loading(rows: []))
    
    init(day: SRGDay) {
        self.day = day
        
        Publishers.PublishAndRepeat(onOutputFrom: ApplicationSignal.wokenUp()) { [weak self, $day] in
            $day
                .map { day in
                    return SRGDataProvider.current!.state(for: day, from: self?.state ?? State.empty)
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
        
        init(section: Section, in day: SRGDay) {
            self.init(section: section, items: [Item(.empty, in: section, day: day)])
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
        enum RowState {
            case loading(rows: [Row])
            case loaded(rows: [Row])
            
            fileprivate var rows: [Row] {
                switch self {
                case let .loading(rows: rows):
                    return rows
                case let .loaded(rows: rows):
                    return rows
                }
            }
        }
        
        case loaded(srgState: RowState, thirdPartyState: RowState)
        case failed(error: Error)
        
        static var empty: State {
            return .loaded(srgState: .loaded(rows: []), thirdPartyState: .loaded(rows: []))
        }
        
        private var rows: [Row] {
            if case let .loaded(srgState: srgState, thirdPartyState: thirdPartyState) = self {
                return srgState.rows + thirdPartyState.rows
            }
            else {
                return []
            }
        }
        
        fileprivate var srgRows: [Row] {
            if case let .loaded(srgState: srgState, thirdPartyState: _) = self {
                return srgState.rows
            }
            else {
                return []
            }
        }
        
        fileprivate var thirdPartyRows: [Row] {
            if case let .loaded(srgState: _, thirdPartyState: thirdPartyState) = self {
                return thirdPartyState.rows
            }
            else {
                return []
            }
        }
        
        var sections: [Section] {
            return rows.map(\.section)
        }
        
        var isLoading: Bool {
            if case let .loaded(srgState: srgState, thirdPartyState: thirdPartyState) = self {
                if case .loading = srgState, case .loading = thirdPartyState {
                    return true
                }
                else {
                    return false
                }
            }
            else {
                return false
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

// TODO: Can probably improve, e.g. by defining these methods on ProgramGuideDailyViewModel to avoid explicit types
//       (or using typealiases).
private extension SRGDataProvider {
    // TODO: Can probably improve to extract existing programs as well if the day stayed the same, so that shallow
    //       reloads preserve existing data
    private static func placeholderRows(from rows: [ProgramGuideDailyViewModel.Row], in day: SRGDay) -> [ProgramGuideDailyViewModel.Row] {
        return rows.map { ProgramGuideDailyViewModel.Row(section: $0.section, in: day) }
    }
    
    private func rows(for vendor: SRGVendor, provider: SRGProgramProvider, day: SRGDay, from rows: [ProgramGuideDailyViewModel.Row]) -> AnyPublisher<ProgramGuideDailyViewModel.State.RowState, Error> {
        return tvPrograms(for: vendor, provider: provider, day: day, minimal: true)
            .append(tvPrograms(for: vendor, provider: provider, day: day))
            .map { programCompositions in
                let rows = programCompositions.map { ProgramGuideDailyViewModel.Row(from: $0, in: day) }
                return ProgramGuideDailyViewModel.State.RowState.loaded(rows: rows)
            }
            .prepend(ProgramGuideDailyViewModel.State.RowState.loading(rows: Self.placeholderRows(from: rows, in: day)))
            .eraseToAnyPublisher()
    }
    
    func state(for day: SRGDay, from state: ProgramGuideDailyViewModel.State) -> AnyPublisher<ProgramGuideDailyViewModel.State, Never> {
        let applicationConfiguration = ApplicationConfiguration.shared
        let vendor = applicationConfiguration.vendor
        
        if applicationConfiguration.areTvThirdPartyChannelsAvailable {
            return Publishers.CombineLatest(
                self.rows(for: vendor, provider: .SRG, day: day, from: state.srgRows),
                self.rows(for: vendor, provider: .thirdParty, day: day, from: state.thirdPartyRows)
            )
            .map { ProgramGuideDailyViewModel.State.loaded(srgState: $0, thirdPartyState: $1) }
            .catch { error in
                return Just(ProgramGuideDailyViewModel.State.failed(error: error))
            }
            .eraseToAnyPublisher()
        }
        else {
            return rows(for: vendor, provider: .SRG, day: day, from: state.srgRows)
                .map { ProgramGuideDailyViewModel.State.loaded(srgState: $0, thirdPartyState: .loaded(rows: [])) }
                .catch { error in
                    return Just(ProgramGuideDailyViewModel.State.failed(error: error))
                }
                .eraseToAnyPublisher()
        }
    }
}
