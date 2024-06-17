//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

struct ServiceMessage: Codable, Identifiable, Equatable {
    private let data: Data

    var id: String {
        data.id
    }

    var text: String {
        data.text
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    private struct Data: Codable {
        let id: String
        let text: String
    }
}
