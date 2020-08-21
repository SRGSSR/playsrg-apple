//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import SwiftUI

struct ShowCell: View {
    private static let cellWidth: CGFloat = 375
    private static let cellSize = CGSize(width: Self.cellWidth, height: Self.cellWidth * 9 / 16)
    
    let show: SRGShow?
    
    private var title: String {
        guard let show = show else { return String(repeating: " ", count: .random(in: 10..<20)) }
        return show.title
    }
    
    private var imageUrl: URL? {
        return show?.imageURL(for: .height, withValue: Self.cellSize.height, type: .default)
    }
    
    private var redactionReason: RedactionReasons {
        return show == nil ? .placeholder : .init()
    }
    
    var body: some View {
        Button(action: {
            // TODO: Open show page
        }) {
            ZStack {
                ImageView(url: imageUrl)
                    .whenRedacted { $0.hidden() }
                    .frame(maxWidth: Self.cellSize.width, maxHeight: Self.cellSize.height)
                Rectangle()
                    .fill(Color(white: 0, opacity: 0.4))
                Text(title)
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
