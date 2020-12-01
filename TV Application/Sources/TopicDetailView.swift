//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct TopicDetailView: View {
    @ObservedObject var model: TopicDetailModel
    
    static let headerHeight: CGFloat = 60
    
    enum Section: Hashable {
        case medias
        case information
    }
    
    enum Content: Hashable {
        case loading
        case message(_ message: String, iconName: String)
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
            let item = Content.message(friendlyMessage(for: error), iconName: "error-90")
            return [Row(section: .information, items: [item])]
        case let .loaded(medias: medias):
            if !medias.isEmpty {
                return [Row(section: .medias, items: medias.map { .media($0) })]
            }
            else {
                let item = Content.message(NSLocalizedString("No results", comment: "Default text displayed when no results are available"), iconName: "media-90")
                return [Row(section: .information, items: [item])]
            }
        }
    }
    
    private static func boundarySupplementaryItems() -> [NSCollectionLayoutBoundarySupplementaryItem] {
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(Self.headerHeight)),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .topLeading
        )
        return [header]
    }
    
    private static func layoutGroup(for section: Section, geometry: GeometryProxy) -> NSCollectionLayoutGroup {
        switch section {
        case .medias:
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(420))
            return NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 4)
        case .information:
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let height = geometry.size.height - Self.headerHeight
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(height))
            return NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        }
    }
    
    private static func layoutSection(for section: Section, geometry: GeometryProxy) -> NSCollectionLayoutSection {
        let section = NSCollectionLayoutSection(group: layoutGroup(for: section, geometry: geometry))
        section.boundarySupplementaryItems = Self.boundarySupplementaryItems()
        return section
    }
    
    var body: some View {
        GeometryReader { geometry in
            CollectionView(rows: rows) { _, _ in
                return Self.layoutSection(for: rows.first!.section, geometry: geometry)
            } cell: { _, item in
                switch item {
                case .loading:
                    ProgressView()
                case let .message(text, iconName):
                    VStack(spacing: 20) {
                        Image(iconName)
                        Text(text)
                            .srgFont(.body)
                            .lineLimit(2)
                            .foregroundColor(.white)
                    }
                    .padding()
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
            }
            .onDisappear {
                model.cancelRefresh()
            }
            .onResume {
                model.refresh()
            }
            .tracked(with: analyticsPageTitle, levels: analyticsPageLevels)
        }
    }
    
    private struct HeaderView: View {
        let title: String
        
        var body: some View {
            Text(title)
                .srgFont(.title2)
                .foregroundColor(.white)
                .opacity(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

extension TopicDetailView {
    private var analyticsPageTitle: String {
        return AnalyticsPageTitle.latest.rawValue
    }
    
    private var analyticsPageLevels: [String] {
        return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.video.rawValue, self.model.topic.title]
    }
}
