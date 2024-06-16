//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation
import MediaPlayer

// Magic subscription handler to presumably make iOS keep the player alive so we can continuously play audio in the background.
final class RemoteCommandCenter: NSObject {
    @objc static func activateRatingCommand() {
        MPRemoteCommandCenter.shared().ratingCommand.addTarget(self, action: #selector(doNothing))
    }

    @objc private static func doNothing() -> MPRemoteCommandHandlerStatus {
        .success
    }
}
