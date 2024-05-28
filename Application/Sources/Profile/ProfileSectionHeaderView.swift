//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct ProfileSectionHeaderView: View {
    let title: String
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            Text(title)
                .srgFont(.H1)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundColor(.srgGrayD2)
        .padding(.all, 16)
    }
}

struct ProfileSectionHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSectionHeaderView(title: "Title")
            .previewLayout(.fixed(width: 320, height: 64))
    }
}
