//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

struct SearchSettingsBucketsView: View {
    let title: String
    
    @State var buckets: [Bucket]        // Capture the initial bucket list as state so that it never gets modified afterwards
    @Binding var selectedUrns: Set<String>
    @State private var searchText = ""
    
    @FirstResponder private var firstResponder
    
    private var filteredBuckets: [Bucket] {
        guard !searchText.isEmpty else { return buckets }
        return buckets.filter { $0.title.contains(searchText) }
    }
    
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
        let bucket: Bucket
        
        @Binding var selectedUrns: Set<String>
                
        var body: some View {
            Button(action: toggleSelection) {
                HStack {
                    Text(bucket.title)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .foregroundColor(.primary)
            .accessibilityElement(label: bucket.accessibilityLabel, hint: nil, traits: accessibilityTraits)
        }
        
        private var isSelected: Bool {
            return selectedUrns.contains(bucket.urn)
        }
        
        private var accessibilityTraits: AccessibilityTraits {
            return isSelected ? [.isButton, .isSelected] : .isButton
        }
        
        private func toggleSelection() {
            if isSelected {
                selectedUrns.remove(bucket.id)
            }
            else {
                selectedUrns.update(with: bucket.id)
            }
        }
    }
}
