//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct MigrationBanner: View {
    var body: some View {
        Color.red
            .padding(.top, 40)
    }

    static func size() -> NSCollectionLayoutSize {
        NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(300))
    }
}
