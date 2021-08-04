//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import Foundation

// MARK: View model

final class ProgramViewModel: ObservableObject {
    @Published var program: SRGProgram? {
        didSet {
            updatePublishers()
        }
    }
    
    @Published private var media: SRGMedia?
    
    private var cancellables = Set<AnyCancellable>()
    
    var title: String? {
        return program?.title
    }
    
    var lead: String? {
        return program?.lead
    }
    
    var summary: String? {
        return program?.summary
    }
    
    var formattedTimeAndDate: String? {
        guard let program = program else { return nil }
        let startTime = DateFormatter.play_time.string(from: program.startDate)
        let endTime = DateFormatter.play_time.string(from: program.endDate)
        let day = DateFormatter.play_relative.string(from: program.startDate)
        return "\(startTime) - \(endTime), \(day)"
    }
    
    var imageUrl: URL? {
        return program?.imageUrl(for: .medium)
    }
    
    var duration: Double? {
        guard let program = program else { return nil }
        let duration = program.endDate.timeIntervalSince(program.startDate)
        return duration > 0 ? duration : nil
    }
    
    var hasMultiAudio: Bool {
        return program?.alternateAudioAvailable ?? false
    }
    
    var hasAudioDescription: Bool {
        return program?.audioDescriptionAvailable ?? false
    }
    
    var hasSubtitles: Bool {
        return program?.subtitlesAvailable ?? false
    }
    
    var imageCopyright: String? {
        guard let imageCopyright = program?.imageCopyright else { return nil }
        return String(format: NSLocalizedString("Image credit: %@", comment: "Image copyright introductory label"), imageCopyright)
    }
    
    var hasActions: Bool {
        return media != nil
    }
    
    private func updatePublishers() {
        cancellables = []
        media = nil
        
        if let mediaUrn = program?.mediaURN {
            SRGDataProvider.current!.media(withUrn: mediaUrn)
                .map { Optional($0) }
                .replaceError(with: nil)
                .receive(on: DispatchQueue.main)
                .assign(to: &$media)
        }
    }
}
