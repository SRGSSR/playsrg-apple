//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct ShowCell: View {
    let show: SRGShow?
    
    private var imageUrl: URL? {
        return show?.imageURL(for: .width, withValue: SizeForImageScale(.small).width, type: .default)
    }
    
    private var redactionReason: RedactionReasons {
        return show == nil ? .placeholder : .init()
    }
    
    private var accessibilityLabel: String {
        return show?.title ?? ""
    }
    
    var body: some View {
        GeometryReader { geometry in
            #if os(tvOS)
            LabeledCardButton(action: {
                if let show = show {
                    navigateToShow(show)
                }
            }) {
                ImageView(url: imageUrl)
                    .frame(width: geometry.size.width, height: geometry.size.width * 9 /  16)
                    .accessibilityElement()
                    .accessibilityLabel(accessibilityLabel)
                    .accessibility(addTraits: .isButton)
            } label: {
                DescriptionView(show: show)
                    .frame(width: geometry.size.width, alignment: .leading)
            }
            #else
            VStack {
                ImageView(url: imageUrl)
                    .frame(width: geometry.size.width, height: geometry.size.width * 9 /  16)
                DescriptionView(show: show)
                    .padding(.bottom, 5)
                    .padding(.horizontal, 8)
                    .frame(width: geometry.size.width, alignment: .leading)
            }
            .background(Color(.play_cardGrayBackground))
            .cornerRadius(LayoutStandardViewCornerRadius)
            .accessibilityElement()
            .accessibilityLabel(accessibilityLabel)
            #endif
        }
        .redacted(reason: redactionReason)
    }
    
    private struct DescriptionView: View {
        let show: SRGShow?
        
        private var title: String {
            guard let show = show else { return String(repeating: " ", count: .random(in: 10..<20)) }
            return show.title
        }
        
        var body: some View {
            Text(title)
                .srgFont(.subtitle)
        }
    }
}

extension UICollectionView {
    private static let showCellRegistration: UICollectionView.CellRegistration<HostCollectionViewCell<ShowCell>, SRGShow> = {
        return UICollectionView.CellRegistration { cell, _, show in
            cell.content = ShowCell(show: show)
        }
    }()
    
    @objc func showCell(for indexPath: IndexPath, show: SRGShow) -> UICollectionViewCell {
            return dequeueConfiguredReusableCell(using: Self.showCellRegistration, for: indexPath, item: show)
    }
}

struct ShowCell_Previews: PreviewProvider {
    static var showPreview: SRGShow {
        let asset = NSDataAsset(name: "show-srf-tv")!
        let jsonData = try! JSONSerialization.jsonObject(with: asset.data, options: []) as? [String: Any]
        
        return try! MTLJSONAdapter(modelClass: SRGShow.self)?.model(fromJSONDictionary: jsonData) as! SRGShow
    }
    
    static var previews: some View {
        Group {
            ShowCell(show: showPreview)
                .previewLayout(.fixed(width: 375, height: 211))
                .previewDisplayName("SRF show")
        }
    }
}
