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
        ZStack {
            ImageView(url: imageUrl)
                .whenRedacted { $0.hidden() }
            Rectangle()
                .fill(Color(white: 0, opacity: 0.4))
            Text(title)
                .foregroundColor(.white)
                .padding()
        }
        .cornerRadius(10)
        .redacted(reason: redactionReason)
    }
}
