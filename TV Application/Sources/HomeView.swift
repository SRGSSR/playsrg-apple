//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var model: HomeModel
    
    private struct Cell: View {
        let item: HomeRowItem
        
        private static func isHeroAppearance(for item: HomeRowItem) -> Bool {
            if case let .tvTrending(appearance: appearance) = item.rowId, appearance == .hero {
                return true
            }
            else {
                return false
            }
        }
        
        var body: some View {
            switch item.content {
            case let .media(media):
                if Self.isHeroAppearance(for: item) {
                    HeroMediaCell(media: media)
                }
                else {
                    MediaCell(media: media)
                }
            case .mediaPlaceholder:
                if Self.isHeroAppearance(for: item) {
                    HeroMediaCell(media: nil)
                }
                else {
                    MediaCell(media: nil)
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
    
    private struct SupplementaryView: View {
        let rowId: HomeRowId
        let kind: String
        
        var body: some View {
            if kind == UICollectionView.elementKindSectionHeader {
                VStack(alignment: .leading) {
                    if let title = rowId.title {
                        Text(title)
                            .srgFont(.medium, size: .title)
                            .lineLimit(1)
                    }
                    if let lead = rowId.lead {
                        Text(lead)
                            .srgFont(.light, size: .headline)
                            .lineLimit(1)
                            .opacity(0.8)
                    }
                }
                .opacity(0.8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
    }
    
    private static func swimlaneLayoutSection(for rowId: HomeRowId) -> NSCollectionLayoutSection {
        func layoutGroupSize(for rowId: HomeRowId) -> NSCollectionLayoutSize {
            switch rowId {
            case let .tvTrending(appearance: appearance):
                if appearance == .hero {
                    return NSCollectionLayoutSize(widthDimension: .absolute(1740), heightDimension: .absolute(680))
                }
                else {
                    return NSCollectionLayoutSize(widthDimension: .absolute(375), heightDimension: .absolute(211))
                }
            case .tvTopicsAccess:
                return NSCollectionLayoutSize(widthDimension: .absolute(250), heightDimension: .absolute(141))
            case .radioAllShows:
                return NSCollectionLayoutSize(widthDimension: .absolute(375), heightDimension: .absolute(211))
            default:
                return NSCollectionLayoutSize(widthDimension: .absolute(375), heightDimension: .absolute(340))
            }
        }
        
        func contentInsets(for rowId: HomeRowId) -> NSDirectionalEdgeInsets {
            switch rowId {
            case .tvTopicsAccess:
                return NSDirectionalEdgeInsets(top: 80, leading: 0, bottom: 80, trailing: 0)
            default:
                return NSDirectionalEdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)
            }
        }
        
        func boundarySupplementaryItems(for rowId: HomeRowId) -> [NSCollectionLayoutBoundarySupplementaryItem] {
            guard let headerHeight = swimlaneSectionHeaderHeight(for: rowId) else { return [] }
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(headerHeight)),
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .topLeading
            )
            return [header]
        }
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = layoutGroupSize(for: rowId)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 40
        section.contentInsets = contentInsets(for: rowId)
        section.boundarySupplementaryItems = boundarySupplementaryItems(for: rowId)
        return section
    }
    
    private static func swimlaneSectionHeaderHeight(for rowId: HomeRowId) -> CGFloat? {
        guard rowId.title != nil else { return nil }
        if let lead = rowId.lead, !lead.isEmpty {
            return 140
        }
        else {
            return 100
        }
    }
    
    var body: some View {
        CollectionView(rows: model.rows) { sectionIndex, layoutEnvironment in
            let rowId = model.rows[sectionIndex].section
            return Self.swimlaneLayoutSection(for: rowId)
        } cell: { _, item in
            Cell(item: item)
        } supplementaryView: { kind, indexPath in
            let rowId = model.rows[indexPath.section].section
            SupplementaryView(rowId: rowId, kind: kind)
        }
        .synchronizeParentTabScrolling()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
    }
}
