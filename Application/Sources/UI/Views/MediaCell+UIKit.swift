//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

extension UICollectionView {
    private static let mediaCellRegistration: UICollectionView.CellRegistration<HostCollectionViewCell<MediaCell>, SRGMedia> = {
        return UICollectionView.CellRegistration { cell, _, media in
            cell.content = MediaCell(media: media)
        }
    }()
    
    @objc func mediaCell(for indexPath: IndexPath, media: SRGMedia) -> UICollectionViewCell {
        return dequeueConfiguredReusableCell(using: Self.mediaCellRegistration, for: indexPath, item: media)
    }
}

@objc protocol MediaSettable {
    var media: SRGMedia? { get set }
}

extension UITableView {
    class MediaTableViewCell: HostTableViewCell<MediaCell>, MediaSettable {
        var media: SRGMedia? {
            willSet {
                content = MediaCell(media: newValue, layout: .horizontal)
            }
        }
    }
    
    private static let reuseIdentifier = "MediaCell"
    
    @objc func registerReusableMediaCell() {
        register(MediaTableViewCell.self, forCellReuseIdentifier: Self.reuseIdentifier)
    }
    
    @objc func dequeueReusableMediaCell(for indexPath: IndexPath) -> UITableViewCell & MediaSettable {
        return dequeueReusableCell(withIdentifier: Self.reuseIdentifier, for: indexPath) as! MediaTableViewCell
    }
}
