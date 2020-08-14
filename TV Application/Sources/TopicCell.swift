//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import SwiftUI

struct TopicCell: View {
    private static let cellWidth: CGFloat = 250
    private static let cellSize = CGSize(width: Self.cellWidth, height: Self.cellWidth * 9 / 16)
    
    let topic: SRGTopic?
    
    private var title: String {
        return topic?.title ?? ""
    }
    
    private var imageUrl: URL? {
        return topic?.imageURL(for: .height, withValue: Self.cellSize.height, type: .default)
    }
    
    private var redactionReason: RedactionReasons {
        return topic == nil ? .placeholder : .init()
    }
    
    var body: some View {
        Button(action: { /* Open the topic detail page */ }) {
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
            .frame(width: Self.cellSize.width, height: Self.cellSize.height)
        }
        .buttonStyle(CardButtonStyle())
        .padding(.top, 20)
        .padding(.bottom, 80)
        .redacted(reason: redactionReason)
    }
}
