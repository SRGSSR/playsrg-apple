//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

struct ServiceMessage: Codable, Identifiable, Equatable {
    private let data: Data
    
    var id: String {
        return data.id
    }
    
    var text: String {
        return data.text
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    private struct Data: Codable {
        let id: String
        let text: String
    }
}
