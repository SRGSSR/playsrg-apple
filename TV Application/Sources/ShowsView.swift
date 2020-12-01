//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SwiftUI

struct ShowsView: View {
    @ObservedObject var model: ShowsModel
    
    static let headerHeight: CGFloat = 100
    
    enum Section: Hashable {
        case shows(character: Character)
        case information
    }
    
    enum Content: Hashable {
        case loading
        case message(_ message: String, iconName: String)
        case show(_ show: SRGShow)
    }
    
    typealias Row = CollectionRow<Section, Content>
    
    init() {
        model = ShowsModel()
    }
    
    private var rows: [Row] {
        switch model.state {
        case .loading:
            return [Row(section: .information, items: [.loading])]
        case let .failed(error: error):
            let item = Content.message(friendlyMessage(for: error), iconName: "error-90")
            return [Row(section: .information, items: [item])]
        case let .loaded(alphabeticalShows: alphabeticalShows):
            if !alphabeticalShows.isEmpty {
                return alphabeticalShows.map { entry in
                    Row(section: .shows(character: entry.character), items: entry.shows.map { .show($0) })
                }
            }
            else {
                let item = Content.message(NSLocalizedString("No results", comment: "Default text displayed when no results are available"), iconName: "media-90")
                return [Row(section: .information, items: [item])]
            }
        }
    }
    
    private static func boundarySupplementaryItems() -> [NSCollectionLayoutBoundarySupplementaryItem] {
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(100)),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .topLeading
        )
        return [header]
    }
    
    private static func layoutGroup(for section: Section, geometry: GeometryProxy) -> NSCollectionLayoutGroup {
        switch section {
        case .shows:
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(350))
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
                case let .show(show):
                    ShowCell(show: show)
                }
            } supplementaryView: { _, indexPath in
                switch model.state {
                case .loading, .failed:
                    Rectangle()
                        .fill(Color.clear)
                case let .loaded(alphabeticalShows: alphabeticalShows):
                    HeaderView(character: alphabeticalShows[indexPath.section].character)
                        .padding([.leading, .trailing], 20)
                }
            }
            .synchronizeParentTabScrolling()
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
        let character: Character
        
        var body: some View {
            GeometryReader { geometry in
                Text(String(character))
                    .srgFont(.title2)
                    .lineLimit(1)
                    .foregroundColor(.white)
                    .opacity(0.8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
    }
}

extension ShowsView {
    private var analyticsPageTitle: String {
        return AnalyticsPageTitle.showsAZ.rawValue
    }
    
    private var analyticsPageLevels: [String] {
        return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.video.rawValue]
    }
}

struct ShowsView_Previews: PreviewProvider {
    
    static var showPreview: SRGShow {
        let asset = NSDataAsset(name: "show-srf-tv")!
        let jsonData = try! JSONSerialization.jsonObject(with: asset.data, options: []) as? [String: Any]
        
        return try! MTLJSONAdapter(modelClass: SRGShow.self)?.model(fromJSONDictionary: jsonData) as! SRGShow
    }
    
    static var previews: some View {
        ShowsView()
            .previewDisplayName("SRF shows")
    }
}
