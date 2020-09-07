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
        return topic?.imageURL(for: .width, withValue: SizeForImageScale(.small).width, type: .default)
    }
    
    private var redactionReason: RedactionReasons {
        return topic == nil ? .placeholder : .init()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ImageView(url: imageUrl)
                    .whenRedacted { $0.hidden() }
                Rectangle()
                    .fill(Color(white: 0, opacity: 0.4))
                Text(title)
                    .srgFont(.regular, size: .headline)
                    .lineLimit(1)
                    .foregroundColor(.white)
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .redacted(reason: redactionReason)
        }
    }
}
