//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

struct MediaDescription {
    private static func placeholder(minLength: Int, maxLength: Int) -> String {
        return String(repeating: " ", count: .random(in: minLength..<maxLength))
    }
    
    static func title(for media: SRGMedia?) -> String {
        guard let media = media else { return placeholder(minLength: 15, maxLength: 30) }
        return media.show?.title ?? media.title
    }
    
    static func subtitle(for media: SRGMedia?) -> String {
        guard let media = media else { return placeholder(minLength: 20, maxLength: 30) }
        if let showTitle = media.show?.title, !media.title.contains(showTitle) {
            return media.title
        }
        else {
            return DateFormatters.formattedRelativeDateAndTime(for: media.date)
        }
    }
    
    static func summary(for media: SRGMedia?) -> String? {
        guard let media = media else { return placeholder(minLength: 120, maxLength: 200) }
        return media.summary
    }
}
