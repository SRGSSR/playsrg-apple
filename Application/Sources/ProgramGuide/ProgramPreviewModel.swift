//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGDataProviderModel

// MARK: View model

final class ProgramPreviewModel: ObservableObject {
    @Published var program: SRGProgram?
    @Published private(set) var date = Date()
    
    var subtitle: String? {
        return program?.subtitle != nil ? program?.title : nil
    }
    
    var title: String {
        if let subtitle = program?.subtitle {
            return subtitle
        }
        else {
            return program?.title ?? "                "
        }
    }
    
    var timeInformation: String {
        guard let program = program else { return "       " }
        let nowDate = Date()
        if program.play_contains(nowDate) {
            let remainingTimeInterval = program.endDate.timeIntervalSince(nowDate)
            let remainingTime = PlayRemainingTimeFormattedDuration(remainingTimeInterval)
            return String(format: NSLocalizedString("%@ remaining", comment: "Text displayed on live cells telling how much time remains for a program currently on air"), remainingTime)
        }
        else {
            let startTime = DateFormatter.play_time.string(from: program.startDate)
            let endTime = DateFormatter.play_time.string(from: program.endDate)
            // Unbreakable spaces before / after the separator
            return "\(startTime) - \(endTime)"
        }
    }
    
    var imageUrl: URL? {
        return program?.imageUrl(for: .medium)
    }
    
    init() {
        Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .assign(to: &$date)
    }
}
