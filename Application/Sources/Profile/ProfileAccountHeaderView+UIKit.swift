//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

extension UITableView {
    final class ProfileAccountTableViewHeaderView: HostView<ProfileAccountHeaderView> {
        override func willMove(toWindow _: UIWindow?) {
            content = ProfileAccountHeaderView()
        }
    }

    @objc func profileAccountHeaderView() -> UIView {
        ProfileAccountTableViewHeaderView(
            frame: CGRect(origin: .zero, size: ProfileAccountHeaderView.size()),
            leadingAnchorConstant: LayoutMargin * 2,
            trailingAnchorConstant: -LayoutMargin * 2
        )
    }
}
