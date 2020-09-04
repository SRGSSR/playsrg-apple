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
        return show?.imageURL(for: .width, withValue: SizeForImageScale(.small).width, type: .default)
    }
    
    private var redactionReason: RedactionReasons {
        return show == nil ? .placeholder : .init()
    }
    
    var body: some View {
        GeometryReader { geometry in
            Button(action: {}) {
                ZStack {
                    ImageView(url: imageUrl)
                        .whenRedacted { $0.hidden() }
                    Rectangle()
                        .fill(Color(white: 0, opacity: 0.4))
                    Text(title)
                        .foregroundColor(.white)
                        .padding()
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .buttonStyle(CardButtonStyle())
            .redacted(reason: redactionReason)
        }
    }
}
