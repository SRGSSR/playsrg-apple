//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import GoogleCast
import UIKit

@objc class GoogleCastBarButtonItem: UIBarButtonItem {
    private var castButton: GCKUICastButton!
    private weak var navigationBar: UINavigationBar?
    private var tintColorObservation: NSKeyValueObservation?

    // MARK: - Object lifecycle

    @objc init(for navigationBar: UINavigationBar) {
        super.init()
        self.navigationBar = navigationBar

        castButton = GCKUICastButton(frame: CGRect(x: 0.0, y: 0.0, width: 44.0, height: 44.0))
        customView = castButton

        tintColorObservation = navigationBar.observe(\.tintColor, options: [.new]) { [weak self] _, _ in
            self?.updateAppearance()
        }

        updateAppearance()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: - Updates

    private func updateAppearance() {
        castButton.tintColor = navigationBar?.tintColor
    }
}
