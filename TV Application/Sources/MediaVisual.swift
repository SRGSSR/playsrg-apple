//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct MediaVisual<Overlay: View>: View {
    private struct DurationLabel: View {
        let media: SRGMedia?
        
        private var duration: String? {
            guard let media = media else { return nil }
            return DurationFormatters.minutes(for: media.duration / 1000)
        }
        
        var body: some View {
            if let duration = duration {
                Text(duration)
                    .srgFont(.regular, size: .caption)
                    .foregroundColor(.white)
                    .padding([.top, .bottom], 5)
                    .padding([.leading, .trailing], 8)
                    .background(Color.init(white: 0, opacity: 0.5))
                    .cornerRadius(4)
            }
        }
    }

    private struct BlockingOverlay: View {
        let media: SRGMedia?
        
        private var blockingIconImage: UIImage? {
            guard let blockingReason = media?.blockingReason(at: Date()) else { return nil }
            return UIImage.play_image(for: blockingReason)
        }
        
        var body: some View {
            if let blockingIconImage = blockingIconImage {
                ZStack {
                    Rectangle()
                        .fill(Color(white: 0, opacity: 0.6))
                    Image(uiImage: blockingIconImage)
                        .foregroundColor(.white)
                }
            }
        }
    }

    private struct Badge: View {
        let text: String
        let color: Color
        
        var body: some View {
            Text(text)
                .srgFont(.regular, size: .caption)
                .foregroundColor(.white)
                .padding([.top, .bottom], 5)
                .padding([.leading, .trailing], 8)
                .background(color)
                .cornerRadius(4)
        }
    }
    
    let media: SRGMedia?
    let scale: ImageScale
    let contentMode: ContentMode
    var overlay: () -> Overlay
    
    init(media: SRGMedia?, scale: ImageScale, contentMode: ContentMode, @ViewBuilder overlay: @escaping () -> Overlay) {
        self.media = media
        self.scale = scale
        self.contentMode = contentMode
        self.overlay = overlay
    }
    
    @Environment(\.isFocused) private var isFocused: Bool
    
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
                return DurationFormatters.hours(for: to.timeIntervalSince(from))
            case 1:
                return DurationFormatters.days(for: to.timeIntervalSince(from))
            default:
                return nil
        }
    }
    
    private func availabilityBadgeProperties() -> (text: String, color: Color)? {
        guard let media = media else { return nil }
        
        let now = Date()
        let availability = media.timeAvailability(at: now)
        switch availability {
            case .notAvailableAnymore:
                return (NSLocalizedString("Expired", comment: "Short label identifying content which has expired."), .gray)
            case .available:
                guard let endDate = media.endDate, media.contentType != .livestream, media.contentType != .scheduledLivestream else { return nil }
                if let remainingDays = Self.formattedDuration(from: now, to: endDate) {
                    return (NSLocalizedString("\(remainingDays) left", comment: "Short label displayed on medias expiring soon"), Color(.play_orange))
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
                .preference(key: FocusedKey.self, value: isFocused)
                .whenRedacted { $0.hidden() }
            overlay()
            
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

struct MediaVisual_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
