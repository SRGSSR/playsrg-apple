//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import SwiftUI

// TODO: Should be replaced with tvOS cells, but we need to have code compile for both platforms (e.g. have tvOS modifiers
//       which do nothing on iOS to avoid too much preprocessor)
struct MediaCell2: View {
    let media: SRGMedia?
    
    var body: some View {
        Text(media?.title ?? "<media>")
    }
}

struct ShowCell2: View {
    let show: SRGShow?
    
    var body: some View {
        Text(show?.title ?? "<show>")
    }
}
