//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel

extension SRGMedia {
    // FIXME: Ask IL to get this information in a media
    /**
     *  Return `true` iff the URN is related to a live center event.
     */
    @objc static func PlayIsSwissTXTURN(_ mediaURN: String) -> Bool {
        return mediaURN.contains(":swisstxt:")
    }
    
    var play_isToday: Bool {
        return NSCalendar.srg_default.isDateInToday(date)
    }
    
    // Return a concatenation of lead and summary, iff summary not contains the lead, to avoid duplicate information.
    @objc var play_fullSummary: String? {
        if let lead, !lead.isEmpty, let summary, !summary.isEmpty, !summary.contains(lead) {
            return "\(lead)\n\n\(summary)"
        } else if let summary, !summary.isEmpty {
            return summary
        } else if let lead, !lead.isEmpty {
            return lead
        } else {
            return nil
        }
    }
    
    var play_summary: String? {
        return leadOrSummary
    }
    
    private var leadOrSummary: String? {
        return lead?.isEmpty ?? true ? summary : lead
    }
    
    var play_areSubtitlesAvailable: Bool {
        return !play_subtitleVariants.isEmpty
    }
    
    var play_isAudioDescriptionAvailable: Bool {
        return play_audioVariants.contains(where: { $0.type == .audioDescription })
    }
    
    var play_isMultiAudioAvailable: Bool {
        let locales = self.play_audioVariants.map { $0.locale }
        return Set(locales).count > 1
    }
    
    @objc var play_isWebFirst: Bool {
        return date > Date() && timeAvailability(at: Date()) == .available && contentType == .episode
    }
    
    var play_subtitleLanguages: [String] {
        return play_subtitleVariants.map({ $0.language ?? $0.locale.identifier })
    }
    
    var play_audioLanguages: [String] {
        return play_audioVariants.map({ $0.language ?? $0.locale.identifier })
    }
    
    private var play_subtitleVariants: [SRGVariant] {
        return subtitleVariants(for: recommendedSubtitleVariantSource) ?? []
    }
    
    private var play_audioVariants: [SRGVariant] {
        return audioVariants(for: recommendedAudioVariantSource) ?? []
    }
    
    var publicationDate: Date {
        return startDate ?? date
    }
}
