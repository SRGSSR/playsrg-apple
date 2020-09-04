//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SRGDataProviderModel
import SwiftUI

struct FocusedKey: PreferenceKey {
    static var defaultValue: Bool = false
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {}
}

struct DurationLabel: View {
    let media: SRGMedia?
    
    private var duration: String? {
        guard let media = media else { return nil }
        return DurationFormatters.minutes(for: media.duration / 1000)
    }
    
    var body: some View {
        if let duration = duration {
            Text(duration)
                .font(.caption)
                .foregroundColor(.white)
                .padding([.top, .bottom], 5)
                .padding([.leading, .trailing], 8)
                .background(Color.init(white: 0, opacity: 0.5))
                .cornerRadius(4)
        }
    }
}

struct BlockingOverlay: View {
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
                    .colorInvert()
            }
        }
    }
}

struct Badge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.white)
            .padding([.top, .bottom], 5)
            .padding([.leading, .trailing], 8)
            .background(color)
            .cornerRadius(4)
    }
}

struct MediaVisualView: View {
    let media: SRGMedia?
    
    @Environment(\.isFocused) var isFocused: Bool
    
    private var imageUrl: URL? {
        return media?.imageURL(for: .width, withValue: SizeForImageScale(.small).width, type: .default)
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
        let availabilty = media.timeAvailability(at: now)
        switch availabilty {
            case .notAvailableAnymore:
                return (NSLocalizedString("Expired", comment: "Short label identifying content which has expired."), .gray)
            case .available:
                guard let endDate = media.endDate, media.contentType != .livestream, media.contentType != .scheduledLivestream else { return nil }
                if let remainingDays = Self.formattedDuration(from: now, to: endDate) {
                    return (NSLocalizedString("\(remainingDays) left", comment: "Short label displayed on medias expiring soon"), .orange)
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
            ImageView(url: imageUrl)
                .preference(key: FocusedKey.self, value: isFocused)
                .whenRedacted { $0.hidden() }
            
            HStack(spacing: 4) {
                if media?.presentation == .presentation360 {
                    Image("360_media-25")
                        .colorInvert()
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
            
            BlockingOverlay(media: media)
        }
    }
}

struct MediaDescriptionView: View {
    let media: SRGMedia?
    
    static private func showName(for media: SRGMedia) -> String? {
        guard let show = media.show else { return nil }
        return !media.title.contains(show.title) ? show.title : nil
    }
    
    private var title: String {
        guard let media = media else { return String(repeating: " ", count: .random(in: 15..<30)) }
        return media.title
    }
    
    private var subtitle: String {
        guard let media = media else { return String(repeating: " ", count: .random(in: 20..<30)) }
        if let showName = Self.showName(for: media) {
            return "\(showName) - \(DateFormatters.formattedRelativeDate(for: media.date))"
        }
        else {
            return DateFormatters.formattedRelativeDateAndTime(for: media.date)
        }
    }
    
    var body: some View {
        Text(title)
            .lineLimit(2)
        Text(subtitle)
            .font(.caption)
            .lineLimit(1)
    }
}

struct MediaCell: View {
    let media: SRGMedia?
    
    @State private var isPresented = false
    
    /// Focus is received by the Button, detected in its title view, and bubbled up with preferences so that we
    /// can apply a similar focused appearance to the sibling description view.
    @State private var isFocused = false
    
    private var redactionReason: RedactionReasons {
        return media == nil ? .placeholder : .init()
    }
    
    private func play() {
        if media != nil {
            isPresented.toggle()
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Button(action: play) {
                    MediaVisualView(media: media)
                        .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                }
                .buttonStyle(CardButtonStyle())
                
                MediaDescriptionView(media: media)
                    .frame(width: geometry.size.width, alignment: .leading)
                    .scaleEffect(isFocused ? 1.1 : 1)
                    .offset(x: 0, y: isFocused ? 10 : 0)
            }
            .onPreferenceChange(FocusedKey.self) { value in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isFocused = value
                }
            }
            .redacted(reason: redactionReason)
            .fullScreenCover(isPresented: $isPresented, content: {
                PlayerView(media: media!)
            })
        }
    }
}
