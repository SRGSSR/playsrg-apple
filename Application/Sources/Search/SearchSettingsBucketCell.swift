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
        let contents = String(format: PlaySRGAccessibilityLocalizedString("%@ results", comment: "Number of results aggregated in search"), PlayAccessibilityNumberFormatter(bucket.count as NSNumber))
        return "\(bucket.title) (\(contents))"
    }
    
    var accessibilityTraits: AccessibilityTraits {
        return isSelected ? [.isButton, .isSelected] : .isButton
    }
}

// MARK: Preview

struct SearchSettingsBucketCell_Previews: PreviewProvider {
    private static let size = CGSize(width: 320, height: 36)
    
    static var previews: some View {
        Group {
            SearchSettingsBucketCell(bucket: Mock.bucket(.standard), selectedUrns: .constant([]))
            SearchSettingsBucketCell(bucket: Mock.bucket(.standard), selectedUrns: .constant([Mock.bucket(.standard).urn]))
            SearchSettingsBucketCell(bucket: Mock.bucket(.overflow), selectedUrns: .constant([Mock.bucket(.overflow).urn]))
        }
        .padding()
        .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
