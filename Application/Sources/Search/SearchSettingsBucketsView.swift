//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

typealias SearchSettingsBucket = SearchSettingsViewModel.SearchSettingsBucket

// MARK: View

struct SearchSettingsBucketsView: View {
    @State var buckets: [SearchSettingsBucket]
    
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
    
    private var filteredBuckets: [SearchSettingsBucket] {
        guard !searchText.isEmpty else { return buckets }
        return buckets.filter { $0.title.contains(searchText) }
    }
    
    @State private var searchText = ""
    @State private var selection = Set<String>()
    
    @FirstResponder private var firstResponder
    
    var body: some View {
        List {
            SearchBarView(text: $searchText, placeholder: NSLocalizedString("Search", comment: "Search shortcut label"))
            ForEach(filteredBuckets) {
                BucketCell(bucket: $0, selectedUrns: $selectedUrns)
            }
        }
        .listStyle(.plain)
        .simultaneousGesture(
            DragGesture().onChanged { _ in
                firstResponder.sendAction(#selector(UIResponder.resignFirstResponder))
            }
        )
        .srgFont(.body)
        .navigationTitle(title)
    }
    
    private struct BucketCell: View {
        let bucket: SearchSettingsBucket
        
        @Binding var selectedUrns: Set<String>
                
        var body: some View {
            Button(action: select) {
                HStack {
                    Text(bucket.title)
                        .accessibilityHidden(true)
                    Spacer()
                    if selectedUrns.contains(bucket.id) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .foregroundColor(.primary)
        }
        
        private func select() {
            if selectedUrns.contains(bucket.id) {
                selectedUrns.remove(bucket.id)
            }
            else {
                selectedUrns.update(with: bucket.id)
            }
        }
    }
}
