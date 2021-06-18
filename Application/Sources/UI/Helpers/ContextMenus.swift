//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import UIKit

enum ContextMenu {
    private static func watchLaterAction(for media: SRGMedia, in viewController: UIViewController) -> UIAction? {
        func title(for action: WatchLaterAction) -> String {
            if action == .add {
                if media.mediaType == .audio {
                    return NSLocalizedString("Listen later", comment: "Context menu action to add an audio to the later list")
                }
                else {
                    return NSLocalizedString("Watch later", comment: "Context menu action to add a video to the later list")
                }
            }
            else {
                return NSLocalizedString("Delete from \"Later\"", comment: "Context menu action to delete a media from the later list")
            }
        }
        
        func image(for action: WatchLaterAction) -> UIImage {
            return (action == .add) ? UIImage(named: "watch_later_full-22")! : UIImage(named: "watch_later-22")!
        }
        
        let action = WatchLaterAllowedActionForMediaMetadata(media)
        guard action != .none else { return nil }
        
        let menuAction = UIAction(title: title(for: action), image: image(for: action)) { _ in
            WatchLaterToggleMediaMetadata(media) { added, error in
                guard error == nil else { return }
                
                let labels = SRGAnalyticsHiddenEventLabels()
                labels.source = AnalyticsSource.peekMenu.rawValue
                labels.value = media.urn
                
                let name = added ? AnalyticsTitle.watchLaterAdd.rawValue : AnalyticsTitle.watchLaterRemove.rawValue
                SRGAnalyticsTracker.shared.trackHiddenEvent(withName: name, labels: labels)
                
                Banner.showWatchLaterAdded(added, forItemWithName: media.title, in: viewController)
            }
        }
        if action == .remove {
            menuAction.attributes = .destructive
        }
        return menuAction
    }
    
    private static func moreEpisodesAction(for media: SRGMedia, in viewController: UIViewController) -> UIAction? {
        guard !ApplicationConfiguration.shared.areShowsUnavailable,
              let show = media.show,
              let navigationController = viewController.navigationController else { return nil }
        return UIAction(title: NSLocalizedString("More episodes", comment: "Context menu action to open more episodes associated with a media"),
                        image: UIImage(named: "episodes-22")) { _ in
            let showViewController = ShowViewController(show: show, fromPushNotification: false)
            navigationController.pushViewController(showViewController, animated: true)
        }
    }
    
    private static func menu(for media: SRGMedia, in viewController: UIViewController) -> UIMenu {
        return UIMenu(title: "", children: [
            watchLaterAction(for: media, in: viewController),
            moreEpisodesAction(for: media, in: viewController)
        ].compactMap { $0 })
    }
    
    private static func menu(for show: SRGShow, in viewController: UIViewController) -> UIMenu {
        var elements: [UIMenuElement] = []
        return UIMenu(title: "", children: elements)
    }
    
    static func configuration(for item: Content.Item, in viewController: UIViewController) -> UIContextMenuConfiguration {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            switch item {
            case let .media(media):
                return menu(for: media, in: viewController)
            case let .show(show):
                return menu(for: show, in: viewController)
            default:
                return nil
            }
        }
    }
}
