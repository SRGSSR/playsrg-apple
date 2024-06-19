//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

struct Recommendation: Codable {
    /**
     *  The recommendation identifier.
     */
    let recommendationId: String

    /**
     *  The recommended URN list.
     *
     *  @discussion Contains as first item the URN which the recommendation was retrieved for, to which the recommended medias are appended.
     */
    let urns: [String]
}
