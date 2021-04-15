//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

extension PageViewController {
    struct PageMediaCell: View {
        let media: SRGMedia?
        let section: PageModel.Section
        
        var body: some View {
            if section.properties.layout == .hero {
                #if os(tvOS)
                FeaturedMediaCell(media: media, layout: .hero)
                #else
                MediaCell(media: media, style: .show)
                #endif
            }
            else if section.properties.layout == .highlight {
                #if os(tvOS)
                FeaturedMediaCell(media: media, layout: .hero)
                #else
                MediaCell(media: media, style: .show)
                #endif
            }
            else if section.properties.presentationType == .livestreams {
                if let media = media, media.contentType == .livestream || media.contentType == .scheduledLivestream {
                    LiveMediaCell(media: media)
                }
                else {
                    MediaCell(media: media)
                }
            }
            else {
                MediaCell(media: media, style: .show)
            }
        }
    }

    struct PageShowCell: View {
        let show: SRGShow?
        let section: PageModel.Section
        
        var body: some View {
            if section.properties.layout == .hero {
                #if os(tvOS)
                FeaturedShowCell(show: show, layout: .hero)
                #else
                ShowCell(show: show)
                #endif
            }
            else if section.properties.layout == .highlight {
                #if os(tvOS)
                FeaturedShowCell(show: show, layout: .highlight)
                #else
                ShowCell(show: show)
                #endif
            }
            else {
                ShowCell(show: show)
            }
        }
    }

    struct PageCell: View {
        let item: PageModel.Item
        
        var body: some View {
            switch item {
            case let .mediaPlaceholder(index: _, section: section):
                PageMediaCell(media: nil, section: section)
            case let .media(media, section: section):
                PageMediaCell(media: media, section: section)
            case let .showPlaceholder(index: _, section: section):
                PageShowCell(show: nil, section: section)
            case let .show(show, section: section):
                PageShowCell(show: show, section: section)
            case .topicPlaceholder:
                TopicCell(topic: nil)
            case let .topic(topic, section: _):
                TopicCell(topic: topic)
            #if os(iOS)
            case .showAccess:
                ShowAccessCell(action: { _ in })
            #endif
            }
        }
    }
}
