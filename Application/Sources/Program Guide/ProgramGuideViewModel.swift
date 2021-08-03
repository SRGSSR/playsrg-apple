//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine

// MARK: View model

final class ProgramGuideViewModel: ObservableObject {
    @Published private(set) var channels: [SRGChannel] = []
    @Published var selectedChannel: SRGChannel?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(day: SRGDay) {
        Publishers.PublishAndRepeat(onOutputFrom: ApplicationSignal.wokenUp()) { [weak self] in
            return SRGDataProvider.current!.tvPrograms(for: ApplicationConfiguration.shared.vendor, day: day)
                .map { $0.map(\.channel) }
                .catch { _ in
                    return Just(self?.channels ?? [])
                }
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] channels in
            guard let self = self else { return }
            self.channels = channels
            if self.selectedChannel == nil {
                self.selectedChannel = channels.first
            }
        }
        .store(in: &cancellables)
    }
    
    func nextChannel() {
        guard let selectedChannel = selectedChannel,
              let index = channels.firstIndex(of: selectedChannel) else {
            return
        }
            
        let nextIndex = index < channels.endIndex - 1 ? channels.index(after: index) : channels.startIndex
        self.selectedChannel = channels[nextIndex]
    }
}
