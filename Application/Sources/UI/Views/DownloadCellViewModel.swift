//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine

// MARK: View model

final class DownloadCellViewModel: ObservableObject {
    @Published var download: Download?
    @Published private(set) var state: State = .unknown
    
    var title: String? {
        return download?.title
    }
    
    var subtitle: String? {
        switch state {
        case let .downloading(progress: progress):
            return progress.localizedDescription
        default:
            guard let size = download?.size else { return nil }
            return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        }
    }
    
    init() {
        $download
            .map { download in
                return Publishers.Merge(
                    NotificationCenter.default.weakPublisher(for: NSNotification.Name.DownloadStateDidChange, object: download)
                        .compactMap { $0.userInfo?[DownloadStateKey] as? Int }
                        .map { Self.state(from: DownloadState(rawValue: $0), for: download) },
                    NotificationCenter.default.weakPublisher(for: NSNotification.Name.DownloadProgressDidChange, object: download)
                        .compactMap { $0.userInfo?[DownloadProgressKey] as? Progress }
                        .map { State.downloading(progress: $0) }
                )
                .prepend(Self.state(from: download?.state, for: download))
            }
            .switchToLatest()
            .assign(to: &$state)
    }
}

// MARK: Types

// TODO: Provides a common state merging both download-related notification streams. The download service should probably
//       be improved to deliver a single update stream, but for the moment it is simpler to do the consolidation here. If
//       we later rewrite our download service to deliver a single notification stream this extension can be removed.
extension DownloadCellViewModel {
    enum State {
        case unknown
        case added
        case removed
        case downloadable
        case downloading(progress: Progress)
        case suspended
        case downloaded
    }
    
    private static func progress(for download: Download?) -> Progress {
        if let download = download, let progress = Download.currentlyKnownProgress(for: download) {
            return progress
        }
        else {
            // Display 0% if nothing
            return Progress(totalUnitCount: 10)
        }
    }
    
    private static func state(from downloadState: DownloadState?, for download: Download?) -> State {
        guard let downloadState = downloadState else { return .unknown }
        switch downloadState {
        case .added:
            return .added
        case .removed:
            return .removed
        case .downloadable:
            return .downloadable
        case .downloading:
            return .downloading(progress: progress(for: download))
        case .downloadingSuspended:
            return .suspended
        case .downloaded:
            return .downloaded
        default:
            return .unknown
        }
    }
}
