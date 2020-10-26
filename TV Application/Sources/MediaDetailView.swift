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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
}

extension MediaDetailView {
    struct PropertiesView: View {
        let media: SRGMedia
        
        var body: some View {
            HStack(spacing: 4) {
                if let youthProtectionLogoImage = YouthProtectionImageForColor(media.youthProtectionColor) {
                    Image(uiImage: youthProtectionLogoImage)
                }
                DurationLabel(media: media)
                if let subtitleLanguages = media.play_subtitleLanguages, subtitleLanguages.count != 0 {
                    Spacer()
                        .frame(width: 25)
                    Image("subtitles_off-22")
                    Spacer()
                        .frame(width: 5)
                    Text(subtitleLanguages.joined(separator: " - "))
                        .srgFont(.regular, size: .caption)
                        .foregroundColor(.white)
                }
                if let audioLanguages = media.play_audioLanguages, audioLanguages.count != 0 {
                    Spacer()
                        .frame(width: 25)
                    Image("audios-22")
                    Spacer()
                        .frame(width: 5)
                    Text(audioLanguages.joined(separator: " - "))
                        .srgFont(.regular, size: .caption)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

extension MediaDetailView {
    struct SummaryView: View {
        private struct TextButtonStyle: ButtonStyle {
            let focused: Bool
            
            func makeBody(configuration: Configuration) -> some View {
                configuration.label
                    .background(focused ? Color(UIColor.init(white: 1, alpha: 0.1)) : Color.clear)
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
                                .frame(width: geometry.size.width)
                                .padding([.top, .bottom], 5)
                                .reportFocusChanges()
                        })
                        .onFocusChange { focused in
                            withAnimation {
                                isFocused = focused
                            }
                        }
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
}

extension MediaDetailView {
    struct ActionsView: View {
        let media: SRGMedia
        
        var body: some View {
            HStack(spacing: 10) {
                LabeledButton(icon: "play-50", label: NSLocalizedString("Play", comment: "Play button label")) {
                    navigateToMedia(media, play: true)
                }
                .frame(width: 200)
                
                LabeledButton(icon: "watch_later-22", label: NSLocalizedString("Watch later", comment: "Watch later button label")) {
                    /* Toggle Watch Later state */
                }
                .frame(width: 200)
                
                if media.show != nil {
                    LabeledButton(icon: "episodes-22", label: NSLocalizedString("Episodes", comment:"Episodes button label")) {
                        /* Open show page */
                    }
                    .frame(width: 200)
                }
                
                Spacer()
            }
            .frame(height: 80)
        }
    }
}

extension MediaDetailView {
    private struct DescriptionView: View {
        let media: SRGMedia
        
        @Namespace private var namespace
        
        var body: some View {
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 0) {
                    Text(MediaDescription.subtitle(for: media))
                        .srgFont(.bold, size: .title)
                        .lineLimit(3)
                        .foregroundColor(.white)
                        .padding([.top, .bottom], 0)
                    Text(MediaDescription.title(for: media))
                        .srgFont(.regular, size: .headline)
                        .foregroundColor(.white)
                        .padding([.top, .bottom], 0)
                    Spacer()
                        .frame(height: 20)
                    PropertiesView(media: media)
                    Spacer()
                        .frame(height: 20)
                    SummaryView(media: media)
                    Spacer()
                    ActionsView(media: media)
                        .prefersDefaultFocus(in: namespace)
                }
                .frame(maxWidth: geometry.size.width / 2, maxHeight: .infinity, alignment: .topLeading)
                .focusScope(namespace)
            }
        }
    }
}

extension MediaDetailView {
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
                                        MediaCell(media: media, action: {
                                            navigateToMedia(media, play: true)
                                        })
                                        .frame(width: 280)
                                        .onFocusChange { focused in
                                            if focused {
                                                focusedMedia = media
                                            }
                                        }
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
