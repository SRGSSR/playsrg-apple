//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAnalyticsSwiftUI
import SwiftUI

struct HomeView: View {
    @ObservedObject var model: PageModel
    
    private static func swimlaneLayoutSection(for section: SRGContentSection) -> NSCollectionLayoutSection {
        func layoutGroupSize(for section: SRGContentSection) -> NSCollectionLayoutSize {
            switch section.presentation.type {
            case .hero, .mediaHighlight, .showHighlight:
                return NSCollectionLayoutSize(widthDimension: .absolute(1740), heightDimension: .absolute(680))
            case .topicSelector:
                let width = CGFloat(250)
                return NSCollectionLayoutSize(widthDimension: .absolute(width), heightDimension: .absolute(width * 9 / 16))
            case .favoriteShows:
                return NSCollectionLayoutSize(widthDimension: .absolute(375), heightDimension: .absolute(260))
            default:
                if section.type == .shows {
                    return NSCollectionLayoutSize(widthDimension: .absolute(375), heightDimension: .absolute(260))
                }
                else {
                    return NSCollectionLayoutSize(widthDimension: .absolute(375), heightDimension: .absolute(360))
                }
            }
        }
        
        func contentInsets(for section: SRGContentSection) -> NSDirectionalEdgeInsets {
            switch section.presentation.type {
            case .topicSelector:
                return NSDirectionalEdgeInsets(top: 80, leading: 0, bottom: 80, trailing: 0)
            default:
                return NSDirectionalEdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)
            }
        }
        
        func continuousGroupLeadingBoundary(for section: SRGContentSection) -> UICollectionLayoutSectionOrthogonalScrollingBehavior {
            if section.presentation.type == .hero {
                return .continuous
            }
            else {
                return .continuousGroupLeadingBoundary
            }
        }
        
        func header(for section: SRGContentSection) -> [NSCollectionLayoutBoundarySupplementaryItem] {
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
    
    private static func swimlaneSectionHeaderHeight(for section: SRGContentSection) -> CGFloat? {
        guard section.presentation.title != nil else { return nil }
        if let summary = section.presentation.summary, !summary.isEmpty {
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
        
        private static func isHeroAppearance(for item: PageModel.RowItem) -> Bool {
            return [.hero, .mediaHighlight, .showHighlight].contains(item.section.presentation.type)
        }
        
        var body: some View {
            switch item.content {
            case let .media(media):
                if Self.isHeroAppearance(for: item) {
                    HeroMediaCell(media: media)
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
                if Self.isHeroAppearance(for: item) {
                    HeroMediaCell(media: nil)
                }
                else {
                    MediaCell(media: nil, style: .show)
                }
            case let .show(show):
                ShowCell(show: show)
            case .showPlaceholder:
                ShowCell(show: nil)
            case let .topic(topic):
                TopicCell(topic: topic)
            case .topicPlaceholder:
                TopicCell(topic: nil)
            }
        }
    }
    
    private struct HeaderView: View {
        let section: SRGContentSection
        
        var body: some View {
            VStack(alignment: .leading) {
                if let title = section.presentation.title {
                    Text(title)
                        .srgFont(.title2)
                        .lineLimit(1)
                }
                if let summary = section.presentation.summary {
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
        }
    }
}
