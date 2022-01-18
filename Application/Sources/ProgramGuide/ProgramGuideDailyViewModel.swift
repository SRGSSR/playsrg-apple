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
        Publishers.PublishAndRepeat(onOutputFrom: ApplicationSignal.wokenUp()) { [weak self] in
            return SRGDataProvider.current!.tvPrograms(for: self?.day ?? .today)
                .map { programCompositions in
                    return State.loaded(programCompositions: programCompositions)
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
        case loaded(programCompositions: [SRGProgramComposition])
        
        var hasContent: Bool {
            switch self {
            case let .loaded(programCompositions):
                return !programCompositions.flatMap({ $0.programs ?? [] }).isEmpty
            default:
                return false
            }
        }
        
        var channels: [SRGChannel] {
            if case let .loaded(programCompositions: programCompositions) = self {
                return programCompositions.map(\.channel)
            }
            else {
                return []
            }
        }
        
        func programs(for channel: SRGChannel?) -> [SRGProgram] {
            if case let .loaded(programCompositions: programCompositions) = self {
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

// MARK: Publishers

private extension SRGDataProvider {
    func tvPrograms(for day: SRGDay) -> AnyPublisher<[SRGProgramComposition], Error> {
        let applicationConfiguration = ApplicationConfiguration.shared
        let vendor = applicationConfiguration.vendor
        
        if applicationConfiguration.areTvThirdPartyChannelsAvailable {
            return Publishers.CombineLatest(
                tvPrograms(for: vendor, day: day, minimal: true)
                    .append(tvPrograms(for: vendor, day: day))
                    .prepend([]),
                tvPrograms(for: vendor, provider: .thirdParty, day: day, minimal: true)
                    .append(tvPrograms(for: vendor, provider: .thirdParty, day: day))
                    .prepend([])
            )
            .map { $0 + $1 }
            .eraseToAnyPublisher()
        }
        else {
            return tvPrograms(for: vendor, day: day, minimal: true)
                .append(tvPrograms(for: vendor, day: day))
                .prepend([])
                .eraseToAnyPublisher()
        }
    }
}
