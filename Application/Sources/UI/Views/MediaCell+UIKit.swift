//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

extension UICollectionView {
    private static var mediaCellRegistration: UICollectionView.CellRegistration<HostCollectionViewCell<MediaCell>, SRGMedia>!
    
    @objc static func registerMediaCell() {
        if mediaCellRegistration == nil {
            mediaCellRegistration = UICollectionView.CellRegistration { cell, _, media in
                cell.content = MediaCell(media: media, style: .show)
            }
        }
    }
    
    @objc func mediaCell(for indexPath: IndexPath, media: SRGMedia) -> UICollectionViewCell {
        return dequeueConfiguredReusableCell(using: Self.mediaCellRegistration, for: indexPath, item: media)
    }
}
