//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct TopicDetailView: View {
    @ObservedObject var model: TopicDetailModel
    
    enum Section: Hashable {
        case medias
        case information
    }
    
    enum Content: Hashable {
        case loading
        case message(_ message: String)
        case media(_ media: SRGMedia)
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
            let item = Content.message(friendlyMessage(for: error))
            return [Row(section: .information, items: [item])]
        case let .loaded(medias: medias):
            if !medias.isEmpty {
                return [Row(section: .medias, items: medias.map { .media($0) })]
            }
            else {
                let item = Content.message(NSLocalizedString("No results", comment: "Default text displayed when no results are available"))
                return [Row(section: .information, items: [item])]
            }
        }
    }
    
    private static func boundarySupplementaryItems() -> [NSCollectionLayoutBoundarySupplementaryItem] {
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60)),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .topLeading
        )
        return [header]
    }
    
    private static func layoutGroup(for section: Section) -> NSCollectionLayoutGroup {
        switch section {
        case .medias:
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(400))
            return NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 4)
        case .information:
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(400))
            return NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        }
    }
    
    private static func layoutSection(for section: Section) -> NSCollectionLayoutSection {
        let section = NSCollectionLayoutSection(group: layoutGroup(for: section))
        section.boundarySupplementaryItems = Self.boundarySupplementaryItems()
        return section
    }
    
    var body: some View {
        CollectionView(rows: rows) { _, _ in
            return Self.layoutSection(for: rows.first!.section)
        } cell: { _, item in
            switch item {
            case .loading:
                ProgressView()
            case let .message(message):
                Text(message)
                    .srgFont(.regular, size: .headline)
                    .lineLimit(2)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .media(media):
                MediaCell(media: media, style: .show)
                    .onAppear {
                        model.loadNextPage(from: media)
                    }
            }
        } supplementaryView: { _, _ in
            HeaderView(title: model.topic.title)
                .padding([.leading, .trailing], 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.play_black))
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            model.refresh()
            SRGAnalyticsTracker.shared.trackPageView(title: analyticsPageTitle(), levels: analyticsPageLevels())
        }
        .onDisappear {
            model.cancelRefresh()
        }
        .onResume {
            model.refresh()
            SRGAnalyticsTracker.shared.trackPageView(title: analyticsPageTitle(), levels: analyticsPageLevels())
        }
    }
    
    private func analyticsPageTitle() -> String {
        return AnalyticsPageTitle.latest.rawValue
    }
    
    private func analyticsPageLevels() -> [String] {
        return [ AnalyticsPageLevel.application.rawValue, AnalyticsPageLevel.video.rawValue, self.model.topic.title ]
    }
    
    private struct HeaderView: View {
        let title: String
        
        var body: some View {
            Text(title)
                .srgFont(.medium, size: .title)
                .foregroundColor(.white)
                .opacity(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
