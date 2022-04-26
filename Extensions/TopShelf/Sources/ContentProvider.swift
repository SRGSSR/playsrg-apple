//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine
import TVServices

final class ContentProvider: TVTopShelfContentProvider {
    private struct ImageLayout {
        let image: SRGImage
        let shape: TVTopShelfSectionedItem.ImageShape
        let width1x: SRGImageWidth
        let width2x: SRGImageWidth
    }
    
    static let dataProvider: SRGDataProvider = {
        return SRGDataProvider(serviceURL: SRGIntegrationLayerProductionServiceURL())
    }()
    
    private var cancellable: AnyCancellable?
    
    private static let vendor: SRGVendor = {
        let businessUnit = Bundle.main.infoDictionary?["PlaySRGBusinessUnit"] as! String
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
        return Bundle.main.infoDictionary?["PlaySRGURLScheme"] as! String
    }()
    
    private static func imageLayout(for show: SRGShow) -> ImageLayout {
        let imageLayout = Bundle.main.infoDictionary?["PlaySRGImageLayout"] as! String
        switch imageLayout {
        case "poster":
            if let posterImage = show.posterImage {
                return ImageLayout(image: posterImage, shape: .poster, width1x: .width320, width2x: .width640)
            }
            else {
                return ImageLayout(image: show.image, shape: .hdtv, width1x: .width960, width2x: .width1920)
            }
        default:
            return ImageLayout(image: show.image, shape: .hdtv, width1x: .width960, width2x: .width1920)
        }
    }
    
    private static func url(for image: SRGImage?, width: SRGImageWidth) -> URL? {
        return dataProvider.url(for: image, width: width)
    }
    
    private static func contentPublisher() -> AnyPublisher<[SRGShow], Error> {
        let contentRequest = Bundle.main.infoDictionary?["PlaySRGContentRequest"] as! String
        switch contentRequest {
        case "all_shows":
            return dataProvider.tvShows(for: vendor)
        case "popular_shows":
            return dataProvider.mostSearchedShows(for: vendor, matching: .TV)
        default:
            assertionFailure("Unsupported content request")
            return Just([])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }
    
    private static func item(from show: SRGShow) -> TVTopShelfSectionedItem {
        let item = TVTopShelfSectionedItem(identifier: show.urn)
        item.title = show.title
        
        let imageLayout = Self.imageLayout(for: show)
        item.imageShape = imageLayout.shape
        item.setImageURL(url(for: imageLayout.image, width: imageLayout.width1x), for: .screenScale1x)
        item.setImageURL(url(for: imageLayout.image, width: imageLayout.width2x), for: .screenScale2x)
        item.displayAction = TVTopShelfAction(url: URL(string: "\(urlScheme)://show/\(show.urn)")!)
        return item
    }
    
    private static func content(from shows: [SRGShow]) -> TVTopShelfSectionedContent {
        let items = shows.map { item(from: $0) }
        let section = TVTopShelfItemCollection(items: items)
        section.title = NSLocalizedString("Popular on Play SRG", comment: "Most poular shows on Play SRG, displayed in the tvOS top shelf")
        return TVTopShelfSectionedContent(sections: [section])
    }
    
    private static func contentPublisher() -> AnyPublisher<TVTopShelfContent?, Never> {
        return contentPublisher()
            .map { Optional(content(from: $0)) }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
    
    override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
        cancellable = Self.contentPublisher()
            .sink { content in
                // Can be called from a background thread according to `loadTopShelfContent(completionHandler:)` documentation.
                completionHandler(content)
            }
    }
}
