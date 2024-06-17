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
    let buckets: [SRGItemBucket]

    @Binding var selectedUrns: Set<String>
    @State private var searchText = ""
    @FirstResponder private var firstResponder

    private var filteredBuckets: [SRGItemBucket] {
        guard !searchText.isEmpty else { return buckets }
        return buckets.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            SearchBarView(text: $searchText, placeholder: NSLocalizedString("Search", comment: "Search shortcut label"), autocapitalizationType: .none)
            ForEach(filteredBuckets, id: \.urn) {
                SearchSettingsBucketCell(bucket: $0, selectedUrns: $selectedUrns)
            }
        }
        .animation(.easeInOut, value: buckets)
        .listStyle(.plain)
        .simultaneousGesture(
            DragGesture().onChanged { _ in
                firstResponder.sendAction(#selector(UIResponder.resignFirstResponder))
            }
        )
        .navigationTitle(title)
    }
}
