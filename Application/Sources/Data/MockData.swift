//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

#if DEBUG

struct MockData {
    enum Kind: String {
        case standard
        case overflow
        
        fileprivate func resource(named name: String) -> String {
            return "\(name)-\(self)"
        }
    }
    
    private static func mockObject<T>(_ name: String, type: T.Type) -> T {
        let asset = NSDataAsset(name: name)!
        let jsonData = try! JSONSerialization.jsonObject(with: asset.data, options: []) as? [String: Any]
        return try! MTLJSONAdapter(modelClass: type as? AnyClass)?.model(fromJSONDictionary: jsonData) as! T
    }
    
    static func show(_ kind: Kind = .standard) -> SRGShow {
        return mockObject(kind.resource(named: "show"), type: SRGShow.self)
    }
    
    static func media(_ kind: Kind = .standard) -> SRGMedia {
        return mockObject(kind.resource(named: "media"), type: SRGMedia.self)
    }
    
    static func topic(_ kind: Kind = .standard) -> SRGTopic {
        return mockObject(kind.resource(named: "topic"), type: SRGTopic.self)
    }
}

#endif
