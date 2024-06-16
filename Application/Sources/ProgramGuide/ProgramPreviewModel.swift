//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGDataProviderModel

// MARK: View model

final class ProgramPreviewModel: ObservableObject {
    @Published var data: ProgramAndChannel?
    @Published private(set) var date = Date()

    private var program: SRGProgram? {
        data?.program
    }

    private var isLive: Bool {
        guard let program else { return false }
        return (program.startDate ... program.endDate).contains(date)
    }

    var availabilityBadgeProperties: MediaDescription.BadgeProperties? {
        if isLive {
            MediaDescription.liveBadgeProperties()
        } else {
            nil
        }
    }

    private var primaryTitle: String {
        program?.title ?? .placeholder(length: 16)
    }

    private var secondaryTitle: String? {
        program?.subtitle ?? program?.lead
    }

    var subtitle: String? {
        secondaryTitle != nil ? primaryTitle : nil
    }

    var title: String {
        if let secondaryTitle {
            secondaryTitle
        } else {
            primaryTitle
        }
    }

    var timeInformation: String {
        guard let program else { return .placeholder(length: 8) }
        let nowDate = Date()
        if program.play_containsDate(nowDate) {
            let remainingTimeInterval = program.endDate.timeIntervalSince(nowDate)
            let remainingTime = PlayRemainingTimeFormattedDuration(remainingTimeInterval)
            return String(format: NSLocalizedString("%@ remaining", comment: "Text displayed on live cells telling how much time remains for a program currently on air"), remainingTime)
        } else {
            let startTime = DateFormatter.play_time.string(from: program.startDate)
            let endTime = DateFormatter.play_time.string(from: program.endDate)
            // Unbreakable spaces before / after the separator
            return "\(startTime) - \(endTime)"
        }
    }

    var imageUrl: URL? {
        data?.programGuideImageUrl(size: .large)
    }

    init() {
        Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .assign(to: &$date)
    }
}
