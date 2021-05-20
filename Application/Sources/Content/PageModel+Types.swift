//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine
import SRGUserData

protocol PageSectionLayoutProperties {
    var layout: PageModel.SectionLayout { get }
    var canOpenDetailPage: Bool { get }
}

extension PageSectionLayoutProperties {
    var accessibilityHint: String? {
        if canOpenDetailPage {
            return PlaySRGAccessibilityLocalizedString("Shows all contents.", "Homepage header action hint")
        }
        else {
            return nil
        }
    }
    
    var isGridLayout: Bool {
        switch layout {
        case .mediaGrid, .showGrid, .liveMediaGrid:
            return true
        default:
            return false
        }
    }
    
    private var sectionPageLayout: PageModel.SectionLayout {
        switch layout {
        case .mediaSwimlane, .mediaGrid:
            return .mediaGrid
        case .showSwimlane, .showGrid:
            return .showGrid
        case .liveMediaSwimlane, .liveMediaGrid:
            return .liveMediaGrid
        case .hero:
            return .mediaGrid
        case .topicSelector:
            return .showGrid
        default:
            return layout
        }
    }
}

extension PageModel {
    enum Id: SectionFiltering {
        case video
        case audio(channel: RadioChannel)
        case live
        case topic(topic: SRGTopic)
        
        var supportsCastButton: Bool {
            switch self {
            case .video, .audio, .live:
                return true
            default:
                return false
            }
        }
        
        func canContain(show: SRGShow) -> Bool {
            switch self {
            case .video:
                return show.transmission == .TV
            case let .audio(channel: channel):
                return show.transmission == .radio && show.primaryChannelUid == channel.uid
            default:
                return false
            }
        }
        
        func compatibleShows(_ shows: [SRGShow]) -> [SRGShow] {
            return shows.filter { canContain(show: $0) }.sorted(by: { $0.title < $1.title })
        }
        
        func compatibleMedias(_ medias: [SRGMedia]) -> [SRGMedia] {
            switch self {
            case .video:
                return medias.filter { $0.mediaType == .video }
            case let .audio(channel: channel):
                return medias.filter { $0.mediaType == .audio && $0.channel?.uid == channel.uid }
            default:
                return medias
            }
        }
    }
    
    enum State {
        case loading
        case failed(error: Error)
        case loaded(rows: [Row])
    }
    
    enum SectionLayout: Hashable {
        case hero
        case highlight
        case liveMediaGrid
        case liveMediaSwimlane
        case mediaGrid
        case mediaSwimlane
        case showGrid
        case showSwimlane
        case topicSelector
        
        @available(tvOS, unavailable)
        case showAccess
    }
    
    struct Section: Hashable {
        let wrappedValue: Content.Section
        
        init(_ wrappedValue: Content.Section) {
            self.wrappedValue = wrappedValue
        }
        
        var properties: SectionProperties {
            return wrappedValue.properties
        }
        
        var layoutProperties: PageSectionLayoutProperties {
            switch wrappedValue {
            case let .content(section):
                return ContentSectionProperties(contentSection: section)
            case let .configured(section):
                return ConfiguredSectionProperties(configuredSection: section)
            }
        }
    }
    
    struct Item: Hashable {
        let wrappedValue: Content.Item
        let section: Section
        
        init(_ wrappedValue: Content.Item, in section: Section) {
            self.wrappedValue = wrappedValue
            self.section = section
        }
    }
    
    typealias Row = CollectionRow<Section, Item>
    
    struct ContentSectionProperties: PageSectionLayoutProperties {
        let contentSection: SRGContentSection
        
        private var presentation: SRGContentPresentation {
            return contentSection.presentation
        }
        
        var layout: PageModel.SectionLayout {
            switch presentation.type {
            case .hero:
                return .hero
            case .mediaHighlight, .showHighlight:
                return .highlight
            case .topicSelector:
                return .topicSelector
            case .showAccess:
                #if os(iOS)
                return .showAccess
                #else
                // Not supported
                return .mediaSwimlane
                #endif
            case .favoriteShows:
                return .showSwimlane
            case .swimlane:
                return (contentSection.type == .shows) ? .showSwimlane : .mediaSwimlane
            case .grid:
                return (contentSection.type == .shows) ? .showGrid : .mediaGrid
            case .livestreams:
                return .liveMediaSwimlane
            case .none, .resumePlayback, .watchLater, .personalizedProgram:
                return .mediaSwimlane
            }
        }
        
        var canOpenDetailPage: Bool {
            return presentation.hasDetailPage
        }
    }
    
    struct ConfiguredSectionProperties: PageSectionLayoutProperties {
        let configuredSection: ConfiguredSection
        
        var layout: PageModel.SectionLayout {
            switch configuredSection.type {
            case .radioLatestEpisodes, .radioMostPopular, .radioLatest, .radioLatestVideos:
                return (configuredSection.contentPresentationType == .hero) ? .hero : .mediaSwimlane
            case .tvLive, .radioLive, .radioLiveSatellite:
                #if os(iOS)
                return .liveMediaGrid
                #else
                return .liveMediaSwimlane
                #endif
            case .tvLiveCenter, .tvScheduledLivestreams:
                return .mediaSwimlane
            case .radioFavoriteShows:
                return .showSwimlane
            case .radioAllShows:
                return .showGrid
            case .radioShowAccess:
                #if os(iOS)
                return .showAccess
                #else
                // Not supported
                return .mediaSwimlane
                #endif
            }
        }
        
        var canOpenDetailPage: Bool {
            return layout == .mediaSwimlane
        }
    }
}
