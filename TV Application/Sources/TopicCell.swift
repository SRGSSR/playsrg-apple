//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import SwiftUI

struct TopicCell: View {
    let topic: SRGTopic?
    
    private var title: String {
        return topic?.title ?? ""
    }
    
    private var imageUrl: URL? {
        return topic?.imageURL(for: .width, withValue: 200, type: .default)
    }
    
    private var redactionReason: RedactionReasons {
        return topic == nil ? .placeholder : .init()
    }
    
    var body: some View {
        ZStack {
            ImageView(url: imageUrl)
                .whenRedacted { $0.hidden() }
            Rectangle()
                .fill(Color(white: 0, opacity: 0.4))
            Text(title)
                .lineLimit(1)
                .foregroundColor(.white)
                .padding()
        }
        .cornerRadius(10)
        .redacted(reason: redactionReason)
    }
}
