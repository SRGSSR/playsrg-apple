//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel

protocol PageSectionLayoutProperties {
    var layout: PageModel.SectionLayout { get }
    var canOpenDetailPage: Bool { get }
}

extension PageSectionLayoutProperties {
    var accessibilityHint: String? {
        if canOpenDetailPage {
            return PlaySRGAccessibilityLocalizedString("Shows all contents.", "Homepage header action hint")
        }
        else {
            return nil
        }
    }
        
    var hasSwimlaneLayout: Bool {
        switch layout {
        case .mediaSwimlane, .showSwimlane:
            return true
        default:
            return false
        }
    }
    
    var hasGridLayout: Bool {
        switch layout {
        case .mediaGrid, .showGrid, .liveMediaGrid:
            return true
        default:
            return false
        }
    }
}
