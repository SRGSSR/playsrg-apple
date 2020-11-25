//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct MediaVisualView: View {
    let media: SRGMedia?
    let scale: ImageScale
    let contentMode: ContentMode
    
    init(media: SRGMedia?, scale: ImageScale, contentMode: ContentMode = .fit) {
        self.media = media
        self.scale = scale
        self.contentMode = contentMode
    }
    
    private var imageUrl: URL? {
        return media?.imageURL(for: .width, withValue: SizeForImageScale(scale).width, type: .default)
    }
    
    private var youthProtectionLogoImage: UIImage? {
        guard let youthProtectionColor = media?.youthProtectionColor else { return nil }
        return YouthProtectionImageForColor(youthProtectionColor)
    }
    
    static func formattedDuration(from: Date, to: Date) -> String? {
        guard let days = Calendar.current.dateComponents([.day], from: from, to: to).day else { return nil }
        switch days {
        case 0:
            return PlayShortFormattedHours(to.timeIntervalSince(from))
        case 1...3:
            return PlayShortFormattedDays(to.timeIntervalSince(from))
        default:
            return nil
        }
    }
    
    private func availabilityBadgeProperties() -> (text: String, color: Color)? {
        guard let media = media else { return nil }
        
        let now = Date()
        let availability = media.timeAvailability(at: now)
        switch availability {
        case .notYetAvailable:
            return (NSLocalizedString("Soon", comment: "Short label identifying content which will be available soon."), Color(.play_orange))
        case .notAvailableAnymore:
            return (NSLocalizedString("Expired", comment: "Short label identifying content which has expired."), Color(.play_gray))
        case .available:
            guard let endDate = media.endDate, media.contentType != .livestream, media.contentType != .scheduledLivestream else { return nil }
            if let remainingTime = Self.formattedDuration(from: now, to: endDate) {
                return (String(format: NSLocalizedString("%@ left", comment: "Short label displayed on a media expiring soon"), remainingTime), Color(.play_orange))
            }
            else {
                return nil
            }
        default:
            return nil
        }
    }
    
    var body: some View {
        ZStack {
            ImageView(url: imageUrl, contentMode: contentMode)
            BlockingOverlay(media: media)
            
            HStack(spacing: 4) {
                if media?.presentation == .presentation360 {
                    Image("360_media-25")
                        .foregroundColor(.white)
                }
                Spacer()
                if let youthProtectionLogoImage = youthProtectionLogoImage {
                    Image(uiImage: youthProtectionLogoImage)
                }
                DurationLabel(media: media)
            }
            .padding([.leading, .trailing, .bottom], 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            
            Group {
                if let isWebFirst = media?.play_isWebFirst, isWebFirst {
                    Badge(text: NSLocalizedString("Web first", comment: "Web first label on media cells"), color: Color(.srg_blue))
                }
                else if let availabilityBadgeProperties = availabilityBadgeProperties() {
                    Badge(text: availabilityBadgeProperties.text, color: availabilityBadgeProperties.color)
                }
            }
            .padding([.leading, .top], 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}
