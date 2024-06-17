//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

// MARK: View model

final class LiveMediaCellViewModel: ObservableObject {
    @Published var media: SRGMedia? {
        didSet {
            registerForChannelUpdates(for: media)
        }
    }

    @Published private(set) var programComposition: SRGProgramComposition?
    @Published private(set) var date = Date()

    private var channelObserver: Any?

    init() {
        Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .assign(to: &$date)
    }

    deinit {
        unregisterChannelUpdates()
    }

    private func registerForChannelUpdates(for media: SRGMedia?) {
        unregisterChannelUpdates()

        if let media, let channel = media.channel, media.contentType == .livestream {
            channelObserver = ChannelService.shared.addObserverForUpdates(with: channel, livestreamUid: media.uid) { [weak self] composition in
                guard let self else { return }
                programComposition = composition
            }
        }
    }

    private func unregisterChannelUpdates() {
        programComposition = nil
        ChannelService.shared.removeObserver(channelObserver)
    }
}

// MARK: Properties

extension LiveMediaCellViewModel {
    var channel: SRGChannel? {
        programComposition?.channel ?? media?.channel
    }

    var logoImage: UIImage? {
        channel?.play_largeLogoImage
    }

    var program: SRGProgram? {
        programComposition?.play_program(at: date)
    }

    var title: String? {
        if let channel {
            program?.title ?? channel.title
        } else if let media {
            MediaDescription.title(for: media, style: .date)
        } else {
            nil
        }
    }

    var subtitle: String? {
        if let media, media.contentType == .scheduledLivestream {
            return MediaDescription.subtitle(for: media, style: .date)
        } else {
            guard let program else { return nil }
            let remainingTimeInterval = program.endDate.timeIntervalSince(date)
            let remainingTime = PlayRemainingTimeFormattedDuration(remainingTimeInterval)
            return String(format: NSLocalizedString("%@ remaining", comment: "Text displayed on live cells telling how much time remains for a program currently on air"), remainingTime)
        }
    }

    var progress: Double? {
        if channel != nil {
            guard let program else { return nil }
            let progress = date.timeIntervalSince(program.startDate) / program.endDate.timeIntervalSince(program.startDate)
            return progress.clamped(to: 0 ... 1)
        } else if let media, media.contentType == .scheduledLivestream, media.timeAvailability(at: date) == .available,
                  let startDate = media.startDate,
                  let endDate = media.endDate {
            let progress = date.timeIntervalSince(startDate) / endDate.timeIntervalSince(startDate)
            return progress.clamped(to: 0 ... 1)
        } else {
            return nil
        }
    }

    var imageUrl: URL? {
        url(for: program?.image, size: .small) ?? url(for: media?.image, size: .small)
    }
}

// MARK: Accessibility

extension LiveMediaCellViewModel {
    var accessibilityLabel: String? {
        if let channel {
            var label = String(format: PlaySRGAccessibilityLocalizedString("%@ live", comment: "Live content label, with a channel title"), channel.title)
            if let program {
                label.append(", \(program.title)")
            }
            return label
        } else if let media {
            return MediaDescription.cellAccessibilityLabel(for: media)
        } else {
            return nil
        }
    }
}
