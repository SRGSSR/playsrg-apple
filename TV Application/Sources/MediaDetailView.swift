//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SRGDataProviderCombine
import SRGLetterbox
import SwiftUI

class MediaDetailModel: ObservableObject {
    let media: SRGMedia
    
    @Published private(set) var relatedMedias: [SRGMedia] = []
    
    var cancellables = Set<AnyCancellable>()
    
    init(media: SRGMedia) {
        self.media = media
    }
    
    func refresh() {
        guard let show = media.show else { return }
        SRGDataProvider.current!.latestEpisodesForShow(withUrn: show.urn)
            .map { result -> [SRGMedia] in
                guard let episodes = result.episodeComposition.episodes else { return [] }
                return episodes.flatMap { episode -> [SRGMedia] in
                    guard let medias = episode.medias else { return [] }
                    return medias.filter { media in
                        return media.contentType == .episode || media.contentType == .scheduledLivestream
                    }
                }
            }
            .replaceError(with: [])
            .assign(to: \.relatedMedias, on: self)
            .store(in: &cancellables)
    }
    
    func cancelRefresh() {
        cancellables = []
    }
}

struct MediaDetailView: View {
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
                    
                    HStack(spacing: 4) {
                        if let youthProtectionLogoImage = YouthProtectionImageForColor(media.youthProtectionColor) {
                            Image(uiImage: youthProtectionLogoImage)
                        }
                        DurationLabel(media: media)
                    }
                    
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
                    
                    Spacer()
                    
                    HStack {
                        LabeledButton(icon: "play.fill", label: NSLocalizedString("Play", comment: "Play button label")) {
                            if let presentedViewController = UIApplication.shared.windows.first?.rootViewController?.presentedViewController {
                                let letterboxViewController = SRGLetterboxViewController()
                                letterboxViewController.controller.playMedia(media, at: nil, withPreferredSettings: nil)
                                presentedViewController.present(letterboxViewController, animated: true, completion: nil)
                            }
                        }
                        LabeledButton(icon: "clock", label: NSLocalizedString("Watch later", comment: "Watch later button label")) {
                            /* Toggle Watch Later state */
                        }
                    }
                }
                .frame(maxWidth: geometry.size.width / 2, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
    
    let media: SRGMedia
    
    @ObservedObject var model: MediaDetailModel
    
    init(media: SRGMedia) {
        self.media = media
        model = MediaDetailModel(media: media)
    }
    
    private var imageUrl: URL? {
        return media.imageURL(for: .width, withValue: SizeForImageScale(.large).width, type: .default)
    }
    
    var body: some View {
        ZStack {
            ImageView(url: imageUrl)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Rectangle()
                .fill(Color(white: 0, opacity: 0.6))
            VStack {
                DescriptionView(media: media)
                    .padding([.top, .leading, .trailing], 100)
                    .padding(.bottom, 30)
                
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
                                    }
                                }
                                .padding(.top, 70)
                                .padding([.leading, .trailing], 40)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: 350)
                }
                else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(maxWidth: .infinity, maxHeight: 305)
                }
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
