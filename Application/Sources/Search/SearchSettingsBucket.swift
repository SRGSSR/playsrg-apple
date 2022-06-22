//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

struct SearchTopicBucket: Identifiable, Equatable {
    let bucket: SRGTopicBucket
    
    var id: String {
        return bucket.urn
    }
    
    var title: String {
        return bucket.title
    }
    
    static func == (lhs: SearchTopicBucket, rhs: SearchTopicBucket) -> Bool {
        return lhs.id == rhs.id
    }
}
