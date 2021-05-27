//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct SectionShowHeaderView: View {
    let section: SectionModel.Section
    let show: SRGShow?
    
    var body: some View {
        VStack {
            ImageView(url: show?.imageUrl(for: .large))
                .aspectRatio(SectionShowHeaderViewSize.aspectRatio, contentMode: .fit)
        }
    }
}

class SectionShowHeaderViewSize: NSObject {
    fileprivate static let aspectRatio: CGFloat = 16 / 9
}

struct SectionShowHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        SectionShowHeaderView(section: SectionModel.Section(.content(Mock.contentSection())), show: Mock.show())
            .previewLayout(.fixed(width: 600, height: 400))
    }
}
