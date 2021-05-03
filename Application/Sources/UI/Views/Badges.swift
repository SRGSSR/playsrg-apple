//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

/// Behavior: h-hug, v-hug
struct Badge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .srgFont(.label)
            .lineLimit(1)
            .foregroundColor(.white)
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(color)
            .cornerRadius(4)
    }
}

/// Behavior: h-hug, v-hug
struct SubtitlesBadge: View {
    var body: some View {
        Text("ST")
            .srgFont(.caption)
            .lineLimit(1)
            .foregroundColor(.black)
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(Color(.play_whiteBadge))
            .cornerRadius(4)
    }
}

/// Behavior: h-hug, v-hug
struct AudioDescriptionBadge: View {
    var body: some View {
        Image("audio_description-14")
            .colorInvert()
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(Color(.play_whiteBadge))
            .cornerRadius(4)
    }
}

struct Badges_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Badge(text: "Badge", color: .orange)
            SubtitlesBadge()
            AudioDescriptionBadge()
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
