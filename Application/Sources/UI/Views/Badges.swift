//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import SwiftUI

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
