//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SRGDataProviderModel
import SwiftUI

// MARK: View

struct SearchSettingsBucketCell: View {
    let bucket: SRGItemBucket
    
    @Binding var selectedUrns: Set<String>
            
    var body: some View {
        Button(action: toggleSelection) {
            HStack {
                Text(title)
                    .srgFont(.body)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .foregroundColor(.primary)
        .accessibilityElement(label: accessibilityLabel, hint: nil, traits: accessibilityTraits)
    }
    
    private var title: String {
        return "\(bucket.title) (\(NumberFormatter.localizedString(from: bucket.count as NSNumber, number: .decimal)))"
    }
    
    private var isSelected: Bool {
        return selectedUrns.contains(bucket.urn)
    }
    
    private func toggleSelection() {
        if isSelected {
            selectedUrns.remove(bucket.urn)
        }
        else {
            selectedUrns.update(with: bucket.urn)
        }
    }
}

// MARK: Accessibility

private extension SearchSettingsBucketCell {
    var accessibilityLabel: String? {
        let items = String(format: PlaySRGAccessibilityLocalizedString("%d items", comment: "Number of items aggregated in search"), bucket.count)
        return "\(bucket.title) (\(items))"
    }
    
    var accessibilityTraits: AccessibilityTraits {
        return isSelected ? [.isButton, .isSelected] : .isButton
    }
}
