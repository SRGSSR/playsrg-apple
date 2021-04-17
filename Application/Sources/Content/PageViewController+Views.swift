//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

extension PageViewController {
    struct PageMediaCell: View {
        let media: SRGMedia?
        let section: PageModel.Section
        
        var body: some View {
            if section.properties.layout == .hero {
                #if os(tvOS)
                FeaturedMediaCell(media: media, layout: .hero)
                #else
                MediaCell(media: media, style: .show, layout: .vertical)
                #endif
            }
            else if section.properties.layout == .highlight {
                #if os(tvOS)
                FeaturedMediaCell(media: media, layout: .hero)
                #else
                MediaCell(media: media, style: .show, layout: .vertical)
                #endif
            }
            else if section.properties.presentationType == .livestreams {
                if let media = media, media.contentType == .livestream || media.contentType == .scheduledLivestream {
                    LiveMediaCell(media: media)
                }
                else {
                    MediaCell(media: media, layout: .vertical)
                }
            }
            else {
                MediaCell(media: media, style: .show, layout: .vertical)
            }
        }
    }

    struct PageShowCell: View {
        let show: SRGShow?
        let section: PageModel.Section
        
        var body: some View {
            if section.properties.layout == .hero {
                #if os(tvOS)
                FeaturedShowCell(show: show, layout: .hero)
                #else
                ShowCell(show: show)
                #endif
            }
            else if section.properties.layout == .highlight {
                #if os(tvOS)
                FeaturedShowCell(show: show, layout: .highlight)
                #else
                ShowCell(show: show)
                #endif
            }
            else {
                ShowCell(show: show)
            }
        }
    }

    struct PageCell: View {
        let item: PageModel.Item
        
        var body: some View {
            switch item {
            case let .mediaPlaceholder(index: _, section: section):
                PageMediaCell(media: nil, section: section)
            case let .media(media, index: _, section: section):
                PageMediaCell(media: media, section: section)
            case let .showPlaceholder(index: _, section: section):
                PageShowCell(show: nil, section: section)
            case let .show(show, index: _, section: section):
                PageShowCell(show: show, section: section)
            case .topicPlaceholder:
                TopicCell(topic: nil)
            case let .topic(topic, index: _, section: _):
                TopicCell(topic: topic)
            #if os(iOS)
            case .showAccess:
                ShowAccessCell()
            #endif
            }
        }
    }
}

extension PageViewController {
    struct PageSectionHeaderView: View {
        let section: PageModel.Section
        let pageTitle: String?
        
        @Accessibility(\.isVoiceOverRunning) private var isVoiceOverRunning
            
        private var accessibilityLabel: String {
            if let summary = section.properties.summary {
                return section.properties.accessibilityTitle + ", " + summary
            }
            else {
                return section.properties.accessibilityTitle
            }
        }
        
        private var accessibilityHint: String {
            return section.properties.canOpenDetailPage ? PlaySRGAccessibilityLocalizedString("Shows all contents.", "Homepage header action hint") : ""
        }
        
        var body: some View {
            if let pageTitle = pageTitle {
                Text(pageTitle)
                    .srgFont(.H1)
                    .foregroundColor(.white)
                    .opacity(0.8)
            }
            VStack(alignment: .leading) {
                if let title = isVoiceOverRunning ? section.properties.accessibilityTitle : section.properties.title {
                    Text(title)
                        .srgFont(.H2)
                        .lineLimit(1)
                }
                if let summary = section.properties.summary {
                    Text(summary)
                        .srgFont(.subtitle)
                        .lineLimit(1)
                        .opacity(0.8)
                }
            }
            .opacity(0.8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .accessibilityElement()
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(accessibilityHint)
            .accessibility(addTraits: .isHeader)
        }
    }
}

extension PageViewController {
    /**
     *  A collection view applying a stronger deceleration rate to horizontally scrollable sections.
     */
    // TODO: Remove if the compositional layout API is further improved (could be added to `UICollectionViewCompositionalLayoutConfiguration`
    //       in the future).
    @available(tvOS, unavailable)
    class DampedCollectionView: UICollectionView {
        override func didAddSubview(_ subview: UIView) {
            super.didAddSubview(subview)
            
            if let scrollView = subview as? UIScrollView {
                Self.applySettings(to: scrollView)
            }
        }
        
        static func applySettings(to scrollView: UIScrollView) {
            guard let scrollViewClass = object_getClass(scrollView) else { return }
            
            scrollView.decelerationRate = .fast
            scrollView.alwaysBounceHorizontal = true
            
            let scrollViewSubclassName = String(cString: class_getName(scrollViewClass)).appending("_IgnoreSafeArea")
            if let viewSubclass = NSClassFromString(scrollViewSubclassName) {
                object_setClass(scrollView, viewSubclass)
            }
            else {
                guard let viewClassNameUtf8 = (scrollViewSubclassName as NSString).utf8String else { return }
                guard let scrollViewSubclass = objc_allocateClassPair(scrollViewClass, viewClassNameUtf8, 0) else { return }
                
                if let decelerationRateMethod = class_getInstanceMethod(UIScrollView.self, #selector(setter: UIScrollView.decelerationRate)) {
                    let setDecelerationRate: @convention(block) (AnyObject, UIScrollView.DecelerationRate) -> Void = { _, _ in
                        // Do nothing, only prevent value changes
                    }
                    class_addMethod(scrollViewSubclass, #selector(setter: UIScrollView.decelerationRate), imp_implementationWithBlock(setDecelerationRate), method_getTypeEncoding(decelerationRateMethod))
                }
                
                if let alwaysBounceHorizontalMethod = class_getInstanceMethod(UIScrollView.self, #selector(setter: UIScrollView.alwaysBounceHorizontal)) {
                    let setAlwaysBounceHorizontal: @convention(block) (AnyObject, Bool) -> Void = { _, _ in
                        // Do nothing, only prevent value changes
                    }
                    class_addMethod(scrollViewSubclass, #selector(setter: UIScrollView.alwaysBounceHorizontal), imp_implementationWithBlock(setAlwaysBounceHorizontal), method_getTypeEncoding(alwaysBounceHorizontalMethod))
                }
                
                objc_registerClassPair(scrollViewSubclass)
                object_setClass(scrollView, scrollViewSubclass)
            }
        }
    }
}
