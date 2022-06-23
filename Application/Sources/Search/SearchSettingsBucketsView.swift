//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

struct SearchSettingsBucketsView: View {
    let buckets: [SearchSettingsViewModel.SearchSettingsBucket]
    
    enum BucketType: String {
        case topics
        case shows
    }
    
    let bucketType: BucketType
    
    @Binding var selections: Set<String>

    @State private var displayedBuckets: [SearchSettingsViewModel.SearchSettingsBucket] = []
    @State private var multiSelection = Set<String>()
    
    private var title: String {
        switch bucketType {
        case .topics:
            return NSLocalizedString("Topics", comment: "Search setting")
        case .shows:
            return NSLocalizedString("Shows", comment: "Search setting")
        }
    }
    
    var body: some View {
        List(displayedBuckets, selection: $multiSelection) {
            Text($0.title)
        }
        .srgFont(.body)
        .navigationTitle(title)
        .environment(\.editMode, .constant(.active))
        .onAppear {
            displayedBuckets = buckets
            multiSelection = selections
        }
        .onChange(of: multiSelection) { newValue in
            selections = newValue
        }
    }
}
