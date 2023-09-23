//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

extension ApplicationConfiguration {
    private static func configuredSection(from homeSection: HomeSection) -> ConfiguredSection? {
        switch homeSection {
        case .tvLive:
            return .tvLive
        case .radioLive:
            return .radioLive
        case .radioLiveSatellite:
            return .radioLiveSatellite
        case .tvLiveCenterScheduledLivestreams:
            return .tvLiveCenterScheduledLivestreams
        case .tvLiveCenterScheduledLivestreamsAll:
            return .tvLiveCenterScheduledLivestreamsAll
        case .tvLiveCenterEpisodes:
            return .tvLiveCenterEpisodes
        case .tvLiveCenterEpisodesAll:
            return .tvLiveCenterEpisodesAll
        case .tvScheduledLivestreams:
            return .tvScheduledLivestreams
        case .tvScheduledLivestreamsSignLanguage:
            return .tvScheduledLivestreamsSignLanguage
        default:
            return nil
        }
    }
    
    var liveConfiguredSections: [ConfiguredSection] {
        return liveHomeSections.compactMap { homeSection in
            guard let homeSection = HomeSection(rawValue: homeSection.intValue) else { return nil }
            return Self.configuredSection(from: homeSection)
        }
    }
    
    var serviceMessageUrl: URL {
        return URL(string: "v3/api/\(businessUnitIdentifier)/general-information-message", relativeTo: playServiceURL)!
    }
    
    func relatedContentUrl(for media: SRGMedia) -> URL {
        return URL(string: "api/v2/playlist/recommendation/relatedContent/\(media.urn)", relativeTo: self.middlewareURL)!
    }
    
    private static var version: String {
        return Bundle.main.play_friendlyVersionNumber
    }
    
    private static var type: String {
        return UIDevice.current.userInterfaceIdiom == .pad ? "tablet" : "phone"
    }
    
    private static var identifier: String? {
        return UserDefaults.standard.string(forKey: "tc_unique_id")
    }
    
    private static func typeformUrlWithParameters(_ url: URL) -> URL {
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
        guard let host = urlComponents.host, host.contains("typeform.") else { return url }
        
        let typeformQueryItems = [
            URLQueryItem(name: "platform", value: "iOS"),
            URLQueryItem(name: "version", value: version),
            URLQueryItem(name: "type", value: type),
            URLQueryItem(name: "cid", value: identifier)
        ]
        if let queryItems = urlComponents.queryItems {
            urlComponents.queryItems = typeformQueryItems.appending(contentsOf: queryItems)
        }
        else {
            urlComponents.queryItems = typeformQueryItems
        }
        return urlComponents.url ?? url
    }
    
    var userSuggestionUrlWithParameters: URL? {
        guard let feedbackUrl = feedbackURL else { return nil }
        
        return Self.typeformUrlWithParameters(feedbackUrl)
    }
    
    var tvGuideOtherBouquets: [TVGuideBouquet] {
        return self.tvGuideOtherBouquetsObjc.map { number in
            return TVGuideBouquet(rawValue: number.intValue)!
        }
    }
}

enum ConfiguredSection: Hashable {
    case show(SRGShow)
    
    case favoriteShows
    case history
    case watchLater
    
    case tvAllShows
    case tvEpisodesForDay(_ day: SRGDay)
    
    case radioAllShows(channelUid: String)
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
    case tvScheduledLivestreamsSignLanguage
    
#if os(iOS)
    case downloads
    case notifications
    case radioShowAccess(channelUid: String)
#endif
}
