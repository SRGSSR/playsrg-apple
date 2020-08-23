//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import SwiftUI

struct ShowCell: View {
    let show: SRGShow?
    
    private var title: String {
        guard let show = show else { return String(repeating: " ", count: .random(in: 10..<20)) }
        return show.title
    }
    
    private var imageUrl: URL? {
        return show?.imageURL(for: .width, withValue: 200, type: .default)
    }
    
    private var redactionReason: RedactionReasons {
        return show == nil ? .placeholder : .init()
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
