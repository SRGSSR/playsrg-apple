//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

protocol LiveMedia {
    var media: SRGMedia? { get }
    var programComposition: SRGProgramComposition? { get }
}

extension LiveMedia {
    var channel: SRGChannel? {
        return programComposition?.channel ?? media?.channel
    }
    
    var logoImage: UIImage? {
        if let channel = channel {
            #if os(tvOS)
            return channel.play_logo60Image
            #else
            return channel.play_logo32Image
            #endif
        }
        else {
            return nil
        }
    }
    
    func program(at date: Date) -> SRGProgram? {
        return programComposition?.play_program(at: date)
    }
    
    func title(at date: Date) -> String {
        if let channel = channel {
            return program(at: date)?.title ?? channel.title
        }
        else {
            return MediaDescription.title(for: media) ?? ""
        }
    }
    
    func subtitle(at date: Date) -> String? {
        if let media = media, media.contentType == .scheduledLivestream {
            return MediaDescription.subtitle(for: media)
        }
        else {
            guard let currentProgram = program(at: date) else { return nil }
            let remainingTimeInterval = currentProgram.endDate.timeIntervalSince(date)
            let remainingTime = PlayRemainingTimeFormattedDuration(remainingTimeInterval)
            return String(format: NSLocalizedString("%@ remaining", comment: "Text displayed on live cells telling how much time remains for a program currently on air"), remainingTime)
        }
    }
    
    func imageUrl(at date: Date, for scale: ImageScale) -> URL? {
        if let channel = channel {
            return program(at: date)?.imageUrl(for: scale) ?? channel.imageUrl(for: scale)
        }
        else {
            return media?.imageUrl(for: scale)
        }
    }
    
    func progress(at date: Date) -> Double? {
        if channel != nil {
            guard let currentProgram = program(at: date) else { return 0 }
            return date.timeIntervalSince(currentProgram.startDate) / currentProgram.endDate.timeIntervalSince(currentProgram.startDate)
        }
        else if let media = media, media.contentType == .scheduledLivestream, media.timeAvailability(at: Date()) == .available,
                let startDate = media.startDate,
                let endDate = media.endDate {
            let progress = Date().timeIntervalSince(startDate) / endDate.timeIntervalSince(startDate)
            return progress.clamped(to: 0...1)
        }
        else {
            return nil
        }
    }
}
