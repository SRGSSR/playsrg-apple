//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

struct SearchSettingsBucketsView: View {
    @State var buckets: [SearchSettingsViewModel.SearchSettingsBucket]
    
    enum BucketType: String {
        case topics
        case shows
    }
    
    let bucketType: BucketType
    
    @Binding var selectedUrns: Set<String>
    
    private var title: String {
        switch bucketType {
        case .topics:
            return NSLocalizedString("Topics", comment: "Search setting")
        case .shows:
            return NSLocalizedString("Shows", comment: "Search setting")
        }
    }
    
    private var filteredBuckets: [SearchSettingsViewModel.SearchSettingsBucket] {
        guard !searchText.isEmpty else { return buckets }
        return buckets.filter { $0.title.contains(searchText) }
    }
    
    @State private var searchText = ""
    @State private var selection = Set<String>()
    
    var body: some View {
        VStack(spacing: 0) {
            SearchBarView(text: $searchText, placeholder: NSLocalizedString("Search", comment: "Search shortcut label"))
                .padding(.horizontal, 8)
            List(filteredBuckets, selection: $selection) {
                Text($0.title)
            }
            .srgFont(.body)
            .navigationTitle(title)
            .environment(\.editMode, .constant(.active))
            .onAppear {
                selection = selectedUrns
            }
            .onChange(of: selection) { newValue in
                selectedUrns = newValue
            }
        }
    }
}
