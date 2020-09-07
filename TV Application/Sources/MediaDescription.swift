//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

struct MediaDescription {
    private static func showName(for media: SRGMedia) -> String? {
        guard let show = media.show else { return nil }
        return !media.title.contains(show.title) ? show.title : nil
    }
    
    private static func placeholder(minLength: Int, maxLength: Int) -> String {
        return String(repeating: " ", count: .random(in: minLength..<maxLength))
    }
    
    static func title(for media: SRGMedia?) -> String {
        guard let media = media else { return placeholder(minLength: 15, maxLength: 30) }
        return media.title
    }
    
    static func subtitle(for media: SRGMedia?) -> String {
        guard let media = media else { return placeholder(minLength: 20, maxLength: 30) }
        if let showName = Self.showName(for: media) {
            return "\(showName) - \(DateFormatters.formattedRelativeDate(for: media.date))"
        }
        else {
            return DateFormatters.formattedRelativeDateAndTime(for: media.date)
        }
    }
}
