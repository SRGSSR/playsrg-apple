//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine

// MARK: View model

final class ProgramGuideDailyViewModel: ObservableObject {
    let day: SRGDay
    
    @Published private(set) var state: State = .loading
    
    init(day: SRGDay) {
        self.day = day
        
        Self.tvPrograms(for: day)
            .receive(on: DispatchQueue.main)
            .assign(to: &$state)
    }
    
    private static func tvPrograms(for day: SRGDay) -> AnyPublisher<State, Never> {
        return SRGDataProvider.current!.tvPrograms(for: ApplicationConfiguration.shared.vendor, day: day)
            .map { programCompositions in
                return State.loaded(programCompositions)
            }
            .catch { error in
                return Just(State.failed(error: error))
            }
            .eraseToAnyPublisher()
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
        
        func programs(for channel: SRGChannel?) -> [SRGProgram] {
            if case let .loaded(programCompositions) = self {
                if let channel = channel {
                    return programCompositions.first(where: { $0.channel == channel })?.programs ?? []
                }
                else {
                    return programCompositions.first?.programs ?? []
                }
            }
            else {
                return []
            }
        }
    }
}
