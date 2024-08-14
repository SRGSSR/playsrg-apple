//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SRGDataProviderModel
import SwiftUI

// MARK: Contract

@objc protocol ShowAccessCellActions: AnyObject {
    func openShowAZ(sender: Any?, event: ShowAccessEvent?)
    func openShowByDate(sender: Any?, event: ShowAccessEvent?)
}

class ShowAccessEvent: UIEvent {
    let transmission: SRGTransmission

    init(transmission: SRGTransmission) {
        self.transmission = transmission
        super.init()
    }

    override init() {
        fatalError("init() is not available")
    }
}

// MARK: View

/// Behavior: h-exp, v-exp
struct ShowAccessCell: View, PrimaryColorSettable {
    let style: Style

    var primaryColor: Color = .srgGrayD2

    @FirstResponder private var firstResponder

    private var showAZButtonProperties: ButtonProperties {
        ButtonProperties(
            icon: .aToZ,
            label: NSLocalizedString("A to Z", comment: "Show A-Z short button title"),
            accessibilityLabel: PlaySRGAccessibilityLocalizedString("A to Z shows", comment: "Show A-Z button label")
        )
    }

    private var showByDateButtonProperties: ButtonProperties {
        switch style {
        case .calendar:
            ButtonProperties(
                icon: .calendar,
                label: NSLocalizedString("By date", comment: "Show by date short button title"),
                accessibilityLabel: PlaySRGAccessibilityLocalizedString("Shows by date", comment: "Show by date button label")
            )
        case .programGuide:
            ButtonProperties(
                icon: .tvGuide,
                label: NSLocalizedString("TV guide", comment: "TV guide short button title")
            )
        }
    }

    private var transmission: SRGTransmission {
        switch style {
        case .programGuide:
            .TV
        case .calendar:
            .radio
        }
    }

    var body: some View {
        HStack {
            ExpandingButton(icon: showAZButtonProperties.icon, label: showAZButtonProperties.label, accessibilityLabel: showAZButtonProperties.accessibilityLabel) {
                firstResponder.sendAction(#selector(ShowAccessCellActions.openShowAZ), for: ShowAccessEvent(transmission: transmission))
            }
            .primaryColor(primaryColor)
            ExpandingButton(icon: showByDateButtonProperties.icon, label: showByDateButtonProperties.label, accessibilityLabel: showByDateButtonProperties.accessibilityLabel) {
                firstResponder.sendAction(#selector(ShowAccessCellActions.openShowByDate), for: ShowAccessEvent(transmission: transmission))
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
        NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(38))
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
