//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SwiftUI

struct ShowDetailView: View {
    let show: SRGShow
    
    @ObservedObject var model: ShowDetailModel
    
    init(show: SRGShow) {
        self.show = show
        model = ShowDetailModel(show: show)
    }
    
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
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(400))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 4)
        
        let section = NSCollectionLayoutSection(group: group)
        section.boundarySupplementaryItems = Self.boundarySupplementaryItems()
        return section
    }
    
    var body: some View {
        VStack(spacing: 20) {
            CollectionView(rows: model.rows) { sectionIndex, layoutEnvironment in
                return Self.layoutSection()
            } cell: { indexPath, item in
                MediaCell(media: item)
            } supplementaryView: { kind, indexPath in
                DescriptionView(show: show)
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
    private struct DescriptionView: View {
        let show: SRGShow
        
        private var imageUrl: URL? {
            return show.imageURL(for: .width, withValue: SizeForImageScale(.medium).width, type: .default)
        }
        
        var body: some View {
            GeometryReader { geometry in
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

