//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SRGLetterbox
import SwiftUI

struct MediaDetailView: View {
    let media: SRGMedia
    
    @ObservedObject var model: MediaDetailModel
    @State private var currentMedia: SRGMedia?
    
    init(media: SRGMedia) {
        self.media = media
        model = MediaDetailModel(media: media)
    }
    
    private var displayedMedia: SRGMedia {
        return currentMedia ?? media
    }
    
    private var imageUrl: URL? {
        return displayedMedia.imageURL(for: .width, withValue: SizeForImageScale(.large).width, type: .default)
    }
    
    var body: some View {
        ZStack {
            ImageView(url: imageUrl)
            Rectangle()
                .fill(Color(white: 0, opacity: 0.6))
            VStack {
                DescriptionView(media: displayedMedia)
                    .padding([.top, .leading, .trailing], 100)
                    .padding(.bottom, 30)
                RelatedMediasView(model: model, focusedMedia: $currentMedia)
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
        .onResume {
            model.refresh()
        }
    }
    
    private struct DescriptionView: View {
        let media: SRGMedia
        
        @Namespace private var namespace
        
        var body: some View {
            FocusableRegion {
                GeometryReader { geometry in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(MediaDescription.subtitle(for: media, style: .show))
                            .srgFont(.bold, size: .title)
                            .lineLimit(3)
                            .foregroundColor(.white)
                        Text(MediaDescription.title(for: media, style: .show))
                            .srgFont(.regular, size: .headline)
                            .foregroundColor(.white)
                        Spacer()
                            .frame(height: 20)
                        AttributesView(media: media)
                        Spacer()
                            .frame(height: 20)
                        SummaryView(media: media)
                        Spacer()
                        ActionsView(media: media)
                            .layoutPriority(1)
                            .prefersDefaultFocus(in: namespace)
                    }
                    .frame(maxWidth: geometry.size.width / 2, maxHeight: .infinity, alignment: .leading)
                    .focusScope(namespace)
                }
            }
        }
    }
    
    struct AttributeView: View {
        let icon: String
        let values: [String]
        
        var body: some View {
            HStack(spacing: 10) {
                Image(icon)
                Text(values.joined(separator: " - "))
                    .srgFont(.regular, size: .caption)
                    .foregroundColor(.white)
            }
        }
    }
    
    struct AttributesView: View {
        let media: SRGMedia
        
        var body: some View {
            HStack(spacing: 30) {
                HStack(spacing: 4) {
                    if let youthProtectionLogoImage = YouthProtectionImageForColor(media.youthProtectionColor) {
                        Image(uiImage: youthProtectionLogoImage)
                    }
                    DurationLabel(media: media)
                }
                
                if let isWebFirst = media.play_isWebFirst, isWebFirst {
                    Badge(text: NSLocalizedString("Web first", comment: "Web first label on media detail page"), color: Color(.srg_blue))
                }
                if let subtitleLanguages = media.play_subtitleLanguages, !subtitleLanguages.isEmpty {
                    AttributeView(icon: "subtitles_off-22", values: subtitleLanguages)
                }
                if let audioLanguages = media.play_audioLanguages, !audioLanguages.isEmpty {
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
                    .background(focused ? Color(UIColor.init(white: 1, alpha: 0.3)) : Color.clear)
                    .scaleEffect(focused && !configuration.isPressed ? 1.02 : 1)
            }
        }
        
        let media: SRGMedia
        
        @State var isFocused: Bool = false
        
        var body: some View {
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 0) {
                    if let summary = media.play_fullSummary {
                        Button(action: {
                            showText(summary)
                        }, label: {
                            Text(summary)
                                .foregroundColor(.white)
                                .srgFont(.light, size: .subtitle)
                                .frame(width: geometry.size.width, alignment: .leading)
                                .padding([.top, .bottom], 5)
                                .onFocusChange { isFocused = $0 }
                        })
                        .buttonStyle(TextButtonStyle(focused: isFocused))
                    }
                    
                    if let availability = MediaDescription.availability(for: media) {
                        Text(availability)
                            .srgFont(.light, size: .subheadline)
                            .foregroundColor(.white)
                            .padding([.top, .bottom], 5)
                    }
                }
            }
        }
    }
    
    struct ActionsView: View {
        let media: SRGMedia
        
        var body: some View {
            HStack(alignment: .top, spacing: 30) {
                // TODO: 22 icon?
                LabeledButton(icon: "play-50", label: media.mediaType == .audio ? NSLocalizedString("Listen", comment: "Play button label for audio") : NSLocalizedString("Watch", comment: "Play button label for video")) {
                    navigateToMedia(media, play: true)
                }
                #if DEBUG
                LabeledButton(icon: "watch_later-22", label: NSLocalizedString("Later", comment: "Watch or listen later button label")) {
                    /* Toggle Watch Later state */
                }
                #endif
                if let show = media.show {
                    LabeledButton(icon: "episodes-22", label: NSLocalizedString("Show", comment:"Show button label")) {
                        navigateToShow(show)
                    }
                }
            }
        }
    }
    
    private struct RelatedMediasView: View {
        @ObservedObject var model: MediaDetailModel
        @Binding var focusedMedia: SRGMedia?
        
        init(model: MediaDetailModel, focusedMedia: Binding<SRGMedia?>) {
            self.model = model
            self._focusedMedia = focusedMedia
        }
        
        var body: some View {
            ZStack {
                if !model.relatedMedias.isEmpty {
                    ZStack {
                        Rectangle()
                            .fill(Color(.srg_color(fromHexadecimalString: "#222222")!))
                            .opacity(0.8)
                        ZStack {
                            Text(NSLocalizedString("Related content", comment: "Related content media list title"))
                                .srgFont(.medium, size: .headline)
                                .foregroundColor(.gray)
                                .padding([.leading, .trailing], 40)
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
                                                focusedMedia = media
                                            }
                                        }
                                        .frame(width: 280)
                                    }
                                }
                                .padding(.top, 70)
                                .padding([.leading, .trailing], 40)
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
