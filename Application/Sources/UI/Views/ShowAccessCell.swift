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
struct ShowAccessCell: View, PrimaryColorSettable {
    let style: Style
    
    internal var primaryColor: Color = .srgGrayD2
    
    @FirstResponder private var firstResponder
    
    private var showAZButtonProperties: ButtonProperties {
        return ButtonProperties(
            icon: .aToZ,
            label: NSLocalizedString("A to Z", comment: "Show A-Z short button title"),
            accessibilityLabel: PlaySRGAccessibilityLocalizedString("A to Z shows", comment: "Show A-Z button label")
        )
    }
    
    private var showByDateButtonProperties: ButtonProperties {
        switch style {
        case .calendar:
            return ButtonProperties(
                icon: .calendar,
                label: NSLocalizedString("By date", comment: "Show by date short button title"),
                accessibilityLabel: PlaySRGAccessibilityLocalizedString("Shows by date", comment: "Show by date button label")
            )
        case .programGuide:
            return ButtonProperties(
                icon: .tvGuide,
                label: NSLocalizedString("TV guide", comment: "TV guide short button title")
            )
        }
    }
    
    var body: some View {
        HStack {
            ExpandingButton(icon: showAZButtonProperties.icon, label: showAZButtonProperties.label, accessibilityLabel: showAZButtonProperties.accessibilityLabel) {
                firstResponder.sendAction(#selector(ShowAccessCellActions.openShowAZ))
            }
            .primaryColor(primaryColor)
            ExpandingButton(icon: showByDateButtonProperties.icon, label: showByDateButtonProperties.label, accessibilityLabel: showByDateButtonProperties.accessibilityLabel) {
                firstResponder.sendAction(#selector(ShowAccessCellActions.openShowByDate))
            }
            .primaryColor(primaryColor)
        }
        .responderChain(from: firstResponder)
    }
}

// MARK: Types

extension ShowAccessCell {
    enum Style {
        case calendar
        case programGuide
    }
    
    private struct ButtonProperties {
        let icon: ImageResource
        let label: String
        let accessibilityLabel: String?
        
        init(icon: ImageResource, label: String, accessibilityLabel: String? = nil) {
            self.icon = icon
            self.label = label
            self.accessibilityLabel = accessibilityLabel
        }
    }
}

// MARK: Size

enum ShowAccessCellSize {
    static func fullWidth() -> NSCollectionLayoutSize {
        return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(38))
    }
}

// MARK: Preview

struct ShowAccessCell_Previews: PreviewProvider {
    private static let size = ShowAccessCellSize.fullWidth().previewSize
    
    static var previews: some View {
        Group {
            ShowAccessCell(style: .calendar)
            ShowAccessCell(style: .programGuide)
        }
        .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
