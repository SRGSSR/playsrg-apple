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
            switch section.properties.layout {
            case .hero:
                FeaturedContentCell(media: media, label: section.properties.label, layout: .hero)
            case .highlight:
                FeaturedContentCell(media: media, label: section.properties.label, layout: .highlight)
            case .liveMediaSwimlane, .liveMediaGrid:
                LiveMediaCell(media: media)
            case .mediaGrid:
                MediaCell(media: media, style: .show)
            default:
                MediaCell(media: media, style: .show, layout: .vertical)
            }
        }
    }

    struct PageShowCell: View {
        let show: SRGShow?
        let section: PageModel.Section
        
        var body: some View {
            switch section.properties.layout {
            case .hero:
                FeaturedContentCell(show: show, label: section.properties.label, layout: .hero)
            case .highlight:
                FeaturedContentCell(show: show, label: section.properties.label, layout: .highlight)
            default:
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
            case let .media(media, section: section):
                PageMediaCell(media: media, section: section)
            case let .showPlaceholder(index: _, section: section):
                PageShowCell(show: nil, section: section)
            case let .show(show, section: section):
                PageShowCell(show: show, section: section)
            case .topicPlaceholder:
                TopicCell(topic: nil)
            case let .topic(topic, section: _):
                TopicCell(topic: topic)
            #if os(iOS)
            case .showAccess:
                ShowAccessCell()
            #endif
            }
        }
    }
}

@objc protocol SectionHeaderViewAction: AnyObject {
    func openSection(sender: Any?, event: UIEvent?)
}

@objc class OpenSectionEvent: UIEvent {
    let section: PageModel.Section
    
    init(section: PageModel.Section) {
        self.section = section
        super.init()
    }
    
    override init() {
        fatalError("init() Mut not be used to initialize OpenSectionEvent")
    }
}

extension PageViewController {
    struct PageSectionHeaderView: View {
        let section: PageModel.Section
        let pageId: PageModel.Id
        
        private static func title(for section: PageModel.Section) -> String? {
            return section.properties.title
        }
        
        private static func subtitle(for section: PageModel.Section) -> String? {
            return section.properties.summary
        }
        
        private static func detailDisclosure(for section: PageModel.Section, on pageId: PageModel.Id) -> Bool {
            if case .section = pageId {
                return false
            }
            else {
                return section.properties.canOpenDetailPage
            }
        }
        
        var body: some View {
            #if os(tvOS)
            HeaderView(title: Self.title(for: section), subtitle: Self.subtitle(for: section), hasDetailDisclosure: false)
                .accessibilityElement()
                .accessibilityOptionalLabel(Self.title(for: section))
                .accessibility(addTraits: .isHeader)
            #else
            ResponderChain { firstResponder in
                Button {
                    firstResponder.sendAction(#selector(SectionHeaderViewAction.openSection(sender:event:)), for: OpenSectionEvent.init(section: section))
                } label: {
                    HeaderView(title: Self.title(for: section), subtitle: Self.subtitle(for: section), hasDetailDisclosure: Self.detailDisclosure(for: section,on: pageId))
                }
                .foregroundColor(.white)
                .disabled(!Self.detailDisclosure(for: section,on: pageId))
                .accessibilityElement()
                .accessibilityOptionalLabel(Self.title(for: section))
                .accessibilityOptionalHint(section.properties.accessibilityHint)
                .accessibility(addTraits: .isHeader)
            }
            #endif
        }
        
        static func size(section: PageModel.Section, horizontalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutSize {
            return HeaderViewSize.recommended(title: title(for: section), subtitle: subtitle(for: section), horizontalSizeClass: horizontalSizeClass)
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
