//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct ProfileSectionHeaderView: View {
    let title: String
    
    var body: some View {
        HeaderView(title: title, subtitle: nil, hasDetailDisclosure: false)
            .padding(.horizontal, 16)
    }
}

struct ProfileSectionHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSectionHeaderView(title: "Title")
            .previewLayout(.sizeThatFits)
    }
}
