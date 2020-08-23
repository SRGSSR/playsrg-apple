//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import SwiftUI

struct HeroMediaCell: View {
    let media: SRGMedia?
    
    private var imageUrl: URL? {
        return media?.imageURL(for: .width, withValue: 1000, type: .default)
    }
    
    private var redactionReason: RedactionReasons {
        return media == nil ? .placeholder : .init()
    }
    
    var body: some View {
        ZStack {
            ImageView(url: imageUrl, contentMode: .fill)
                .whenRedacted { $0.hidden() }
            Rectangle()
                .fill(Color(white: 0, opacity: 0.4))
            DescriptionView(media: media)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(60)
        }
        .cornerRadius(10)
        .redacted(reason: redactionReason)
    }
}

struct DescriptionView: View {
    let media: SRGMedia?
    
    private var title: String {
        guard let media = media else { return String(repeating: " ", count: .random(in: 15..<30)) }
        return media.title
    }
    
    private var subtitle: String {
        guard let media = media else { return String(repeating: " ", count: .random(in: 12..<18)) }
        return DateFormatters.dateAndTime(for: media.date)
    }
    
    var body: some View {
        VStack {
            Text(title)
                .font(.title2)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            Text(subtitle)
                .font(.body)
                .lineLimit(1)
                .foregroundColor(.white)
        }
    }
}
