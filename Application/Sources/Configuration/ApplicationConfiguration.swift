//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

extension ApplicationConfiguration {
    private static func configuredSection(from homeSection: HomeSection) -> ConfiguredSection? {
        switch homeSection {
        case .tvLive:
            .tvLive
        case .radioLive:
            .radioLive
        case .radioLiveSatellite:
            .radioLiveSatellite
        case .tvLiveCenterScheduledLivestreams:
            .tvLiveCenterScheduledLivestreams
        case .tvLiveCenterScheduledLivestreamsAll:
            .tvLiveCenterScheduledLivestreamsAll
        case .tvLiveCenterEpisodes:
            .tvLiveCenterEpisodes
        case .tvLiveCenterEpisodesAll:
            .tvLiveCenterEpisodesAll
        case .tvScheduledLivestreams:
            .tvScheduledLivestreams
        case .tvScheduledLivestreamsNews:
            .tvScheduledLivestreamsNews
        case .tvScheduledLivestreamsSport:
            .tvScheduledLivestreamsSport
        case .tvScheduledLivestreamsSignLanguage:
            .tvScheduledLivestreamsSignLanguage
        default:
            nil
        }
    }

    var liveConfiguredSections: [ConfiguredSection] {
        liveHomeSections.compactMap { homeSection in
            guard let homeSection = HomeSection(rawValue: homeSection.intValue) else { return nil }
            return Self.configuredSection(from: homeSection)
        }
    }

    var serviceMessageUrl: URL {
        URL(string: "v3/api/\(businessUnitIdentifier)/general-information-message", relativeTo: playServiceURL)!
    }

    func relatedContentUrl(for media: SRGMedia) -> URL {
        URL(string: "api/v2/playlist/recommendation/relatedContent/\(media.urn)", relativeTo: middlewareURL)!
    }

    func topicColors(for topic: SRGTopic) -> (Color, Color)? {
        guard let topicColorsArray = topicColors[topic.urn], topicColorsArray.count == 2 else { return nil }

        let colors = topicColorsArray.map { Color($0) }
        return (colors.first!, colors.last!)
    }

    private static var version: String {
        Bundle.main.play_friendlyVersionNumber
    }

    private static var type: String {
        if ProcessInfo.processInfo.isMacCatalystApp || ProcessInfo.processInfo.isiOSAppOnMac {
            "desktop"
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            "tablet"
        } else {
            "phone"
        }
    }

    private static var identifier: String? {
        UserDefaults.standard.string(forKey: "tc_unique_id")
    }

    private static func typeformUrlWithParameters(_ url: URL) -> URL {
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
        guard let host = urlComponents.host, host.contains("typeform.") else { return url }

        let typeformQueryItems = SupportInformation.toQueryItems()

        if let queryItems = urlComponents.queryItems {
            urlComponents.queryItems = typeformQueryItems.appending(contentsOf: queryItems)
        } else {
            urlComponents.queryItems = typeformQueryItems
        }
        return urlComponents.url ?? url
    }

    var supportFormUrlWithParameters: URL? {
        guard let supportFormURL else { return nil }

        return Self.typeformUrlWithParameters(supportFormURL)
    }

    var tvGuideOtherBouquets: [TVGuideBouquet] {
        tvGuideOtherBouquetsObjc.map { number in
            TVGuideBouquet(rawValue: number.intValue)!
        }
    }
}

enum ConfiguredSection: Hashable {
    case availableEpisodes(SRGShow)

    case favoriteShows(contentType: ContentType)
    case history
    case watchLater

    case tvAllShows
    case tvEpisodesForDay(_ day: SRGDay)

    case radioAllShows(channelUid: String?)
    case radioEpisodesForDay(_ day: SRGDay, channelUid: String)
    case radioFavoriteShows(channelUid: String)
    case radioLatest(channelUid: String)
    case radioLatestEpisodes(channelUid: String)
    case radioLatestEpisodesFromFavorites(channelUid: String)
    case radioLatestVideos(channelUid: String)
    case radioMostPopular(channelUid: String)
    case radioResumePlayback(channelUid: String)
    case radioWatchLater(channelUid: String)

    case tvLive
    case radioLive
    case radioLiveSatellite

    case tvLiveCenterScheduledLivestreams
    case tvLiveCenterScheduledLivestreamsAll
    case tvLiveCenterEpisodes
    case tvLiveCenterEpisodesAll
    case tvScheduledLivestreams
    case tvScheduledLivestreamsNews
    case tvScheduledLivestreamsSport
    case tvScheduledLivestreamsSignLanguage

    #if os(iOS)
        case downloads
        case notifications
        case radioShowAccess(channelUid: String)
    #endif
}
