//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import UIKit

// MARK: View model

final class WhatsNewViewModel: ObservableObject {
    @Published var url: URL?
    @Published private(set) var state: State = .loading
    
    init() {
        $url
            .compactMap { $0 }
            .map { url in
                return URLSession.shared.dataTaskPublisher(for: url)
                    .map(\.data)
                    .tryMap { data in
                        let temporaryFileUrl = URL(fileURLWithPath: NSTemporaryDirectory())
                            .appendingPathComponent(UUID().uuidString)
                            .appendingPathExtension("html")
                        try data.write(to: temporaryFileUrl)
                        
                        var urlComponents = URLComponents(url: temporaryFileUrl, resolvingAgainstBaseURL: false)!
                        urlComponents.queryItems = [
                            URLQueryItem(name: "build", value: Self.build),
                            URLQueryItem(name: "version", value: Self.version),
                            URLQueryItem(name: "ios", value: Self.ios)
                        ]
                        return urlComponents.url!
                    }
                    .map { State.loaded(localFileUrl: $0) }
                    .catch { error in
                        return Just(State.failure(error: error))
                    }
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .assign(to: &$state)
    }
    
    private static var build: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
    }
    
    private static var version: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        return shortVersion.components(separatedBy: "-").first!
    }
    
    private static var ios: String {
        return UIDevice.current.systemVersion
    }
}

// MARK: Types

extension WhatsNewViewModel {
    enum State {
        case loading
        case loaded(localFileUrl: URL)
        case failure(error: Error)
    }
}
