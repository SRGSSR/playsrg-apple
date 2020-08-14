//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import SwiftUI

struct HeroMediaCell: View {
    static let cellSize = CGSize(width: 1740, height: 560)
    
    let media: SRGMedia?
    
    private var title: String {
        guard let media = media else { return String(repeating: " ", count: .random(in: 15..<30)) }
        return media.title
    }
    
    private var imageUrl: URL? {
        return media?.imageURL(for: .height, withValue: Self.cellSize.height, type: .default)
    }
    
    private var redactionReason: RedactionReasons {
        return media == nil ? .placeholder : .init()
    }
    
    var body: some View {
        Button(action: { /* Open the player */ }) {
            ZStack {
                ImageView(url: imageUrl, contentMode: .fill)
                    .whenRedacted { $0.hidden() }
                Rectangle()
                    .fill(Color(white: 0, opacity: 0.4))
                Text(title)
                    .padding()
            }
            .frame(width: Self.cellSize.width, height: Self.cellSize.height)
        }
        .buttonStyle(CardButtonStyle())
        .padding(.top, 20)
        .padding(.bottom, 80)
        .redacted(reason: redactionReason)
    }
}
