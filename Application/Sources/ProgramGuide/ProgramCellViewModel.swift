//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGDataProviderModel

// MARK: View model

final class ProgramCellViewModel: ObservableObject {
    @Published var data: ProgramAndChannel?
    @Published private(set) var date = Date()

    init() {
        Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .assign(to: &$date)
    }

    var title: String? {
        data?.program.wrappedValue.title
    }

    var accessibilityLabel: String? {
        data?.program.wrappedValue.play_accessibilityLabel(with: data?.channel.wrappedValue)
    }

    var timeRange: String? {
        guard let program = data?.program else { return nil }
        let startTime = DateFormatter.play_time.string(from: program.wrappedValue.startDate)
        let endTime = DateFormatter.play_time.string(from: program.extendedEndDate)
        // Unbreakable spaces before / after the separator
        return "\(startTime) - \(endTime)"
    }

    var canPlay: Bool {
        guard let channel = data?.channel, !channel.external else {
            return false
        }
        return progress != nil || data?.program.wrappedValue.mediaURN != nil
    }

    var progress: Double? {
        guard let program = data?.program else { return nil }
        let startDate = program.wrappedValue.startDate
        let progress = date.timeIntervalSince(startDate) / program.extendedEndDate.timeIntervalSince(program.wrappedValue.startDate)
        return (0 ... 1).contains(progress) ? progress : nil
    }
}
