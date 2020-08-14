//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct HomeSwimlane: View {
    let row: HomeRow
    
    var body: some View {
        if let row = row as? HomeMediaRow {
            if case let .trending(appearance: appearance) = row.id, appearance == .hero {
                HomeMediaHeroSwimlane(row: row)
            }
            else {
                Section(header: HomeSwimlaneHeader(row: row)) {
                    HomeMediaSwimlane(row: row)
                }
            }
        }
        else if let row = row as? HomeTopicRow {
            HomeTopicSwimlane(row: row)
        }
    }
}

struct HomeMediaSwimlane: View {
    @ObservedObject var row: HomeMediaRow
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 40) {
                if row.medias.count > 0 {
                    ForEach(row.medias, id: \.uid) { media in
                        MediaCell(media: media)
                    }
                }
                else {
                    ForEach(0..<10) { _ in
                        MediaCell(media: nil)
                    }
                }
            }
            .padding([.leading, .trailing], VideosView.horizontalPadding)
        }
    }
}

struct HomeMediaHeroSwimlane: View {
    @ObservedObject var row: HomeMediaRow
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 40) {
                if row.medias.count > 0 {
                    ForEach(row.medias, id: \.uid) { media in
                        HeroMediaCell(media: media)
                    }
                }
                else {
                    ForEach(0..<2) { _ in
                        HeroMediaCell(media: nil)
                    }
                }
            }
            .padding([.leading, .trailing], VideosView.horizontalPadding)
        }
    }
}

struct HomeTopicSwimlane: View {
    @ObservedObject var row: HomeTopicRow
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 40) {
                if row.topics.count > 0 {
                    ForEach(row.topics, id: \.uid) { topic in
                        TopicCell(topic: topic)
                    }
                }
                else {
                    ForEach(0..<2) { _ in
                        TopicCell(topic: nil)
                    }
                }
            }
            .padding([.leading, .trailing], VideosView.horizontalPadding)
        }
    }
}

struct HomeSwimlaneHeader: View {
    let row: HomeMediaRow
    
    var body: some View {
        if let title = row.title {
            Text(title)
                .font(.headline)
                .padding([.leading, .trailing], VideosView.horizontalPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue)
        }
    }
}
