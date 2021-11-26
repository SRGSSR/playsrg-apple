//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGDataProviderModel

// MARK: View model

final class ProgramCellViewModel: ObservableObject {
    @Published var data: Data?
    @Published private(set) var date: Date = Date()
    
    init() {
        Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .assign(to: &$date)
    }
    
    var title: String? {
        return data?.program.title
    }
    
    var accessibilityLabel: String? {
        guard let data = data else { return nil }
        return data.program.play_accessibilityLabel(with: data.channel)
    }
    
    var timeRange: String? {
        guard let program = data?.program else { return nil }
        let startTime = DateFormatter.play_time.string(from: program.startDate)
        let endTime = DateFormatter.play_time.string(from: program.endDate)
        // Unbreakable spaces before / after the separator
        return "\(startTime) - \(endTime)"
    }
    
    var canPlay: Bool {
        return progress != nil || data?.program.mediaURN != nil
    }
    
    var progress: Double? {
        guard let program = data?.program else { return nil }
        let progress = date.timeIntervalSince(program.startDate) / program.endDate.timeIntervalSince(program.startDate)
        return (0...1).contains(progress) ? progress : nil
    }
}

// MARK: Types

extension ProgramCellViewModel {
    /// Input data for the model
    struct Data: Hashable {
        let program: SRGProgram
        let channel: SRGChannel?
    }
}
