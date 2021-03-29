//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAnalyticsSwiftUI
import SwiftUI

struct HomeView: View {
    @ObservedObject var model: PageModel
    
    private static func swimlaneLayoutSection(for section: PageModel.RowSection) -> NSCollectionLayoutSection {
        func layoutGroupSize(for section: PageModel.RowSection) -> NSCollectionLayoutSize {
            switch section.layout {
            case .hero:
                return NSCollectionLayoutSize(widthDimension: .absolute(1740), heightDimension: .absolute(680))
            case .highlighted:
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
        
        func contentInsets(for section: PageModel.RowSection) -> NSDirectionalEdgeInsets {
            switch section.layout {
            case .topicSelector:
                return NSDirectionalEdgeInsets(top: 80, leading: 0, bottom: 80, trailing: 0)
            default:
                return NSDirectionalEdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)
            }
        }
        
        func continuousGroupLeadingBoundary(for section: PageModel.RowSection) -> UICollectionLayoutSectionOrthogonalScrollingBehavior {
            switch section.layout {
            case .hero:
                return .continuous
            case .highlighted:
                return .none
            default:
                return .continuousGroupLeadingBoundary
            }
        }
        
        func header(for section: PageModel.RowSection) -> [NSCollectionLayoutBoundarySupplementaryItem] {
            guard let headerHeight = swimlaneSectionHeaderHeight(for: section) else { return [] }
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
        layoutSection.boundarySupplementaryItems = header(for: section)
        return layoutSection
    }
    
    private static func swimlaneSectionHeaderHeight(for section: PageModel.RowSection) -> CGFloat? {
        guard section.title != nil else { return nil }
        if let summary = section.summary, !summary.isEmpty {
            return 140
        }
        else {
            return 100
        }
    }
    
    var body: some View {
        CollectionView(rows: model.rows) { _, section, _ in
            return Self.swimlaneLayoutSection(for: section)
        } cell: { _, _, item in
            Cell(item: item)
        } supplementaryView: { _, _, section, _ in
            HeaderView(rowId: section)
        }
        .synchronizeTabBarScrolling()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
        .tracked(withTitle: analyticsPageTitle, levels: analyticsPageLevels)
    }
    
    private struct Cell: View {
        let item: PageModel.RowItem
        
        var body: some View {
            switch item.content {
            case let .media(media):
                if item.section.layout == .hero {
                    FeaturedMediaCell(media: media, layout: .hero)
                }
                else if item.section.layout == .highlighted {
                    FeaturedMediaCell(media: media, layout: .highlighted)
                }
                else if item.section.isLive {
                    if media.contentType == .livestream || media.contentType == .scheduledLivestream {
                        LiveMediaCell(media: media)
                    }
                    else {
                        MediaCell(media: media, style: .date) {
                            navigateToMedia(media, play: true)
                        }
                    }
                }
                else {
                    MediaCell(media: media, style: .show)
                }
            case .mediaPlaceholder:
                if item.section.layout == .hero {
                    FeaturedMediaCell(media: nil, layout: .hero)
                }
                else if item.section.layout == .highlighted {
                    FeaturedMediaCell(media: nil, layout: .highlighted)
                }
                else {
                    MediaCell(media: nil, style: .show)
                }
            case let .show(show):
                if item.section.layout == .hero {
                    FeaturedShowCell(show: show, layout: .hero)
                }
                else if item.section.layout == .highlighted {
                    FeaturedShowCell(show: show, layout: .highlighted)
                }
                else {
                    ShowCell(show: show)
                }
            case .showPlaceholder:
                if item.section.layout == .hero {
                    FeaturedShowCell(show: nil, layout: .hero)
                }
                else if item.section.layout == .highlighted {
                    FeaturedShowCell(show: nil, layout: .highlighted)
                }
                else {
                    ShowCell(show: nil)
                }
            case let .topic(topic):
                TopicCell(topic: topic)
            case .topicPlaceholder:
                TopicCell(topic: nil)
            }
        }
    }
    
    private struct HeaderView: View {
        let section: PageModel.RowSection
        
        var body: some View {
            VStack(alignment: .leading) {
                if let title = section.title {
                    Text(title)
                        .srgFont(.title2)
                        .lineLimit(1)
                }
                if let summary = section.summary {
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
