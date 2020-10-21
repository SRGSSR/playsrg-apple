//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

class MediaDetailModel: ObservableObject {
    let media: SRGMedia
    
    @Published private(set) var relatedMedias: [SRGMedia] = []
    
    var cancellables = Set<AnyCancellable>()
    
    init(media: SRGMedia) {
        self.media = media
    }
    
    func refresh() {
        let middleWareURL:URL? = ApplicationConfiguration.shared.middlewareURL
        guard let _ = middleWareURL else { return }
        
        let resourcePath = "api/v2/playlist/recommendation/continuousPlayback/" + self.media.urn
        let middlewareURL = URL(string: resourcePath, relativeTo: middleWareURL)!
        
        URLSession.shared.dataTaskPublisher(for: middlewareURL)
            .map { $0.data }
            .decode(type: Recommendation.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
            .sink(receiveCompletion: {_ in }, receiveValue: { recommendation in
                SRGDataProvider.current!.medias(withUrns: recommendation.urns)
                    .map { $0.medias }
                    .replaceError(with: [])
                    .assign(to: \.relatedMedias, on: self)
                    .store(in: &self.cancellables)
            }).store(in: &cancellables)
    }
    
    func cancelRefresh() {
        cancellables = []
    }
}

struct Recommendation: Codable {
    let recommendationId: String
    let urns: [String]
}
