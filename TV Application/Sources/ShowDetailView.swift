//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SwiftUI

struct ShowDetailView: View {
    static let headerHeight: CGFloat = 400
    
    @ObservedObject var model: ShowDetailModel
    
    init(show: SRGShow) {
        model = ShowDetailModel(show: show)
    }
    
    var body: some View {
        Group {
            if model.loading && model.rows.isEmpty {
                LoadingView()
            }
            else if let error = model.error {
                ErrorView(error: error)
            }
            else {
                DataView(model: model)
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
        .onResume {
            model.refresh()
        }
    }
}

extension ShowDetailView {
    private struct DataView: View {
        @ObservedObject var model: ShowDetailModel
        
        private static func boundarySupplementaryItems() -> [NSCollectionLayoutBoundarySupplementaryItem] {
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(300)),
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .topLeading
            )
            return [header]
        }
        
        private static func layoutSection() -> NSCollectionLayoutSection {
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(headerHeight))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 4)
            
            let section = NSCollectionLayoutSection(group: group)
            section.boundarySupplementaryItems = Self.boundarySupplementaryItems()
            return section
        }
        
        var body: some View {
            CollectionView(rows: model.rows) { sectionIndex, layoutEnvironment in
                return Self.layoutSection()
            } cell: { indexPath, item in
                MediaCell(media: item)
                    .onAppear {
                        model.loadNextPage(from: item)
                    }
            } supplementaryView: { kind, indexPath in
                HeaderView(show: model.show)
            }
        }
    }
    
    private struct LoadingView: View {
        var body: some View {
            ProgressView()
        }
    }
    
    private struct ErrorView: View {
        let error: Error
        
        var body: some View {
            Text(friendlyMessage(for: error))
                .srgFont(.regular, size: .headline)
                .lineLimit(2)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

extension ShowDetailView {
    private struct HeaderView: View {
        let show: SRGShow
        
        private var imageUrl: URL? {
            return show.imageURL(for: .width, withValue: SizeForImageScale(.medium).width, type: .default)
        }
        
        var body: some View {
            GeometryReader { geometry in
                FocusableRegion {
                    HStack(alignment: .top) {
                        ImageView(url: imageUrl)
                            .frame(width: geometry.size.height * 16 / 9)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(show.title)
                                .srgFont(.bold, size: .title)
                                .lineLimit(3)
                                .foregroundColor(.white)
                            if let lead = show.lead {
                                Text(lead)
                                    .srgFont(.regular, size: .headline)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                        }
                        
                        Spacer()
                        
                        LabeledButton(icon: "favorite-22", label: NSLocalizedString("Add to favorites", comment:"Add to favorites button label")) {
                            /* Toggle Favorite state */
                        }
                    }
                }
            }
        }
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
