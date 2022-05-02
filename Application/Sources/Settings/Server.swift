//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

struct Server: Hashable, Identifiable {
    let url: URL
    let title: String
    
    static var production = Server(url: SRGIntegrationLayerProductionServiceURL(), title: PlaySRGSettingsLocalizedString("Production", comment: "Service URL setting state"))
    
    static var servers: [Server] = {
        guard let plistServers = plistServers, !plistServers.isEmpty else {
            return [production]
        }
        return plistServers
    }()
    
    private static var plistServers: [Server]? = {
        guard let path = Bundle.main.path(forResource: "Settings.server", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let values = plist.value(forKey: "Values") as? [String],
              let titles = plist.value(forKey: "Titles") as? [String],
              values.count == titles.count,
              values.count != 0
        else {
            return nil
        }
        
        return values.enumeratedCompactMap { value, index in
            guard let serverURL = URL(string: value) else { return nil }
            return Server(url: serverURL, title: PlaySRGSettingsLocalizedString(titles[index], comment: nil))
        }
    }()
    
    static func server(for urlString: String?) -> Server {
        guard let urlString = urlString, let server = servers.first(where: { $0.url.absoluteString == urlString }) else {
            return .production
        }
        return server
    }
    
    var id: URL {
        return url
    }
}
