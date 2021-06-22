//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import UIKit

enum ContextMenu {
    private class ActivityPopoverPresentationDelegate: NSObject, UIPopoverPresentationControllerDelegate {
        func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
            return .formSheet
        }
    }
    
    private static let popoverPresentationDelegate = ActivityPopoverPresentationDelegate()
    
    private static func shareItem(_ sharingItem: SharingItem, in viewController: UIViewController) {
        let activityViewController = UIActivityViewController(sharingItem: sharingItem, source: .peekMenu, in: viewController)
        activityViewController.modalPresentationStyle = .popover
        
        let popoverPresentationController = activityViewController.popoverPresentationController
        popoverPresentationController?.sourceView = viewController.view
        popoverPresentationController?.delegate = popoverPresentationDelegate
        
        viewController.present(activityViewController, animated: true, completion: nil)
    }
    
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
            return (action == .add) ? UIImage(named: "watch_later_full")! : UIImage(named: "watch_later")!
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
    
    private static func downloadAction(for media: SRGMedia, in viewController: UIViewController) -> UIAction? {
        guard Download.canDownloadMedia(media) else { return nil}
        
        func title(for download: Download?) -> String {
            return download != nil ? NSLocalizedString("Delete from downloads", comment: "Context menu action to delete a media from the downloads") : NSLocalizedString("Add to downloads", comment: "Context menu action to add a media to the downloads")
        }
        
        func image(for download: Download?) -> UIImage {
            return download != nil ? UIImage(named: "downloadable_stop")! : UIImage(named: "downloadable")!
        }
        
        let download = Download(for: media)
        let menuAction = UIAction(title: title(for: download), image: image(for: download)) { _ in
            if let download = download {
                Download.removeDownload(download)
            }
            else {
                Download.add(for: media)
            }
            
            let labels = SRGAnalyticsHiddenEventLabels()
            labels.source = AnalyticsSource.peekMenu.rawValue
            labels.value = media.urn
            
            let name = (download == nil) ? AnalyticsTitle.downloadAdd.rawValue : AnalyticsTitle.downloadRemove.rawValue
            SRGAnalyticsTracker.shared.trackHiddenEvent(withName: name, labels: labels)
            
            Banner.showDownload(download == nil, forItemWithName: media.title, in: viewController)
        }
        if download != nil {
            menuAction.attributes = .destructive
        }
        return menuAction
    }
    
    private static func sharingAction(for media: SRGMedia, in viewController: UIViewController) -> UIAction? {
        guard let sharingItem = SharingItem(for: media, at: CMTime.zero) else { return nil }
        return UIAction(title: NSLocalizedString("Share", comment: "Context menu action to share a media"),
                                  image: UIImage(named: "share")!) { _ in
            shareItem(sharingItem, in: viewController)
        }
    }
    
    private static func moreEpisodesAction(for media: SRGMedia, in viewController: UIViewController) -> UIAction? {
        guard !ApplicationConfiguration.shared.areShowsUnavailable,
              let show = media.show,
              let navigationController = viewController.navigationController else { return nil }
        return UIAction(title: NSLocalizedString("More episodes", comment: "Context menu action to open more episodes associated with a media"),
                        image: UIImage(named: "episodes")) { _ in
            let showViewController = ShowViewController(show: show, fromPushNotification: false)
            navigationController.pushViewController(showViewController, animated: true)
        }
    }
    
    private static func menu(for media: SRGMedia, in viewController: UIViewController) -> UIMenu {
        return UIMenu(title: "", children: [
            watchLaterAction(for: media, in: viewController),
            downloadAction(for: media, in: viewController),
            sharingAction(for: media, in: viewController),
            moreEpisodesAction(for: media, in: viewController)
        ].compactMap { $0 })
    }
    
    private static func menu(for show: SRGShow, in viewController: UIViewController) -> UIMenu {
        var elements: [UIMenuElement] = []
        return UIMenu(title: "", children: elements)
    }
    
    static func configuration(for item: Content.Item, at indexPath: IndexPath, in viewController: UIViewController) -> UIContextMenuConfiguration? {
        // Build an `NSIndexPath` from the `IndexPath` argument to have an equivalent identifier conforming to `NSCopying`.
        return configuration(for: item, identifier: NSIndexPath(item: indexPath.row, section: indexPath.section), in: viewController)
    }
    
    static func configuration(for item: Content.Item, identifier: NSCopying? = nil, in viewController: UIViewController) -> UIContextMenuConfiguration? {
        switch item {
        case let .media(media):
            return UIContextMenuConfiguration(identifier: identifier) {
                return MediaPreviewViewController(media: media)
            } actionProvider: { _ in
                return menu(for: media, in: viewController)
            }
        case let .show(show):
            return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil) { _ in
                return menu(for: show, in: viewController)
            }
        default:
            return nil
        }
    }
    
    static func interactionView(in collectionView: UICollectionView, withIdentifier identifier: NSCopying) -> UIView? {
        guard let indexPath = identifier as? NSIndexPath else { return nil }
        return collectionView.cellForItem(at: IndexPath(row: indexPath.row, section: indexPath.section))
    }
    
    static func commitPreview(in viewController: UIViewController, animator: UIContextMenuInteractionCommitAnimating) {
        animator.preferredCommitStyle = .pop
        animator.addCompletion {
            guard let previewViewController = animator.previewViewController else { return }
            if let mediaPreviewViewController = previewViewController as? MediaPreviewViewController {
                guard let letterboxController = mediaPreviewViewController.letterboxController else { return }
                viewController.play_presentMediaPlayer(from: letterboxController, withAirPlaySuggestions: true, fromPushNotification: false, animated: true, completion: nil)
            }
            else if let navigationController = viewController.navigationController {
                navigationController.present(previewViewController, animated: true, completion: nil)
            }
        }
    }
}
