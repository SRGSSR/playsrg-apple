//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGDataProviderCombine

// MARK: View model

final class ProgramGuideDailyViewModel: ObservableObject {
    var day: SRGDay {
        didSet {
            guard day != oldValue else { return }
            updatePublishers()
        }
    }
    
    @Published private(set) var state: State = .loading
    
    init(day: SRGDay) {
        self.day = day
        updatePublishers()
    }
    
    private func updatePublishers() {
        Publishers.PublishAndRepeat(onOutputFrom: ApplicationSignal.wokenUp()) { [weak self] () -> AnyPublisher<State, Never> in
            let existingData = self?.state.data ?? Data()
            return SRGDataProvider.current!.data(for: self?.day ?? .today, from: existingData)
                .map { data in
                    return State.loaded(data: data)
                }
                .catch { error in
                    return Just(State.failed(error: error))
                }
                .eraseToAnyPublisher()
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
    
    struct Data {
        let srgRows: [Row]
        let thirdPartyRows: [Row]
        
        fileprivate init(srgRows: [Row] = [], thirdPartyRows: [Row] = []) {
            self.srgRows = srgRows
            self.thirdPartyRows = thirdPartyRows
        }
        
        var rows: [Row] {
            return srgRows + thirdPartyRows
        }
    }
    
    enum State {
        case loading
        case failed(error: Error)
        case loaded(data: Data)
        
        fileprivate var data: Data? {
            if case let .loaded(data: data) = self {
                return data
            }
            else {
                return nil
            }
        }
        
        private var rows: [Row] {
            return data?.rows ?? []
        }
        
        var sections: [Section] {
            return rows.map(\.section)
        }
        
        func items(for section: Section) -> [Item] {
            if let row = rows.first(where: { $0.section == section }) {
                return Self.items(from: row)
            }
            else if let firstRow = rows.first {
                return Self.items(from: firstRow)
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

private extension SRGDataProvider {
    // TODO: Can probably improve to extract existing programs as well if the day stayed the same, so that shallow
    //       reloads preserve existing data
    private static func placeholderRows(from existingRows: [ProgramGuideDailyViewModel.Row], in day: SRGDay) -> [ProgramGuideDailyViewModel.Row] {
        return existingRows.map { ProgramGuideDailyViewModel.Row(section: $0.section, in: day) }
    }
    
    private func rows(for vendor: SRGVendor, provider: SRGProgramProvider, day: SRGDay, from existingRows: [ProgramGuideDailyViewModel.Row]) -> AnyPublisher<[ProgramGuideDailyViewModel.Row], Error> {
        return tvPrograms(for: vendor, provider: provider, day: day, minimal: true)
            .append(tvPrograms(for: vendor, provider: provider, day: day))
            .map { $0.map { ProgramGuideDailyViewModel.Row(from: $0, in: day) } }
            .prepend(Self.placeholderRows(from: existingRows, in: day))
            .eraseToAnyPublisher()
    }
    
    func data(for day: SRGDay, from existingData: ProgramGuideDailyViewModel.Data) -> AnyPublisher<ProgramGuideDailyViewModel.Data, Error> {
        let applicationConfiguration = ApplicationConfiguration.shared
        let vendor = applicationConfiguration.vendor
        
        if applicationConfiguration.areTvThirdPartyChannelsAvailable {
            return Publishers.CombineLatest(
                self.rows(for: vendor, provider: .SRG, day: day, from: existingData.srgRows),
                self.rows(for: vendor, provider: .thirdParty, day: day, from: existingData.thirdPartyRows)
            )
            .map { ProgramGuideDailyViewModel.Data(srgRows: $0, thirdPartyRows: $1) }
            .eraseToAnyPublisher()
        }
        else {
            return rows(for: vendor, provider: .SRG, day: day, from: existingData.srgRows)
                .map { ProgramGuideDailyViewModel.Data(srgRows: $0) }
                .eraseToAnyPublisher()
        }
    }
}
