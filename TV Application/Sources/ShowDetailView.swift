//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAnalyticsSwiftUI
import SRGAppearance
import SRGIdentity
import SwiftUI

struct ShowDetailView: View {
    @ObservedObject var model: ShowDetailModel
    
    static let headerHeight: CGFloat = 450
    
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
    
    init(show: SRGShow) {
        model = ShowDetailModel(show: show)
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
    
    private static func header() -> [NSCollectionLayoutBoundarySupplementaryItem] {
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(Self.headerHeight)),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .topLeading
        )
        return [header]
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
            section.boundarySupplementaryItems = Self.header()
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
                    MediaCell(media: media)
                        .onAppear {
                            model.loadNextPage(from: media)
                        }
                }
            } supplementaryView: { _, _ in
                HeaderView(show: model.show)
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
    
    private struct VisualView: View {
        let show: SRGShow
        
        @State var isFavorite: Bool = false
        @State var favoriteRemovalAlertDisplayed = false
        
        private static let height: CGFloat = 300
        
        private var imageUrl: URL? {
            return show.imageURL(for: .width, withValue: SizeForImageScale(.medium).width, type: .default)
        }
        
        private func toggleFavorite() {
            FavoritesToggleShow(show)
            isFavorite = FavoritesContainsShow(show)
            
            let analyticsTitle = isFavorite ? AnalyticsTitle.favoriteAdd : AnalyticsTitle.favoriteRemove
            let labels = SRGAnalyticsHiddenEventLabels()
            labels.source = AnalyticsSource.button.rawValue
            labels.value = show.urn
            SRGAnalyticsTracker.shared.trackHiddenEvent(withName: analyticsTitle.rawValue, labels: labels)
        }
        
        private func toggleFavoriteAction() {
            if FavoritesIsSubscribedToShow(show) {
                favoriteRemovalAlertDisplayed = true
            }
            else {
                toggleFavorite()
            }
        }
        
        private func favoriteRemovalAlert() -> Alert {
            let primaryButton = Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "Title of a cancel button"))) {}
            let secondaryButton = Alert.Button.destructive(Text(NSLocalizedString("Remove", comment: "Title of a removal button"))) {
                toggleFavorite()
            }
            return Alert(title: Text(NSLocalizedString("Remove from favorites", comment: "Title of the confirmation pop-up displayed when the user is about to remove a favorite")),
                         message: Text(NSLocalizedString("This will remove the favorite and notifications subscription on all devices connected to your account.", comment: "Confirmation message displayed when a logged in user is about to remove a favorite")),
                         primaryButton: primaryButton,
                         secondaryButton: secondaryButton)
        }
        
        var body: some View {
            HStack(alignment: .top) {
                ImageView(url: imageUrl)
                    .frame(width: Self.height * 16 / 9, height: Self.height)
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(show.title)
                        .srgFont(.title1)
                        .lineLimit(3)
                        .foregroundColor(.white)
                    if let broadcastInformationMessage = show.broadcastInformation?.message {
                        Badge(text: broadcastInformationMessage, color: Color(.play_gray))
                    }
                    if let lead = show.lead {
                        Text(lead)
                            .srgFont(.subtitle)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                Spacer()
                LabeledButton(icon: isFavorite ? "favorite_full-22" : "favorite-22",
                              label: isFavorite ? NSLocalizedString("Favorites", comment: "Label displayed in the show view when a show has been favorited") : NSLocalizedString("Add to favorites", comment: "Label displayed in the show view when a show can be favorited"),
                              accessibilityLabel: isFavorite ? PlaySRGAccessibilityLocalizedString("Remove from favorites", "Favorite label in the show view when a show has been favorited") : PlaySRGAccessibilityLocalizedString("Add to favorites", "Favorite label in the show view when a show can be favorited"),
                              action: toggleFavoriteAction)
                    .padding(.leading, 100)
                    .alert(isPresented: $favoriteRemovalAlertDisplayed, content: favoriteRemovalAlert)
            }
            .onAppear {
                isFavorite = FavoritesContainsShow(show)
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
