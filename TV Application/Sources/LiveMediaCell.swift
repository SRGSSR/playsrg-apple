//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//
import SwiftUI

struct LiveMediaCell: View {
    let media: SRGMedia?
    
    private var title: String {
        return media?.title ?? "empty"
    }
    
    var body: some View {
        Text(title)
    }
}
