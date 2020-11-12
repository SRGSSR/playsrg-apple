//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SwiftUI

struct ShowDetailView: View {
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
    
    private struct DataView: View {
        @ObservedObject var model: ShowDetailModel
        
        private static func boundarySupplementaryItems() -> [NSCollectionLayoutBoundarySupplementaryItem] {
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(500)),
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .topLeading
            )
            return [header]
        }
        
        private static func layoutSection() -> NSCollectionLayoutSection {
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(400))
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
                    .padding([.leading, .trailing], 20)
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
                LabeledButton(icon: "favorite-22", label: NSLocalizedString("Favorite", comment:"Show favorite button label")) {
                    /* Toggle Favorite state */
                }
                .padding(.leading, 100)
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
                        Text(NSLocalizedString("Available episodes", comment: "Title of the show episode list header"))
                            .srgFont(.medium, size: .title)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
