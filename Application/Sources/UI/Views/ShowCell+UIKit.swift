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

@objc protocol ShowSettable {
    var show: SRGShow? { get set }
}

extension UITableView {
    class ShowTableViewCell: HostTableViewCell<ShowCell>, ShowSettable {
        var show: SRGShow? {
            willSet {
                content = ShowCell(show: newValue, direction: .horizontal)
            }
        }
    }
    
    private static let reuseIdentifier = "ShowCell"
    
    @objc func registerReusableShowCell() {
        register(ShowTableViewCell.self, forCellReuseIdentifier: Self.reuseIdentifier)
    }
    
    @objc func dequeueReusableShowCell(for indexPath: IndexPath) -> UITableViewCell & ShowSettable {
        return dequeueReusableCell(withIdentifier: Self.reuseIdentifier, for: indexPath) as! ShowTableViewCell
    }
}
