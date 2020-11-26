//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SwiftUI

struct ShowDetailView: View {
    @ObservedObject var model: ShowDetailModel
    
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
    
    init(show: SRGShow) {
        model = ShowDetailModel(show: show)
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
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(500)),
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
                MediaCell(media: media)
                    .onAppear {
                        model.loadNextPage(from: media)
                    }
            }
        } supplementaryView: { _, _ in
            HeaderView(show: model.show)
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
    
    private struct VisualView: View {
        let show: SRGShow
        
        private static let height: CGFloat = 300
        
        private var imageUrl: URL? {
            return show.imageURL(for: .width, withValue: SizeForImageScale(.medium).width, type: .default)
        }
        
        var body: some View {
            HStack(alignment: .top) {
                ImageView(url: imageUrl)
                    .frame(width: Self.height * 16 / 9, height: Self.height)
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(show.title)
                        .srgFont(.bold, size: .title)
                        .lineLimit(3)
                        .foregroundColor(.white)
                    if let broadcastInformationMessage = show.broadcastInformation?.message {
                        Badge(text: broadcastInformationMessage, color: Color(.play_gray))
                    }
                    if let lead = show.lead {
                        Text(lead)
                            .srgFont(.regular, size: .headline)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                Spacer()
                #if DEBUG
                LabeledButton(icon: "favorite-22", label: NSLocalizedString("Favorite", comment:"Show favorite button label")) {
                    /* Toggle Favorite state */
                }
                .padding(.leading, 100)
                #else
                Spacer()
                    .frame(width: 120)
                    .padding(.leading, 100)
                #endif
            }
        }
    }
    
    private struct HeaderView: View {
        let show: SRGShow
        
        var body: some View {
            GeometryReader { geometry in
                FocusableRegion {
                    VStack {
                        VisualView(show: show)
                        Spacer()
                        Text(NSLocalizedString("Available episodes", comment: "Title of the episode list header in show detail view"))
                            .srgFont(.medium, size: .title)
                            .foregroundColor(.white)
                            .opacity(0.8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
}

extension ShowDetailView {
    private var analyticsPageTitle: String {
        return self.model.show.title
    }
    
    private var analyticsPageLevels: [String] {
        let level1: AnalyticsPageLevel = self.model.show.transmission == .radio ? .audio : .video
        return [AnalyticsPageLevel.play.rawValue, level1.rawValue, AnalyticsPageLevel.show.rawValue]
    }
}

struct ShowDetailView_Previews: PreviewProvider {
    
    static var showPreview: SRGShow {
        let asset = NSDataAsset(name: "show-srf-tv")!
        let jsonData = try! JSONSerialization.jsonObject(with: asset.data, options: []) as? [String: Any]
        
        return try! MTLJSONAdapter(modelClass: SRGShow.self)?.model(fromJSONDictionary: jsonData) as! SRGShow
    }
    
    static var previews: some View {
        ShowDetailView(show: showPreview)
            .previewDisplayName("SRF show")
    }
}
