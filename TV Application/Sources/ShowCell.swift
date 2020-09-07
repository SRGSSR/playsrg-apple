//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import SwiftUI

struct ShowCell: View {
    private struct VisualView: View {
        let show: SRGShow?
        
        private var imageUrl: URL? {
            return show?.imageURL(for: .width, withValue: SizeForImageScale(.small).width, type: .default)
        }
        
        var body: some View {
            ImageView(url: imageUrl)
                .whenRedacted { $0.hidden() }
        }
    }
    
    let show: SRGShow?
    
    private var title: String {
        guard let show = show else { return String(repeating: " ", count: .random(in: 10..<20)) }
        return show.title
    }
    
    private var redactionReason: RedactionReasons {
        return show == nil ? .placeholder : .init()
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                VisualView(show: show)
                    .frame(width: geometry.size.width, height: geometry.size.width * 9 /  16)
                
                Text(title)
                    .srgFont(.regular, size: .subtitle)
                    .frame(width: geometry.size.width, alignment: .leading)
            }
            .redacted(reason: redactionReason)
        }
    }
}
