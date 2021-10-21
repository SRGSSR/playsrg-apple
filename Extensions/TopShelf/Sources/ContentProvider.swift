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
    
    private static func item(from show: SRGShow) -> TVTopShelfSectionedItem {
        let item = TVTopShelfSectionedItem(identifier: show.urn)
        item.title = show.title
        item.imageShape = .hdtv
        item.setImageURL(show.imageURL(for: .width, withValue: Self.imageWidth, type: .default), for: .screenScale1x)
        item.setImageURL(show.imageURL(for: .width, withValue: 2 * Self.imageWidth, type: .default), for: .screenScale2x)
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
        return dataProvider.mostSearchedShows(for: vendor)
            .map { Optional(content(from: $0)) }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
    
    override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
        Self.contentPublisher()
            .sink { content in
                // Can be called from a background thread according to `loadTopShelfContent(completionHandler:)` documentation.
                completionHandler(content)
            }
            .store(in: &cancellables)
    }
}
