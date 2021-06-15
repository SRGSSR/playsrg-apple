//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

protocol FeaturedContent {
    associatedtype Content: View
    
    var isPlaceholder: Bool { get }
    
    var introduction: String? { get }
    var title: String? { get }
    var summary: String? { get }
    var label: String? { get }
    
    var accessibilityLabel: String? { get }
    var accessibilityHint: String? { get }
    
    func visualView() -> Content
    
    #if os(tvOS)
    func action()
    #endif
}

struct FeaturedMediaContent: FeaturedContent {
    let media: SRGMedia?
    let label: String?
    
    var isPlaceholder: Bool {
        return media == nil
    }
    
    var introduction: String? {
        return MediaDescription.subtitle(for: media, style: .show)
    }
    
    var title: String? {
        return MediaDescription.title(for: media, style: .show)
    }
    
    var summary: String? {
        return MediaDescription.summary(for: media)
    }
    
    var accessibilityLabel: String? {
        return MediaDescription.accessibilityLabel(for: media)
    }
    
    var accessibilityHint: String? {
        return PlaySRGAccessibilityLocalizedString("Plays the content.", "Featured media hint")
    }
    
    func visualView() -> some View {
        return MediaVisualView(media: media, scale: .large)
    }
    
    #if os(tvOS)
    func action() {
        if let media = media {
            navigateToMedia(media)
        }
    }
    #endif
}

struct FeaturedShowContent: FeaturedContent {
    let show: SRGShow?
    let label: String?
    
    var isPlaceholder: Bool {
        return show == nil
    }
    
    var introduction: String? {
        return nil
    }
    
    var title: String? {
        return show?.title
    }
    
    var summary: String? {
        return show?.summary
    }
    
    var accessibilityLabel: String? {
        return show?.title
    }
    
    var accessibilityHint: String? {
        return PlaySRGAccessibilityLocalizedString("Opens show details.", "Featured show hint")
    }
    
    func visualView() -> some View {
        return ImageView(url: show?.imageUrl(for: .large))
    }
    
    #if os(tvOS)
    func action() {
        if let show = show {
            navigateToShow(show)
        }
    }
    #endif
}
