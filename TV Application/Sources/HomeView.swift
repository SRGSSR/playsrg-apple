//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var model: HomeModel
    
    private static func swimlaneSectionLayout(for rowId: HomeRowId) -> NSCollectionLayoutSection {
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
                case .tvShowsAccess, .radioShowsAccess:
                    return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50))
                case .radioAllShows:
                    return NSCollectionLayoutSize(widthDimension: .absolute(375), heightDimension: .absolute(211))
                default:
                    return NSCollectionLayoutSize(widthDimension: .absolute(375), heightDimension: .absolute(340))
            }
        }
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = layoutGroupSize(for: rowId)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 40
        section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)
        return section
    }
    
    private static func lead(for rowId: HomeRowId) -> String? {
        if case let .tvLatestForModule(module, type: _) = rowId {
            return module?.lead
        }
        else {
            return nil
        }
    }
    
    private static func swimlaneSectionHeaderHeight(for rowId: HomeRowId) -> CGFloat? {
        guard rowId.title != nil else { return nil }
        if let lead = Self.lead(for: rowId), !lead.isEmpty {
            return 140
        }
        else {
            return 100
        }
    }
    
    private static func isHeroAppearance(for item: HomeRowItem) -> Bool {
        if case let .tvTrending(appearance: appearance) = item.rowId, appearance == .hero {
            return true
        }
        else {
            return false
        }
    }
    
    var body: some View {
        CollectionView(rows: model.rows) { sectionIndex, layoutEnvironment in
            let rowId = model.rows[sectionIndex].section
            let section = Self.swimlaneSectionLayout(for: rowId)
            
            if let headerHeight = Self.swimlaneSectionHeaderHeight(for: rowId) {
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(headerHeight)),
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .topLeading
                )
                section.boundarySupplementaryItems = [header]
            }
            
            return section
        } cell: { indexPath, item in
            Group {
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
                    case .showsAccess:
                        ShowsAccessCell()
                }
            }
        } supplementaryView: { kind, indexPath in
            if kind == UICollectionView.elementKindSectionHeader {
                VStack(alignment: .leading) {
                    let rowId = model.rows[indexPath.section].section
                    if let title = rowId.title {
                        Text(title)
                            .srgFont(.regular, size: .title)
                            .lineLimit(1)
                    }
                    if let lead = Self.lead(for: rowId) {
                        Text(lead)
                            .srgFont(.regular, size: .headline)
                            .lineLimit(1)
                            .opacity(0.8)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
        .synchronizeParentTabScrolling()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
    }
}
