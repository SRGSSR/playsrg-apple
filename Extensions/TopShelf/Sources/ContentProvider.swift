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
    
    private var cancellables = Set<AnyCancellable>()
    
    private static func carouselItem(from media: SRGMedia) -> TVTopShelfCarouselItem {
        let item = TVTopShelfCarouselItem(identifier: media.urn)
        item.contextTitle = NSLocalizedString("Featured", comment: "Context title for items displayed in the tvOS top shelf")
        item.title = media.title
        item.summary = media.summary
        item.duration = media.duration / 1000
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
