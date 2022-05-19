//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

struct ServiceMessage: Decodable, Equatable {
    private var data: ServiceMessageData
    
    var text: String {
        return data.text
    }
    
    static func == (lhs: ServiceMessage, rhs: ServiceMessage) -> Bool {
        return lhs.data.text == rhs.data.text
    }
    
    private struct ServiceMessageData: Decodable {
        var text: String
    }
}
