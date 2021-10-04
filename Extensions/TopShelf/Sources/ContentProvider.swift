//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine
import TVServices

final class ContentProvider: TVTopShelfContentProvider {
    static let dataProvider: SRGDataProvider = {
        // FIXME: Use ApplicationSettingServiceURL (or maybe later; not currently set on tvOS)
        return SRGDataProvider(serviceURL: SRGIntegrationLayerProductionServiceURL())
    }()
    
    private var cancellables = Set<AnyCancellable>()
    
    private static func mediaOptions(for media: SRGMedia) -> TVTopShelfCarouselItem.MediaOptions {
        var options = TVTopShelfCarouselItem.MediaOptions()
        if media.play_areSubtitlesAvailable {
            options.formUnion(.audioTranscriptionClosedCaptioning)
        }
        if media.play_isAudioDescriptionAvailable {
            options.formUnion(.audioDescription)
        }
        return options
    }
    
    private static func namedAttributes(from media: SRGMedia) -> [TVTopShelfNamedAttribute] {
        var attributes = [TVTopShelfNamedAttribute]()
        if let showTitle = media.show?.title {
            attributes.append(TVTopShelfNamedAttribute(name: NSLocalizedString("Show", comment: "Show label displayed in the tvOS top shelf media description"),
                                                       values: [showTitle]))
        }
        return attributes
    }
    
    private static func carouselItem(from media: SRGMedia) -> TVTopShelfCarouselItem {
        let item = TVTopShelfCarouselItem(identifier: media.urn)
        item.contextTitle = NSLocalizedString("Featured", comment: "Context title for items displayed in the tvOS top shelf")
        item.title = media.title
        item.summary = media.lead ?? media.summary
        item.duration = media.duration / 1000
        item.creationDate = media.date
        item.setImageURL(media.imageURL(for: .width, withValue: 1920, type: .default), for: .screenScale1x)
        item.setImageURL(media.imageURL(for: .width, withValue: 2 * 1920, type: .default), for: .screenScale2x)
        item.namedAttributes = namedAttributes(from: media)
        // FIXME: Use correct URL scheme associated with the app
        item.displayAction = TVTopShelfAction(url: URL(string: "playsrf-debug://media/\(media.urn)")!)
        return item
    }
    
    private static func carouselContent(from medias: [SRGMedia]) -> TVTopShelfCarouselContent {
        let items = medias.map { carouselItem(from: $0) }
        return TVTopShelfCarouselContent(style: .details, items: items)
    }
    
    private static func carouselContentPublisher() -> AnyPublisher<TVTopShelfContent?, Never> {
        // FIXME: Use business unit associated with the application
        return dataProvider.tvHeroStageMedias(for: .SRF)
            .map { Optional(carouselContent(from: $0)) }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
    
    override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
        Self.carouselContentPublisher()
            .sink { content in
                // Can be called from a background thread
                completionHandler(content)
            }
            .store(in: &cancellables)
    }
}
