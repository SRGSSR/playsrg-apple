//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import NukeUI
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
    let style: FeaturedContentCell<Self>.Style
    let label: String?

    var isPlaceholder: Bool {
        media == nil
    }

    var introduction: String? {
        guard let media else { return nil }
        return MediaDescription.subtitle(for: media, style: mediaDescriptionStyle)
    }

    var title: String? {
        guard let media else { return nil }
        return MediaDescription.title(for: media)
    }

    var summary: String? {
        guard let media else { return nil }
        return MediaDescription.summary(for: media)
    }

    var accessibilityLabel: String? {
        guard let media else { return nil }
        return MediaDescription.cellAccessibilityLabel(for: media)
    }

    var accessibilityHint: String? {
        PlaySRGAccessibilityLocalizedString("Plays the content.", comment: "Featured media hint")
    }

    private var mediaDescriptionStyle: MediaDescription.Style {
        switch style {
        case .show:
            .show
        case .date:
            .date
        }
    }

    func visualView() -> some View {
        MediaVisualView(media: media, size: .medium)
    }

    #if os(tvOS)
        func action() {
            if let media {
                navigateToMedia(media)
            }
        }
    #endif
}

struct FeaturedShowContent: FeaturedContent {
    let show: SRGShow?
    let label: String?

    var isPlaceholder: Bool {
        show == nil
    }

    var introduction: String? {
        nil
    }

    var title: String? {
        show?.title
    }

    var summary: String? {
        show?.play_summary?.compacted
    }

    var accessibilityLabel: String? {
        show?.title
    }

    var accessibilityHint: String? {
        PlaySRGAccessibilityLocalizedString("Opens show details.", comment: "Featured show hint")
    }

    func visualView() -> some View {
        ShowVisualView(show: show, size: .medium)
    }

    #if os(tvOS)
        func action() {
            if let show {
                navigateToShow(show)
            }
        }
    #endif
}
