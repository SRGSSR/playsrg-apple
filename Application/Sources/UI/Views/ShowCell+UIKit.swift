//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

extension UICollectionView {
    private static var defaultShowCellRegistration: UICollectionView.CellRegistration<HostCollectionViewCell<ShowCell>, SRGShow>!
    private static var posterShowCellRegistration: UICollectionView.CellRegistration<HostCollectionViewCell<ShowCell>, SRGShow>!
    
    @objc static func registerShowCell() {
        if defaultShowCellRegistration == nil {
            defaultShowCellRegistration = UICollectionView.CellRegistration { cell, _, show in
                cell.content = ShowCell(show: show, style: .standard, imageVariant: .default)
            }
        }
        if posterShowCellRegistration == nil {
            posterShowCellRegistration = UICollectionView.CellRegistration { cell, _, show in
                cell.content = ShowCell(show: show, style: .standard, imageVariant: .poster)
            }
        }
    }
    
    @objc func showCell(for indexPath: IndexPath, show: SRGShow, imageVariant: SRGImageVariant) -> UICollectionViewCell {
        if imageVariant == .poster {
            return dequeueConfiguredReusableCell(using: Self.posterShowCellRegistration, for: indexPath, item: show)
        }
        else {
            return dequeueConfiguredReusableCell(using: Self.defaultShowCellRegistration, for: indexPath, item: show)
        }
    }
}
