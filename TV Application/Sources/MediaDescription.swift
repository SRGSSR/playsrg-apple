//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

struct MediaDescription {
    private static func placeholder(length: Int) -> String {
        return String(repeating: " ", count: length)
    }
    
    static func title(for media: SRGMedia?) -> String {
        guard let media = media else { return placeholder(length: 20) }
        return media.show?.title ?? media.title
    }
    
    static func subtitle(for media: SRGMedia?) -> String {
        guard let media = media else { return placeholder(length: 25) }
        guard media.contentType != .livestream else { return "" }
        if let showTitle = media.show?.title, !media.title.contains(showTitle) {
            return media.title
        }
        else {
            return DateFormatters.formattedRelativeDateAndTime(for: media.date)
        }
    }
    
    static func summary(for media: SRGMedia?) -> String? {
        guard let media = media else { return placeholder(length: 160) }
        return media.summary
    }
}
