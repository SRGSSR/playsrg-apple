//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import UIKit

class TableLoadMoreFooterView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear

        let loadingImageView = UIImageView.play_loadingImageView(withTintColor: .srgGrayD2)
        addSubview(loadingImageView)

        loadingImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
