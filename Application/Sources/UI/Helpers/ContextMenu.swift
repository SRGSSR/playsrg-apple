//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import UIKit

// MARK: Context menu management

enum ContextMenu {
    // See https://github.com/SRGSSR/playsrg-apple/issues/192
    private static let actionDelay = DispatchTimeInterval.seconds(1)
    
    static func configuration(for item: Content.Item, identifier: NSCopying? = nil, in viewController: UIViewController) -> UIContextMenuConfiguration? {
        switch item {
        case let .media(media):
            return configuration(for: media, identifier: identifier, in: viewController)
        case let .show(show):
            return configuration(for: show, identifier: identifier, in: viewController)
        case let .download(download):
            if let media = download.media {
                return configuration(for: media, identifier: identifier, in: viewController)
            }
            else {
                return nil
            }
        default:
            return nil
        }
    }
    
    static func configuration(for item: Content.Item, at indexPath: IndexPath, in viewController: UIViewController) -> UIContextMenuConfiguration? {
        // Build an `NSIndexPath` from the `IndexPath` argument to have an equivalent identifier conforming to `NSCopying`.
        return configuration(for: item, identifier: NSIndexPath(item: indexPath.row, section: indexPath.section), in: viewController)
    }
    
    static func interactionView(in tableView: UITableView, with configuration: UIContextMenuConfiguration) -> UIView? {
        guard let indexPath = configuration.identifier as? NSIndexPath else { return nil }
        return tableView.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section))
    }
    
    static func interactionView(in collectionView: UICollectionView, with configuration: UIContextMenuConfiguration) -> UIView? {
        guard let indexPath = configuration.identifier as? NSIndexPath else { return nil }
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
                navigationController.pushViewController(previewViewController, animated: true)
            }
        }
    }
}

// MARK: Sharing

private extension ContextMenu {
    private class ActivityPopoverPresentationDelegate: NSObject, UIPopoverPresentationControllerDelegate {
        func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
            return .formSheet
        }
    }
    
    private static let popoverPresentationDelegate = ActivityPopoverPresentationDelegate()
    
    private static func shareItem(_ sharingItem: SharingItem, in viewController: UIViewController) {
        let activityViewController = UIActivityViewController(sharingItem: sharingItem, source: .contextMenu)
        activityViewController.modalPresentationStyle = .popover
        
        let popoverPresentationController = activityViewController.popoverPresentationController
        popoverPresentationController?.sourceView = viewController.view
        popoverPresentationController?.delegate = popoverPresentationDelegate
        
        viewController.present(activityViewController, animated: true, completion: nil)
    }
}

// MARK: Media context menu

extension ContextMenu {
    static func configuration(for media: SRGMedia, identifier: NSCopying?, in viewController: UIViewController) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: identifier) {
            return MediaPreviewViewController(media: media)
        } actionProvider: { _ in
            return menu(for: media, in: viewController)
        }
    }
    
    static func configuration(for media: SRGMedia, at indexPath: IndexPath, in viewController: UIViewController) -> UIContextMenuConfiguration? {
        // Build an `NSIndexPath` from the `IndexPath` argument to have an equivalent identifier conforming to `NSCopying`.
        return configuration(for: media, identifier: NSIndexPath(item: indexPath.row, section: indexPath.section), in: viewController)
    }
    
    private static func menu(for media: SRGMedia, in viewController: UIViewController) -> UIMenu {
        return UIMenu(title: "", children: [
            watchLaterAction(for: media),
            historyAction(for: media),
            downloadAction(for: media),
            sharingAction(for: media, in: viewController),
            moreEpisodesAction(for: media, in: viewController)
        ].compactMap { $0 })
    }
    
    private static func watchLaterAction(for media: SRGMedia) -> UIAction? {
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
            return (action == .add) ? UIImage(named: "watch_later")! : UIImage(named: "watch_later_full")!
        }
        
        let action = WatchLaterAllowedActionForMedia(media)
        guard action != .none else { return nil }
        
        let menuAction = UIAction(title: title(for: action), image: image(for: action)) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.actionDelay) {
                WatchLaterToggleMedia(media) { added, error in
                    guard error == nil else { return }
                    
                    let labels = SRGAnalyticsHiddenEventLabels()
                    labels.source = AnalyticsSource.contextMenu.rawValue
                    labels.value = media.urn
                    
                    let name = added ? AnalyticsTitle.watchLaterAdd.rawValue : AnalyticsTitle.watchLaterRemove.rawValue
                    SRGAnalyticsTracker.shared.trackHiddenEvent(withName: name, labels: labels)
                    
                    Banner.showWatchLaterAdded(added, forItemWithName: media.title)
                }
            }
        }
        if action == .remove {
            menuAction.attributes = .destructive
        }
        return menuAction
    }
    
    private static func historyAction(for media: SRGMedia) -> UIAction? {
        guard HistoryContainsMedia(media) else { return nil }
                
        let menuAction = UIAction(title: NSLocalizedString("Delete from history", comment: "Context menu action to delete a media from the history"),
                                  image: UIImage(named: "history")!) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.actionDelay) {
                HistoryRemoveMedias([media]) { error in
                    guard error == nil else { return }
                    
                    let labels = SRGAnalyticsHiddenEventLabels()
                    labels.source = AnalyticsSource.contextMenu.rawValue
                    labels.value = media.urn
                    
                    SRGAnalyticsTracker.shared.trackHiddenEvent(withName: AnalyticsTitle.historyRemove.rawValue, labels: labels)
                }
            }
        }
        menuAction.attributes = .destructive
        return menuAction
    }
    
    private static func downloadAction(for media: SRGMedia) -> UIAction? {
        guard Download.canToggle(for: media) else { return nil}
        
        func title(for download: Download?) -> String {
            if download != nil {
                return NSLocalizedString("Delete from downloads", comment: "Context menu action to delete a media from the downloads")
            }
            else {
                return NSLocalizedString("Add to downloads", comment: "Context menu action to add a media to the downloads")
            }
        }
        
        func image(for download: Download?) -> UIImage {
            return download != nil ? UIImage(named: "download_remove")! : UIImage(named: "download")!
        }
        
        let download = Download(for: media)
        let menuAction = UIAction(title: title(for: download), image: image(for: download)) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.actionDelay) {
                if let download = download {
                    Download.removeDownloads([download])
                }
                else {
                    Download.add(for: media)
                }
                
                let labels = SRGAnalyticsHiddenEventLabels()
                labels.source = AnalyticsSource.contextMenu.rawValue
                labels.value = media.urn
                
                let name = (download == nil) ? AnalyticsTitle.downloadAdd.rawValue : AnalyticsTitle.downloadRemove.rawValue
                SRGAnalyticsTracker.shared.trackHiddenEvent(withName: name, labels: labels)
                
                Banner.showDownload(download == nil, forItemWithName: media.title)
            }
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
            let showViewController = SectionViewController.showViewController(for: show)
            navigationController.pushViewController(showViewController, animated: true)
        }
    }
}

// MARK: Show context menu

extension ContextMenu {
    static func configuration(for show: SRGShow, identifier: NSCopying?, in viewController: UIViewController) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: identifier) {
            return SectionViewController.showViewController(for: show)
        } actionProvider: { _ in
            return menu(for: show, in: viewController)
        }
    }
    
    static func configuration(for show: SRGShow, at indexPath: IndexPath, in viewController: UIViewController) -> UIContextMenuConfiguration? {
        // Build an `NSIndexPath` from the `IndexPath` argument to have an equivalent identifier conforming to `NSCopying`.
        return configuration(for: show, identifier: NSIndexPath(item: indexPath.row, section: indexPath.section), in: viewController)
    }
    
    private static func menu(for show: SRGShow, in viewController: UIViewController) -> UIMenu {
        return UIMenu(title: "", children: [
            favoriteAction(for: show),
            sharingAction(for: show, in: viewController)
        ].compactMap { $0 })
    }
    
    private static func favoriteAction(for show: SRGShow) -> UIAction? {
        func title(isFavorite: Bool) -> String {
            if isFavorite {
                return NSLocalizedString("Delete from favorites", comment: "Context menu action to delete a show from favorites")
            }
            else {
                return NSLocalizedString("Add to favorites", comment: "Context menu action to add a show to favorites")
            }
        }
        
        func image(isFavorite: Bool) -> UIImage {
            return isFavorite ? UIImage(named: "favorite_full")! : UIImage(named: "favorite")!
        }
        
        let isFavorite = FavoritesContainsShow(show)
        let menuAction = UIAction(title: title(isFavorite: isFavorite), image: image(isFavorite: isFavorite)) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.actionDelay) {
                FavoritesToggleShow(show)
                
                let labels = SRGAnalyticsHiddenEventLabels()
                labels.source = AnalyticsSource.contextMenu.rawValue
                labels.value = show.urn
                
                let name = !isFavorite ? AnalyticsTitle.favoriteAdd.rawValue : AnalyticsTitle.favoriteRemove.rawValue
                SRGAnalyticsTracker.shared.trackHiddenEvent(withName: name, labels: labels)
                
                Banner.showFavorite(!isFavorite, forItemWithName: show.title)
            }
        }
        if isFavorite {
            menuAction.attributes = .destructive
        }
        return menuAction
    }
    
    private static func sharingAction(for show: SRGShow, in viewController: UIViewController) -> UIAction? {
        guard let sharingItem = SharingItem(for: show) else { return nil }
        return UIAction(title: NSLocalizedString("Share", comment: "Context menu action to share a show"),
                        image: UIImage(named: "share")!) { _ in
            shareItem(sharingItem, in: viewController)
        }
    }
}

// MARK: Objective-C API

@objc final class ContextMenuObjC: NSObject {
    @objc static func configuration(for object: AnyObject, at indexPath: NSIndexPath, in viewController: UIViewController) -> UIContextMenuConfiguration? {
        switch object {
        case let media as SRGMedia:
            return ContextMenu.configuration(for: media, identifier: indexPath, in: viewController)
        case let show as SRGShow:
            return ContextMenu.configuration(for: show, identifier: indexPath, in: viewController)
        case let download as Download:
            if let media = download.media {
                return ContextMenu.configuration(for: media, identifier: indexPath, in: viewController)
            }
            else {
                return nil
            }
        default:
            return nil
        }
    }
    
    @objc static func interactionView(inTableView tableView: UITableView, with configuration: UIContextMenuConfiguration) -> UIView? {
        return ContextMenu.interactionView(in: tableView, with: configuration)
    }
    
    @objc static func interactionView(inCollectionView collectionView: UICollectionView, with configuration: UIContextMenuConfiguration) -> UIView? {
        return ContextMenu.interactionView(in: collectionView, with: configuration)
    }
    
    @objc static func commitPreview(in viewController: UIViewController, animator: UIContextMenuInteractionCommitAnimating) {
        ContextMenu.commitPreview(in: viewController, animator: animator)
    }
}
