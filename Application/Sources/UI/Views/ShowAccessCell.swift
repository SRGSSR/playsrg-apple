//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: Contract

@objc protocol ShowAccessCellActions: AnyObject {
    func openShowAZ()
    func openShowByDate()
}

// MARK: View

/// Behavior: h-exp, v-exp
struct ShowAccessCell: View {
    let style: Style
    
    private var showAZButtonProperties: ButtonProperties {
        return ButtonProperties(
            icon: "a_to_z",
            label: NSLocalizedString("A to Z", comment: "Show A-Z short button title"),
            accessibilityLabel: PlaySRGAccessibilityLocalizedString("A to Z shows", comment: "Show A-Z button label")
        )
    }
    
    private var showByDateButtonProperties: ButtonProperties {
        switch style {
        case .calendar:
            return ButtonProperties(
                icon: "calendar",
                label: NSLocalizedString("By date", comment: "Show by date short button title"),
                accessibilityLabel: PlaySRGAccessibilityLocalizedString("Shows by date", comment: "Show by date button label")
            )
        case .programGuide:
            return ButtonProperties(
                icon: "tv_guide",
                label: NSLocalizedString("TV guide", comment: "TV guide short button title")
            )
        }
    }
    
    var body: some View {
        ResponderChain { firstResponder in
            HStack {
                ExpandedButton(icon: showAZButtonProperties.icon, label: showAZButtonProperties.label, accessibilityLabel: showAZButtonProperties.accessibilityLabel) {
                    firstResponder.sendAction(#selector(ShowAccessCellActions.openShowAZ))
                }
                ExpandedButton(icon: showByDateButtonProperties.icon, label: showByDateButtonProperties.label, accessibilityLabel: showByDateButtonProperties.accessibilityLabel) {
                    firstResponder.sendAction(#selector(ShowAccessCellActions.openShowByDate))
                }
            }
        }
    }
}

// MARK: Types

extension ShowAccessCell {
    enum Style {
        case calendar
        case programGuide
    }
    
    private struct ButtonProperties {
        let icon: String
        let label: String
        let accessibilityLabel: String?
        
        init(icon: String, label: String, accessibilityLabel: String? = nil) {
            self.icon = icon
            self.label = label
            self.accessibilityLabel = accessibilityLabel
        }
    }
}

// MARK: Size

final class ShowAccessCellSize: NSObject {
    @objc static func fullWidth(layoutWidth: CGFloat) -> NSCollectionLayoutSize {
        return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(38))
    }
}

// MARK: Preview

struct ShowAccessCell_Previews: PreviewProvider {
    private static let size = ShowAccessCellSize.fullWidth(layoutWidth: 800).previewSize
    
    static var previews: some View {
        Group {
            ShowAccessCell(style: .calendar)
            ShowAccessCell(style: .programGuide)
        }
        .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
