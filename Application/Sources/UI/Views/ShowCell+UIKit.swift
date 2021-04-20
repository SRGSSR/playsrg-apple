//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

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
