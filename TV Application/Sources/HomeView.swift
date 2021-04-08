//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAnalyticsSwiftUI
import SwiftUI

struct HomeView: View {
    @ObservedObject var model: PageModel
    
    private static func swimlaneLayoutSection(for section: PageModel.Section, index: Int, pageTitle: String?) -> NSCollectionLayoutSection {
        func layoutGroupSize(for section: PageModel.Section) -> NSCollectionLayoutSize {
            switch section.properties.layout {
            case .hero:
                return NSCollectionLayoutSize(widthDimension: .absolute(1740), heightDimension: .absolute(680))
            case .highlight:
                return NSCollectionLayoutSize(widthDimension: .absolute(1740), heightDimension: .absolute(480))
            case .topicSelector:
                let width = CGFloat(250)
                return NSCollectionLayoutSize(widthDimension: .absolute(width), heightDimension: .absolute(width * 9 / 16))
            case .shows:
                return NSCollectionLayoutSize(widthDimension: .absolute(375), heightDimension: .absolute(260))
            case .medias:
                return NSCollectionLayoutSize(widthDimension: .absolute(375), heightDimension: .absolute(360))
            }
        }
        
        func contentInsets(for section: PageModel.Section) -> NSDirectionalEdgeInsets {
            switch section.properties.layout {
            case .topicSelector:
                return NSDirectionalEdgeInsets(top: 80, leading: 0, bottom: 80, trailing: 0)
            default:
                return NSDirectionalEdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)
            }
        }
        
        func continuousGroupLeadingBoundary(for section: PageModel.Section) -> UICollectionLayoutSectionOrthogonalScrollingBehavior {
            switch section.properties.layout {
            case .hero:
                return .continuous
            case .highlight:
                return .none
            default:
                return .continuousGroupLeadingBoundary
            }
        }
        
        func header(for section: PageModel.Section, index: Int, pageTitle: String?) -> [NSCollectionLayoutBoundarySupplementaryItem] {
            guard let headerHeight = swimlaneSectionHeaderHeight(for: section, index: index, pageTitle: pageTitle) else { return [] }
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(headerHeight)),
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .topLeading
            )
            return [header]
        }
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = layoutGroupSize(for: section)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let layoutSection = NSCollectionLayoutSection(group: group)
        layoutSection.orthogonalScrollingBehavior = continuousGroupLeadingBoundary(for: section)
        layoutSection.interGroupSpacing = 40
        layoutSection.contentInsets = contentInsets(for: section)
        layoutSection.boundarySupplementaryItems = header(for: section, index: index, pageTitle: pageTitle)
        return layoutSection
    }
    
    private static func swimlaneSectionHeaderHeight(for section: PageModel.Section, index: Int, pageTitle: String?) -> CGFloat? {
        if index == 0, section.properties.title == nil, pageTitle == nil {
            return nil
        }
        
        var height: CGFloat = 40
        if let title = section.properties.title, !title.isEmpty {
            height += 60
        }
        if let summary = section.properties.summary, !summary.isEmpty {
            height += 40
        }
        if let pageTitle = pageTitle, !pageTitle.isEmpty {
            height += 60
        }
        return height
    }
    
    var body: some View {
        if case let .loaded(rows: rows) = model.state {
            CollectionView(rows: rows) { sectionIndex, section, _ in
                return Self.swimlaneLayoutSection(for: section, index: sectionIndex, pageTitle: model.title)
            } cell: { _, _, item in
                Cell(item: item)
            } supplementaryView: { _, indexPath, section, _ in
                HeaderView(section: section, pageTitle: indexPath.section == 0 ? model.title : nil)
            }
            .synchronizeTabBarScrolling()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.play_black))
            .ignoresSafeArea(.all)
            .tracked(withTitle: analyticsPageTitle, levels: analyticsPageLevels)
        }
    }
    
    private struct TitleView: View {
        private let title: String?
        
        var body: some View {
            if let title = title {
            Text(title)
                .srgFont(.H1)
                .foregroundColor(.white)
                .opacity(0.8)
            }
        }
    }
    
    private struct Cell: View {
        let item: PageModel.Item
        
        var body: some View {
            switch item {
            case let .media(media, section: section):
                if section.properties.layout == .hero {
                    FeaturedMediaCell(media: media, layout: .hero)
                }
                else if section.properties.layout == .highlight {
                    FeaturedMediaCell(media: media, layout: .highlighted)
                }
                else if section.properties.presentationType == .livestreams {
                    if media.contentType == .livestream || media.contentType == .scheduledLivestream {
                        LiveMediaCell(media: media)
                    }
                    else {
                        MediaCell(media: media) {
                            navigateToMedia(media, play: true)
                        }
                    }
                }
                else {
                    MediaCell(media: media, style: .show)
                }
            case let .mediaPlaceholder(_, section: section):
                if section.properties.layout == .hero {
                    FeaturedMediaCell(media: nil, layout: .hero)
                }
                else if section.properties.layout == .highlight {
                    FeaturedMediaCell(media: nil, layout: .highlighted)
                }
                else {
                    MediaCell(media: nil, style: .show)
                }
            case let .show(show, section: section):
                if section.properties.layout == .hero {
                    FeaturedShowCell(show: show, layout: .hero)
                }
                else if section.properties.layout == .highlight {
                    FeaturedShowCell(show: show, layout: .highlighted)
                }
                else {
                    ShowCell(show: show)
                }
            case let .showPlaceholder(_, section: section):
                if section.properties.layout == .hero {
                    FeaturedShowCell(show: nil, layout: .hero)
                }
                else if section.properties.layout == .highlight {
                    FeaturedShowCell(show: nil, layout: .highlighted)
                }
                else {
                    ShowCell(show: nil)
                }
            case let .topic(topic, section: _):
                TopicCell(topic: topic, usingHostingController: true)
            case .topicPlaceholder:
                TopicCell(topic: nil, usingHostingController: true)
            }
        }
    }
    
    private struct HeaderView: View {
        let section: PageModel.Section
        let pageTitle: String?
        
        var body: some View {
            if let pageTitle = pageTitle {
                Text(pageTitle)
                    .srgFont(.H1)
                    .foregroundColor(.white)
                    .opacity(0.8)
            }
            VStack(alignment: .leading) {
                if let title = section.properties.title {
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
        }
    }
}

extension HomeView {
    private var analyticsPageTitle: String {
        return AnalyticsPageTitle.home.rawValue
    }
    
    private var analyticsPageLevels: [String] {
        switch self.model.id {
        case .video:
            return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.video.rawValue]
        case let .audio(channel):
            return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.audio.rawValue, channel.name]
        case .live:
            return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.live.rawValue]
        case let .topic(topic):
            return [AnalyticsPageLevel.play.rawValue, topic.transmission == .radio ? AnalyticsPageLevel.video.rawValue : AnalyticsPageLevel.video.rawValue, topic.title]
        }
    }
}
