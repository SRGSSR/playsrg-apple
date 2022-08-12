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
        case .tvLiveCenter:
            return .tvLiveCenter
        case .tvScheduledLivestreams:
            return .tvScheduledLivestreams
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
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }
    
    private static var type: String {
        return UIDevice.current.userInterfaceIdiom == .pad ? "tablet" : "phone"
    }
    
    private static var identifier: String? {
        return UserDefaults.standard.string(forKey: "tc_unique_id")
    }
    
    var feedbackUrlWithParameters: URL? {
        guard let feedbackUrl = feedbackURL else { return nil }
        guard var urlComponents = URLComponents(url: feedbackUrl, resolvingAgainstBaseURL: false) else { return feedbackUrl }
        
        let feedbackQueryItems = [
            URLQueryItem(name: "platform", value: "iOS"),
            URLQueryItem(name: "version", value: Self.version),
            URLQueryItem(name: "type", value: Self.type),
            URLQueryItem(name: "cid", value: Self.identifier)
        ]
        if let queryItems = urlComponents.queryItems {
            urlComponents.queryItems = feedbackQueryItems.appending(contentsOf: queryItems)
        }
        else {
            urlComponents.queryItems = feedbackQueryItems
        }
        return urlComponents.url ?? feedbackUrl
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
    
    case tvLiveCenter
    case tvScheduledLivestreams
    
#if os(iOS)
    case downloads
    case notifications
    case radioShowAccess(channelUid: String)
#endif
}
