//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

#if DEBUG

struct MockData {
    private static func mockObject<T>(_ name: String, type: T.Type) -> T {
        let asset = NSDataAsset(name: name)!
        let jsonData = try! JSONSerialization.jsonObject(with: asset.data, options: []) as? [String: Any]
        return try! MTLJSONAdapter(modelClass: type as? AnyClass)?.model(fromJSONDictionary: jsonData) as! T
    }
    
    static func media() -> SRGMedia {
        return mockObject("media-rts", type: SRGMedia.self)
    }
    
    static func show() -> SRGShow {
        return mockObject("show-srf", type: SRGShow.self)
    }
    
    static func topic() -> SRGTopic {
        return mockObject("topic-rts", type: SRGTopic.self)
    }
}

#endif
