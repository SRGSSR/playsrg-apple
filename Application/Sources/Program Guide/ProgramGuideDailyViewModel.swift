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
        
        Publishers.PublishAndRepeat(onOutputFrom: Signal.wokenUp()) {
            return SRGDataProvider.current!.tvPrograms(for: ApplicationConfiguration.shared.vendor, day: day)
                .map { programCompositions in
                    return State.loaded(programCompositions)
                }
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
