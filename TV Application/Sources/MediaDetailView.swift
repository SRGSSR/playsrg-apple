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
    @State var currentMedia: SRGMedia?
    
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
                    Text(subtitleLanguages.joined(separator: " - "))
                        .srgFont(.regular, size: .caption)
                        .foregroundColor(.white)
                }
                if let audioLanguages = media.play_audioLanguages, audioLanguages.count != 0 {
                    Spacer()
                        .frame(width: 25)
                    Image("audios-22")
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
        let media: SRGMedia
        
        var body: some View {
            if let summary = media.play_fullSummary {
                Text(summary)
                    .srgFont(.light, size: .subtitle)
                    .foregroundColor(.white)
                    .padding([.top, .bottom], 5)
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

extension MediaDetailView {
    struct ActionsView: View {
        let media: SRGMedia
        
        var body: some View {
            HStack {
                LabeledButton(icon: "play.fill", label: NSLocalizedString("Play", comment: "Play button label")) {
                    if let topViewController = UIApplication.shared.windows.first?.topViewController {
                        let letterboxViewController = SRGLetterboxViewController()
                        letterboxViewController.controller.playMedia(media, at: nil, withPreferredSettings: nil)
                        topViewController.present(letterboxViewController, animated: true, completion: nil)
                    }
                }
                LabeledButton(icon: "clock", label: NSLocalizedString("Watch later", comment: "Watch later button label")) {
                    /* Toggle Watch Later state */
                }
            }
        }
    }
}

extension MediaDetailView {
    private struct DescriptionView: View {
        let media: SRGMedia
        
        var body: some View {
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 0) {
                    Text(MediaDescription.subtitle(for: media))
                        .srgFont(.bold, size: .title)
                        .lineLimit(3)
                        .foregroundColor(.white)
                        .padding([.top, .bottom], 5)
                    Text(MediaDescription.title(for: media))
                        .srgFont(.regular, size: .headline)
                        .foregroundColor(.white)
                        .padding([.top, .bottom], 5)
                    PropertiesView(media: media)
                    SummaryView(media: media)
                    Spacer()
                    ActionsView(media: media)
                }
                .frame(maxWidth: geometry.size.width / 2, maxHeight: .infinity, alignment: .topLeading)
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
                            Text(NSLocalizedString("Last episodes", comment: "Last episode list title"))
                                .srgFont(.medium, size: .headline)
                                .foregroundColor(.gray)
                                .padding([.leading, .trailing], 40)
                                .padding(.top, 15)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            ScrollView(.horizontal) {
                                HStack(spacing: 40) {
                                    ForEach(model.relatedMedias, id: \.uid) { media in
                                        MediaCell(media: media)
                                            .frame(width: 280)
                                            .onFocusChange { focused in
                                                if focused {
                                                    focusedMedia = media
                                                }
                                            }
                                            .animation(nil)
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
            .animation(.default)
        }
    }
}
