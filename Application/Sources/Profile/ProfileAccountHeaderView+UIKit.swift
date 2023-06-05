//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

extension UITableView {
    final class ProfileAccountTableViewHeaderView: HostView<ProfileAccountHeaderView> {
        override func willMove(toWindow newWindow: UIWindow?) {
            content = ProfileAccountHeaderView()
        }
    }
    
    @objc func profileAccountHeaderView() -> UIView {
        return ProfileAccountTableViewHeaderView(
            frame: CGRect(origin: .zero, size: ProfileAccountHeaderView.size()),
            leadingAnchorConstant: LayoutMargin * 2,
            trailingAnchorConstant: -LayoutMargin * 2
        )
    }
}
