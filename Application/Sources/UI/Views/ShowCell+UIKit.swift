//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

extension UICollectionView {
    private static let defaultShowCellRegistration: UICollectionView.CellRegistration<HostCollectionViewCell<ShowCell>, SRGShow> = {
        return UICollectionView.CellRegistration { cell, _, show in
            cell.content = ShowCell(show: show, style: .standard, imageType: .default)
        }
    }()
    
    private static let posterShowCellRegistration: UICollectionView.CellRegistration<HostCollectionViewCell<ShowCell>, SRGShow> = {
        return UICollectionView.CellRegistration { cell, _, show in
            cell.content = ShowCell(show: show, style: .standard, imageType: .showPoster)
        }
    }()
    
    @objc func showCell(for indexPath: IndexPath, show: SRGShow, imageType: SRGImageType) -> UICollectionViewCell {
        if imageType == .showPoster {
            return dequeueConfiguredReusableCell(using: Self.posterShowCellRegistration, for: indexPath, item: show)
        }
        else {
            return dequeueConfiguredReusableCell(using: Self.defaultShowCellRegistration, for: indexPath, item: show)
        }
    }
}
