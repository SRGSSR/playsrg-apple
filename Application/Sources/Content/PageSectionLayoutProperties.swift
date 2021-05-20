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
    
    var isGridLayout: Bool {
        switch layout {
        case .mediaGrid, .showGrid, .liveMediaGrid:
            return true
        default:
            return false
        }
    }
    
    private var sectionPageLayout: PageModel.SectionLayout {
        switch layout {
        case .mediaSwimlane, .mediaGrid:
            return .mediaGrid
        case .showSwimlane, .showGrid:
            return .showGrid
        case .liveMediaSwimlane, .liveMediaGrid:
            return .liveMediaGrid
        case .hero:
            return .mediaGrid
        case .topicSelector:
            return .showGrid
        default:
            return layout
        }
    }
}
