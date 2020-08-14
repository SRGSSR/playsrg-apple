//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import SwiftUI

struct MediaCell: View {
    private static let cellWidth: CGFloat = 375
    private static let cellSize = CGSize(width: Self.cellWidth, height: Self.cellWidth * 9 / 16)
    
    let media: SRGMedia?
    
    @State private var isPresented = false
    
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
        Button(action: {
            if media != nil {
                isPresented.toggle()
            }
        }) {
            ZStack {
                ImageView(url: imageUrl)
                    .whenRedacted { $0.hidden() }
                Rectangle()
                    .fill(Color(white: 0, opacity: 0.4))
                Text(title)
                    .foregroundColor(.white)
                    .padding()
            }
            .frame(width: Self.cellSize.width, height: Self.cellSize.height)
        }
        .fullScreenCover(isPresented: $isPresented, content: {
            PlayerView(media: media!)
        })
        .buttonStyle(CardButtonStyle())
        .padding(.top, 20)
        .padding(.bottom, 80)
        .redacted(reason: redactionReason)
    }
}
