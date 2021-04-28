//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAnalyticsSwiftUI
import SRGAppearanceSwift
import SRGLetterbox
import SwiftUI

struct MediaDetailView: View {
    @ObservedObject var model: MediaDetailModel
    
    init(media: SRGMedia) {
        model = MediaDetailModel(media: media)
    }
    
    private var imageUrl: URL? {
        return model.media.imageURL(for: .width, withValue: SizeForImageScale(.large).width, type: .default)
    }
    
    var body: some View {
        ZStack {
            ImageView(url: imageUrl)
            Rectangle()
                .fill(Color(white: 0, opacity: 0.6))
            VStack {
                DescriptionView(model: model)
                    .padding([.top, .horizontal], 100)
                    .padding(.bottom, 30)
                RelatedMediasView(model: model)
                    .frame(maxWidth: .infinity, maxHeight: 350)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.play_black))
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            model.refresh()
        }
        .onDisappear {
            model.cancelRefresh()
        }
        .onWake {
            model.refresh()
        }
        .tracked(withTitle: analyticsPageTitle, levels: analyticsPageLevels)
    }
    
    private struct DescriptionView: View {
        @ObservedObject var model: MediaDetailModel
        
        @Namespace private var namespace
        
        var body: some View {
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 0) {
                    Text(model.media.title)
                        .srgFont(.H1)
                        .lineLimit(3)
                        .foregroundColor(.white)
                    if let showTitle = model.media.show?.title, showTitle.lowercased() != model.media.title.lowercased() {
                        Text(showTitle)
                            .srgFont(.H3)
                            .foregroundColor(.white)
                    }
                    Spacer()
                        .frame(height: 20)
                    VStack(alignment: .leading, spacing: 0) {
                        AttributesView(model: model)
                        Spacer()
                            .frame(height: 20)
                        SummaryView(model: model)
                        Spacer()
                        ActionsView(model: model)
                            .layoutPriority(1)
                            .prefersDefaultFocus(in: namespace)
                            .frame(height: 160, alignment: .top)
                    }
                    .frame(maxWidth: geometry.size.width / 2, maxHeight: .infinity, alignment: .leading)
                }
                .focusScope(namespace)
            }
            .focusable()
        }
    }
    
    struct AttributeView: View {
        let icon: String
        let values: [String]
        
        var body: some View {
            HStack(spacing: 10) {
                Image(icon)
                Text(values.joined(separator: " - "))
                    .srgFont(.overline)
                    .foregroundColor(.white)
            }
        }
    }
    
    struct AttributesView: View {
        @ObservedObject var model: MediaDetailModel
        
        var body: some View {
            HStack(spacing: 30) {
                HStack(spacing: 4) {
                    if let youthProtectionLogoImage = YouthProtectionImageForColor(model.media.youthProtectionColor) {
                        Image(uiImage: youthProtectionLogoImage)
                    }
                    DurationLabel(media: model.media)
                }
                
                if let isWebFirst = model.media.play_isWebFirst, isWebFirst {
                    Badge(text: NSLocalizedString("Web first", comment: "Web first label on media detail page"), color: Color(.srg_blue))
                }
                if let subtitleLanguages = model.media.play_subtitleLanguages, !subtitleLanguages.isEmpty {
                    AttributeView(icon: "subtitles_off-22", values: subtitleLanguages)
                }
                if let audioLanguages = model.media.play_audioLanguages, !audioLanguages.isEmpty {
                    AttributeView(icon: "audios-22", values: audioLanguages)
                }
            }
        }
    }
    
    struct SummaryView: View {
        private struct TextButtonStyle: ButtonStyle {
            let focused: Bool
            
            func makeBody(configuration: Configuration) -> some View {
                configuration.label
                    .background(focused ? Color(UIColor(white: 1, alpha: 0.3)) : Color.clear)
                    .scaleEffect(focused && !configuration.isPressed ? 1.02 : 1)
            }
        }
        
        @ObservedObject var model: MediaDetailModel
        @State var isFocused = false
        
        var availabilityInformation: String {
            var publication = DateFormatter.play_dateAndTime.string(from: model.media.date)
            if let availability = MediaDescription.availability(for: model.media) {
                publication += " - " + availability
            }
            return publication
        }
        
        var body: some View {
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 0) {
                    if let summary = model.media.play_fullSummary {
                        Button {
                            showText(summary)
                        } label: {
                            Text(summary)
                                .foregroundColor(.white)
                                .srgFont(.body)
                                .frame(width: geometry.size.width, alignment: .leading)
                                .padding(.vertical, 5)
                                .onParentFocusChange { isFocused = $0 }
                        }
                        .buttonStyle(TextButtonStyle(focused: isFocused))
                    }
                    
                    Text(availabilityInformation)
                        .srgFont(.overline)
                        .foregroundColor(.white)
                        .padding(.vertical, 5)
                }
            }
        }
    }
    
    struct ActionsView: View {
        @ObservedObject var model: MediaDetailModel
        
        var playButtonLabel: String {
            let progress = HistoryPlaybackProgressForMediaMetadata(model.media)
            if progress == 0 || progress == 1 {
                return model.media.mediaType == .audio ? NSLocalizedString("Listen", comment: "Play button label for audio in media detail view") : NSLocalizedString("Watch", comment: "Play button label for video in media detail view")
            }
            else {
                return NSLocalizedString("Resume", comment: "Resume playback button label")
            }
        }
        
        var body: some View {
            HStack(alignment: .top, spacing: 30) {
                // TODO: 22 icon?
                LabeledButton(icon: "play-50", label: playButtonLabel) {
                    navigateToMedia(model.media, play: true)
                }
                if let action = model.watchLaterAllowedAction, action != .none, let isRemoval = (action == .remove) {
                    LabeledButton(icon: isRemoval ? "watch_later_full-22" : "watch_later-22",
                                  label: isRemoval ? NSLocalizedString("Later", comment: "Watch later or listen later button label in media detail view when a media is in the later list") : model.media.mediaType == .audio ? NSLocalizedString("Listen later", comment: "Button label in media detail view to add an audio to the later list") : NSLocalizedString("Watch later", comment: "Button label in media detail view to add a video to the later list"),
                                  accessibilityLabel: isRemoval ? PlaySRGAccessibilityLocalizedString("Delete from \"Later\" list", "Media deletion from later list label in the media detail view when a media is in the later list") : model.media.mediaType == .audio ? PlaySRGAccessibilityLocalizedString("Listen later", "Media addition to later list label in media detail view to add an audio to the later list") : PlaySRGAccessibilityLocalizedString("Watch later", "Media addition to later list label in media detail view to add a video to the later list")) {
                        model.toggleWatchLater()
                    }
                }
                if let show = model.media.show {
                    LabeledButton(icon: "episodes-22", label: NSLocalizedString("More episodes", comment: "Button to access more episodes from the media detail view")) {
                        navigateToShow(show)
                    }
                }
            }
        }
    }
    
    private struct RelatedMediasView: View {
        @ObservedObject var model: MediaDetailModel
        
        var body: some View {
            ZStack {
                if !model.relatedMedias.isEmpty {
                    ZStack {
                        Rectangle()
                            .fill(Color(.srg_color(fromHexadecimalString: "#222222")!))
                            .opacity(0.8)
                        ZStack {
                            Text(NSLocalizedString("This might interest you", comment: "Related content media list title"))
                                .srgFont(.body)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 40)
                                .padding(.top, 15)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            ScrollView(.horizontal) {
                                HStack(spacing: 40) {
                                    ForEach(model.relatedMedias, id: \.uid) { media in
                                        MediaCell(media: media, style: .show) {
                                            navigateToMedia(media, play: true)
                                        }
                                        .onFocus { isFocused in
                                            if isFocused {
                                                model.selectedMedia = media
                                            }
                                        }
                                        .frame(width: 280)
                                    }
                                }
                                .padding(.top, 70)
                                .padding(.horizontal, 40)
                            }
                        }
                    }
                }
                else {
                    Rectangle()
                        .fill(Color.clear)
                }
            }
        }
    }
}

extension MediaDetailView {
    private var analyticsPageTitle: String {
        return AnalyticsPageTitle.media.rawValue
    }
    
    private var analyticsPageLevels: [String]? {
        return [AnalyticsPageLevel.play.rawValue]
    }
}

struct MediaDetailView_Previews: PreviewProvider {
    static var mediaPreview: SRGMedia {
        let asset = NSDataAsset(name: "media-rts-tv")!
        let jsonData = try! JSONSerialization.jsonObject(with: asset.data, options: []) as? [String: Any]
        
        return try! MTLJSONAdapter(modelClass: SRGMedia.self)?.model(fromJSONDictionary: jsonData) as! SRGMedia
    }
    
    static var previews: some View {
        MediaDetailView(media: mediaPreview)
            .previewDisplayName("RTS media")
    }
}
