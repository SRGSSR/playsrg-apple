//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAnalyticsSwiftUI
import SwiftUI

struct TopicDetailView: View {
    @ObservedObject var model: TopicDetailModel
    
    static let headerHeight: CGFloat = 60
    
    enum Section: Hashable {
        case mostPopularMedias
        case latestMedias
        case information
    }
    
    enum Content: Hashable {
        case loading
        case message(_ message: String, iconName: String)
        case media(_ media: SRGMedia, section: Section)
    }
    
    typealias Row = CollectionRow<Section, Content>
    
    init(topic: SRGTopic) {
        model = TopicDetailModel(topic: topic)
    }
    
    private var rows: [Row] {
        switch model.state {
        case .loading:
            return [Row(section: .information, items: [.loading])]
        case let .failed(error: error):
            let item = Content.message(friendlyMessage(for: error), iconName: "error-90")
            return [Row(section: .information, items: [item])]
        case let .loaded(mostPopularMedias: mostPopularMedias, latestMedias: latestMedias):
            if mostPopularMedias.isEmpty && latestMedias.isEmpty {
                let item = Content.message(NSLocalizedString("No results", comment: "Default text displayed when no results are available"), iconName: "media-90")
                return [Row(section: .information, items: [item])]
            }
            
            var rows = [Row]()
            if !mostPopularMedias.isEmpty {
                rows.append(Row(section: .mostPopularMedias, items: mostPopularMedias.map { .media($0, section: .mostPopularMedias) }))
            }
            if !latestMedias.isEmpty {
                rows.append(Row(section: .latestMedias, items: latestMedias.map { .media($0, section: .latestMedias) }))
            }
            return rows
        }
    }
    
    private static func header(withHeight height: CGFloat = Self.headerHeight) -> [NSCollectionLayoutBoundarySupplementaryItem] {
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(height)),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .topLeading
        )
        return [header]
    }
    
    private static func layoutSection(for section: Section, geometry: GeometryProxy) -> NSCollectionLayoutSection {
        switch section {
        case .mostPopularMedias:
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(1740), heightDimension: .absolute(680))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            section.interGroupSpacing = 40
            section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)
            section.boundarySupplementaryItems = Self.header()
            return section
        case .latestMedias:
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(380))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 4)
            group.interItemSpacing = .fixed(40)
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)
            section.interGroupSpacing = 40
            section.boundarySupplementaryItems = Self.header(withHeight: 100)
            return section
        case .information:
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let height = geometry.size.height - Self.headerHeight
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(height))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.boundarySupplementaryItems = Self.header()
            return section
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            CollectionView(rows: rows) { sectionIndex, _ in
                let section = rows[sectionIndex].section
                return Self.layoutSection(for: section, geometry: geometry)
            } cell: { _, item in
                switch item {
                case .loading:
                    ActivityIndicator()
                case let .message(text, iconName):
                    VStack(spacing: 20) {
                        Image(iconName)
                        Text(text)
                            .srgFont(.body)
                            .lineLimit(2)
                            .foregroundColor(.white)
                    }
                    .opacity(0.8)
                    .padding()
                case let .media(media, section):
                    switch section {
                    case .latestMedias:
                        MediaCell(media: media, style: .show)
                            .onAppear {
                                model.loadNextPage(from: media)
                            }
                    default:
                        HeroMediaCell(media: media)
                    }
                }
            } supplementaryView: { _, indexPath in
                if rows.count > 1 {
                    let section = rows[indexPath.section].section
                    switch section {
                    case .latestMedias:
                        HeaderView(title: NSLocalizedString("Latest videos", comment: "Title label used to present the latest videos"))
                    default:
                        TitleView(title: model.topic.title)
                    }
                }
                else {
                    TitleView(title: model.topic.title)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.play_black))
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                model.refresh()
            }
            .onDisappear {
                model.cancelRefresh()
            }
            .onWake {
                model.refresh()
            }
            .tracked(withTitle: analyticsPageTitle, levels: analyticsPageLevels)
        }
    }
    
    private struct TitleView: View {
        let title: String
        
        var body: some View {
            Text(title)
                .srgFont(.title1)
                .foregroundColor(.white)
                .opacity(0.8)
        }
    }
    
    private struct HeaderView: View {
        let title: String
        
        var body: some View {
            Text(title)
                .srgFont(.title2)
                .foregroundColor(.white)
                .opacity(0.8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
    }
}

extension TopicDetailView {
    private var analyticsPageTitle: String {
        return self.model.topic.title
    }
    
    private var analyticsPageLevels: [String] {
        return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.video.rawValue]
    }
}
