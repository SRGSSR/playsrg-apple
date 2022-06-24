//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import SwiftUI

// MARK: View

struct SearchSettingsBucketsView: View {
    let title: String
    
    @State var buckets: [SRGItemBucket]        // Capture the initial bucket list as state so that it never gets modified afterwards
    @Binding var selectedUrns: Set<String>
    @State private var searchText = ""
    
    @FirstResponder private var firstResponder
    
    private var filteredBuckets: [SRGItemBucket] {
        guard !searchText.isEmpty else { return buckets }
        return buckets.filter { $0.title.contains(searchText) }
    }
    
    var body: some View {
        List {
            SearchBarView(text: $searchText, placeholder: NSLocalizedString("Search", comment: "Search shortcut label"))
            ForEach(filteredBuckets, id: \.urn) {
                SearchSettingsBucketCell(bucket: $0, selectedUrns: $selectedUrns)
            }
        }
        .listStyle(.plain)
        .simultaneousGesture(
            DragGesture().onChanged { _ in
                firstResponder.sendAction(#selector(UIResponder.resignFirstResponder))
            }
        )
        .navigationTitle(title)
    }
}
