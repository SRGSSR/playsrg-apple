//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// TODO: Somehow make searchController.searchControllerObservedScrollView = scrollView possible for SwiftUI views
//       (in particular our CollectionView)
struct SearchResultsView: View {
    @ObservedObject var model: SearchResultsModel
    
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
    
    private static func layoutSection(for section: Section, geometry: GeometryProxy) -> NSCollectionLayoutSection {
        switch section {
        case .medias:
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(380))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 4)
            group.interItemSpacing = .fixed(40)
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)
            section.interGroupSpacing = 40
            return section
        case .information:
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(geometry.size.height))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            return section
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            CollectionView(rows: rows) { _, _ in
                return Self.layoutSection(for: rows.first!.section, geometry: geometry)
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
                case let .media(media):
                    MediaCell(media: media, style: .show)
                        .onAppear {
                            model.loadNextPage(from: media)
                        }
                }
            } supplementaryView: { _, _ in
                
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
        }
    }
}
