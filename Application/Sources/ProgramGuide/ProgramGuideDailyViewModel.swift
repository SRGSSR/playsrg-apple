//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine

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
        Publishers.PublishAndRepeat(onOutputFrom: ApplicationSignal.wokenUp()) { [weak self] in
            return SRGDataProvider.current!.tvPrograms(for: ApplicationConfiguration.shared.vendor, day: self?.day ?? .today)
                .map { programCompositions in
                    return State.loaded(programCompositions)
                }
                .prepend(State.loading)
                .catch { error in
                    return Just(State.failed(error: error))
                }
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$state)
    }
}

// MARK: Types

extension ProgramGuideDailyViewModel {
    enum Section {
        case main
    }
    
    enum State {
        case loading
        case failed(error: Error)
        case loaded([SRGProgramComposition])
        
        var hasContent: Bool {
            switch self {
            case let .loaded(programCompositions):
                return !programCompositions.flatMap({ $0.programs ?? [] }).isEmpty
            default:
                return false
            }
        }
        
        var channels: [SRGChannel] {
            if case let .loaded(programCompositions) = self {
                return programCompositions.map { $0.channel }
            }
            else {
                return []
            }
        }
        
        func programs(for channel: SRGChannel?) -> [SRGProgram] {
            if case let .loaded(programCompositions) = self {
                if let channel = channel {
                    return Self.programs(from: programCompositions.first(where: { $0.channel == channel }))
                }
                else {
                    return Self.programs(from: programCompositions.first)
                }
            }
            else {
                return []
            }
        }
        
        private static func programs(from programComposition: SRGProgramComposition?) -> [SRGProgram] {
            guard let programs = programComposition?.programs else { return [] }
            return programs.flatMap { program in
                return program.subprograms ?? [program]
            }
        }
    }
}
