//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//
import UIKit

@objc protocol NotificationSettable {
    var notification: UserNotification? { get set }
}

extension UITableView {
    final class NotificationTableViewCell: HostTableViewCell<NotificationCell>, NotificationSettable {
        var notification: UserNotification? {
            didSet {
                if let notification = notification {
                    content = NotificationCell(notification: notification)
                }
                else {
                    content = nil
                }
            }
        }
    }
    
    private static let reuseIdentifier = "NotificationCell"
    
    @objc func registerReusableNotificationCell() {
        register(NotificationTableViewCell.self, forCellReuseIdentifier: Self.reuseIdentifier)
    }
    
    @objc func dequeueReusableNotificationCell(for indexPath: IndexPath) -> UITableViewCell & NotificationSettable {
        return dequeueReusableCell(withIdentifier: Self.reuseIdentifier, for: indexPath) as! NotificationTableViewCell
    }
}
