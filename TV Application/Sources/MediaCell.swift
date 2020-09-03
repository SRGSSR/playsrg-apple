//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import SwiftUI

struct MediaCell: View {
    let media: SRGMedia?
    
    private var title: String {
        guard let media = media else { return String(repeating: " ", count: .random(in: 15..<30)) }
        return media.title
    }
    
    private var imageUrl: URL? {
        return media?.imageURL(for: .width, withValue: 200, type: .default)
    }
    
    private var redactionReason: RedactionReasons {
        return media == nil ? .placeholder : .init()
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Button(action: {}) {
                    ImageView(url: imageUrl)
                        .whenRedacted { $0.hidden() }
                        .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                }
                .buttonStyle(CardButtonStyle())
                
                Text(title)
                    .frame(width: geometry.size.width, alignment: .leading)
            }
            .redacted(reason: redactionReason)
        }
    }
}
