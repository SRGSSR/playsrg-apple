//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel

struct Bucket: Identifiable, Equatable {
    let urn: String
    let name: String
    let count: UInt
    
    var id: String {
        return urn
    }
    
    init(from topicBucket: SRGTopicBucket) {
        urn = topicBucket.urn
        name = topicBucket.title
        count = topicBucket.count
    }
    
    init(from showBucket: SRGShowBucket) {
        urn = showBucket.urn
        name = showBucket.title
        count = showBucket.count
    }
    
    var title: String {
        return "\(name) (\(NumberFormatter.localizedString(from: count as NSNumber, number: .decimal)))"
    }
    
    var accessibilityLabel: String {
        let items = String(format: PlaySRGAccessibilityLocalizedString("%d items", comment: "Number of items aggregated in search"), count)
        return "\(name) (\(items))"
    }
}
