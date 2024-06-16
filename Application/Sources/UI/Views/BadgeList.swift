//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import SwiftUI

/// Behavior: h-exp, v-hug
struct BadgeList: View {
    let data: Data

    init(data: Data) {
        self.data = data
    }

    static func data(for program: SRGProgram) -> Data? {
        let data = Data(
            hasSubtitles: program.subtitlesAvailable,
            hasMultiAudio: program.alternateAudioAvailable,
            hasAudioDescription: program.audioDescriptionAvailable,
            hasSignLanguage: program.signLanguageAvailable,
            hasDolbyDigital: program.dolbyDigitalAvailable
        )
        return data.hasBadges ? data : nil
    }

    var body: some View {
        HStack(spacing: 6) {
            if data.hasSubtitles {
                SubtitlesBadge()
            }
            if data.hasMultiAudio {
                MultiAudioBadge()
            }
            if data.hasAudioDescription {
                AudioDescriptionBadge()
            }
            if data.hasSignLanguage {
                SignLanguageBadge()
            }
            if data.hasDolbyDigital {
                DolbyDigitalBadge()
            }
            Spacer()
        }
    }
}

// MARK: Types

extension BadgeList {
    /// Input data for the view
    struct Data: Hashable {
        let hasSubtitles: Bool
        let hasMultiAudio: Bool
        let hasAudioDescription: Bool
        let hasSignLanguage: Bool
        let hasDolbyDigital: Bool

        var hasBadges: Bool {
            return hasSubtitles
                || hasMultiAudio
                || hasAudioDescription
                || hasSignLanguage
                || hasDolbyDigital
        }
    }
}

struct BadgeList_Previews: PreviewProvider {
    static var previews: some View {
        BadgeList(data: BadgeList.data(for: Mock.program())!)
    }
}
