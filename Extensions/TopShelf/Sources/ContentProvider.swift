//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine
import TVServices

final class ContentProvider: TVTopShelfContentProvider {
    static let dataProvider: SRGDataProvider = {
        return SRGDataProvider(serviceURL: SRGIntegrationLayerProductionServiceURL())
    }()
    
    private static let imageWidth: CGFloat = 1200
    
    private var cancellables = Set<AnyCancellable>()
    
    private static let vendor: SRGVendor = {
        let businessUnit = Bundle.main.infoDictionary?["AppBusinessUnit"] as! String
        switch businessUnit {
        case "rsi":
            return .RSI
        case "rtr":
            return .RTR
        case "rts":
            return .RTS
        case "srf":
            return .SRF
        case "swi":
            return .SWI
        default:
            assertionFailure("Unsupported business unit")
            return .SRF
        }
    }()
    
    private static let urlScheme: String = {
        return Bundle.main.infoDictionary?["AppURLScheme"] as! String
    }()
    
    private static func summary(for media: SRGMedia) -> String {
        if let description = media.lead ?? media.summary {
            return "\(media.title)\n\n\(description)"
        }
        else {
            return media.title
        }
    }
    
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
            attributes.append(
                TVTopShelfNamedAttribute(
                    name: NSLocalizedString("Show", comment: "Show label displayed in the tvOS top shelf media description"),
                    values: [showTitle]
                )
            )
        }
        return attributes
    }
    
    private static func carouselItem(from media: SRGMedia) -> TVTopShelfCarouselItem {
        // The context and main titles are only displayed when the cinemagraph video is played. We display the title
        // in the summary
        let item = TVTopShelfCarouselItem(identifier: media.urn)
        item.summary = summary(for: media)
        item.duration = media.duration / 1000
        item.creationDate = media.date
        item.setImageURL(media.imageURL(for: .width, withValue: Self.imageWidth, type: .default), for: .screenScale1x)
        item.setImageURL(media.imageURL(for: .width, withValue: 2 * Self.imageWidth, type: .default), for: .screenScale2x)
        item.mediaOptions = mediaOptions(for: media)
        item.namedAttributes = namedAttributes(from: media)
        item.displayAction = TVTopShelfAction(url: URL(string: "\(urlScheme)://media/\(media.urn)")!)
        item.playAction = TVTopShelfAction(url: URL(string: "\(urlScheme)://play/\(media.urn)")!)
        return item
    }
    
    private static func carouselContent(from medias: [SRGMedia]) -> TVTopShelfCarouselContent {
        let items = medias.map { carouselItem(from: $0) }
        return TVTopShelfCarouselContent(style: .details, items: items)
    }
    
    private static func carouselContentPublisher() -> AnyPublisher<TVTopShelfContent?, Never> {
        return dataProvider.tvLatestMedias(for: vendor)
            .map { Optional(carouselContent(from: $0)) }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
    
    override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
        Self.carouselContentPublisher()
            .sink { content in
                // Can be called from a background thread according to `loadTopShelfContent(completionHandler:)` documentation.
                completionHandler(content)
            }
            .store(in: &cancellables)
    }
}
