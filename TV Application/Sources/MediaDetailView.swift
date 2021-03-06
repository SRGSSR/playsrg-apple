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
    @Binding var media: SRGMedia?
    @StateObject var model = MediaDetailViewModel()
    
    init(media: SRGMedia?) {
        _media = .constant(media)
    }
    
    var body: some View {
        ZStack {
            ImageView(url: model.imageUrl)
            Color(white: 0, opacity: 0.6)
            VStack {
                DescriptionView(model: model)
                    .padding([.top, .horizontal], 100)
                    .padding(.bottom, 30)
                RelatedMediasView(model: model)
                    .frame(maxWidth: .infinity, maxHeight: 350)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.srgGray16)
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            model.initialMedia = media
        }
        .onChange(of: media) { newValue in
            model.initialMedia = newValue
        }
        .tracked(withTitle: analyticsPageTitle, levels: analyticsPageLevels)
        .redactedIfNil(media)
    }
    
    private struct DescriptionView: View {
        @ObservedObject var model: MediaDetailViewModel
        
        @Namespace private var namespace
        
        var body: some View {
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 0) {
                    Text(model.media?.title ?? .placeholder(length: 8))
                        .srgFont(.H1)
                        .lineLimit(3)
                        .foregroundColor(.white)
                    if let showTitle = model.showTitle {
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
                    .srgFont(.subtitle2)
                    .foregroundColor(.white)
            }
        }
    }
    
    struct AttributesView: View {
        @ObservedObject var model: MediaDetailViewModel
        
        var body: some View {
            HStack(spacing: 30) {
                HStack(spacing: 4) {
                    if let youthProtectionColor = model.media?.youthProtectionColor, let youthProtectionLogoImage = YouthProtectionImageForColor(youthProtectionColor) {
                        Image(uiImage: youthProtectionLogoImage)
                    }
                    if let media = model.media, let duration = MediaDescription.duration(for: media) {
                        DurationBadge(duration: duration)
                    }
                }
                
                if let isWebFirst = model.media?.play_isWebFirst, isWebFirst {
                    Badge(text: NSLocalizedString("Web first", comment: "Web first label on media detail page"), color: Color.srgBlue)
                }
                if let subtitleLanguages = model.media?.play_subtitleLanguages, !subtitleLanguages.isEmpty {
                    AttributeView(icon: "subtitle_tracks", values: subtitleLanguages)
                }
                if let audioLanguages = model.media?.play_audioLanguages, !audioLanguages.isEmpty {
                    AttributeView(icon: "audio_tracks", values: audioLanguages)
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
        
        @ObservedObject var model: MediaDetailViewModel
        @State var isFocused = false
        
        var availabilityInformation: String {
            guard let media = model.media else { return .placeholder(length: 15)}
            var publication = DateFormatter.play_dateAndTime.string(from: media.date)
            if let availability = MediaDescription.availability(for: media) {
                publication += " - " + availability
            }
            return publication
        }
        
        var body: some View {
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 0) {
                    if let summary = model.media?.play_fullSummary {
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
                        .srgFont(.subtitle2)
                        .foregroundColor(.white)
                        .padding(.vertical, 5)
                }
            }
        }
    }
    
    struct ActionsView: View {
        @ObservedObject var model: MediaDetailViewModel
        
        var playButtonLabel: String {
            let progress = HistoryPlaybackProgressForMediaMetadata(model.media)
            if progress == 0 || progress == 1 {
                return model.media?.mediaType == .audio ? NSLocalizedString("Listen", comment: "Play button label for audio in media detail view") : NSLocalizedString("Watch", comment: "Play button label for video in media detail view")
            }
            else {
                return NSLocalizedString("Resume", comment: "Resume playback button label")
            }
        }
        
        var body: some View {
            HStack(alignment: .top, spacing: 30) {
                // TODO: 22 icon?
                LabeledButton(icon: "play", label: playButtonLabel) {
                    if let media = model.media {
                        navigateToMedia(media, play: true)
                    }
                }
                if let action = model.watchLaterAllowedAction, action != .none, let isRemoval = (action == .remove) {
                    // TODO: Write in a better way
                    LabeledButton(icon: isRemoval ? "watch_later_full" : "watch_later",
                                  label: isRemoval
                                    ? NSLocalizedString("Later", comment: "Watch later or listen later button label in media detail view when a media is in the later list")
                                    : model.media?.mediaType == .audio
                                    ? NSLocalizedString("Listen later", comment: "Button label in media detail view to add an audio to the later list")
                                    : NSLocalizedString("Watch later", comment: "Button label in media detail view to add a video to the later list"),
                                  accessibilityLabel: isRemoval
                                    ? PlaySRGAccessibilityLocalizedString("Delete from \"Later\" list", comment: "Media deletion from later list label in the media detail view when a media is in the later list")
                                    : model.media?.mediaType == .audio
                                    ? PlaySRGAccessibilityLocalizedString("Listen later", comment: "Media addition to later list label in media detail view to add an audio to the later list")
                                    : PlaySRGAccessibilityLocalizedString("Watch later", comment: "Media addition to later list label in media detail view to add a video to the later list")) {
                        model.toggleWatchLater()
                    }
                }
                if let show = model.media?.show {
                    LabeledButton(icon: "episodes", label: NSLocalizedString("More episodes", comment: "Button to access more episodes from the media detail view")) {
                        navigateToShow(show)
                    }
                }
            }
        }
    }
    
    private struct RelatedMediasView: View {
        @ObservedObject var model: MediaDetailViewModel
        
        var body: some View {
            ZStack {
                if !model.relatedMedias.isEmpty {
                    ZStack {
                        Color.hexadecimal("#222222")
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
                    Color.clear
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
