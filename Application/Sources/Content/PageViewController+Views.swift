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
            switch section.layoutProperties.layout {
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
            switch section.layoutProperties.layout {
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
            switch item.wrappedValue {
            case .mediaPlaceholder:
                PageMediaCell(media: nil, section: item.section)
            case let .media(media):
                PageMediaCell(media: media, section: item.section)
            case .showPlaceholder:
                PageShowCell(show: nil, section: item.section)
            case let .show(show), let .showHeader(show):
                PageShowCell(show: show, section: item.section)
            case .topicPlaceholder:
                TopicCell(topic: nil)
            case let .topic(topic):
                TopicCell(topic: topic)
            #if os(iOS)
            case .showAccess:
                ShowAccessCell()
            #endif
            }
        }
    }
}

@objc protocol SectionHeaderViewAction {
    func openSection(sender: Any?, event: UIEvent?)
}

class OpenSectionEvent: UIEvent {
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
        
        var body: some View {
            #if os(tvOS)
            HeaderView(title: Self.title(for: section), subtitle: Self.subtitle(for: section), hasDetailDisclosure: false)
                .accessibilityElement()
                .accessibilityOptionalLabel(Self.title(for: section))
                .accessibility(addTraits: .isHeader)
            #else
            ResponderChain { firstResponder in
                Button {
                    firstResponder.sendAction(#selector(SectionHeaderViewAction.openSection(sender:event:)), for: OpenSectionEvent(section: section))
                } label: {
                    HeaderView(title: Self.title(for: section), subtitle: Self.subtitle(for: section), hasDetailDisclosure: section.layoutProperties.canOpenDetailPage)
                }
                .disabled(!section.layoutProperties.canOpenDetailPage)
                .accessibilityElement()
                .accessibilityOptionalLabel(Self.title(for: section))
                .accessibilityOptionalHint(section.layoutProperties.accessibilityHint)
                .accessibility(addTraits: .isHeader)
            }
            #endif
        }
        
        static func size(section: PageModel.Section, horizontalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutSize {
            return HeaderViewSize.recommended(title: title(for: section), subtitle: subtitle(for: section), horizontalSizeClass: horizontalSizeClass)
        }
    }
}
