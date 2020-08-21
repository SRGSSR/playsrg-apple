//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

/**
 *  Factory swimlane. Installs the proper type of swimlane based on the row type.
 */
struct HomeSwimlane: View {
    static let horizontalPadding: CGFloat = 40
    
    let row: HomeRow
    
    var body: some View {
        if let row = row as? HomeMediaRow {
            if case let .tvTrending(appearance: appearance) = row.id, appearance == .hero {
                HomeMediaHeroSwimlane(row: row)
            }
            else {
                Section(header: HomeSwimlaneHeader(row: row)) {
                    HomeMediaSwimlane(row: row)
                }
            }
        }
        else if let row = row as? HomeTopicsAccessRow {
            HomeTopicSwimlane(row: row)
        }
        else if let row = row as? HomeShowsAccessRow {
            Section(header: HomeSwimlaneHeader(row: row)) {
                HomeShowsAccessSwimlane(row: row)
            }
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
            .padding([.leading, .trailing], HomeSwimlane.horizontalPadding)
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
            .padding([.leading, .trailing], HomeSwimlane.horizontalPadding)
        }
    }
}

struct HomeTopicSwimlane: View {
    @ObservedObject var row: HomeTopicsAccessRow
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 40) {
                if row.topics.count > 0 {
                    ForEach(row.topics, id: \.uid) { topic in
                        TopicCell(topic: topic)
                    }
                }
                else {
                    ForEach(0..<10) { _ in
                        TopicCell(topic: nil)
                    }
                }
            }
            .padding([.leading, .trailing], HomeSwimlane.horizontalPadding)
        }
    }
}

struct HomeShowsAccessSwimlane: View {
    var row: HomeShowsAccessRow
    
    var body: some View {
        HStack {
            Button(action: { /* Open show list */ }) {
                Text("A to Z")
            }
            Button(action: { /* Open calendar */ }) {
                Text("By date")
            }
        }
    }
}

struct HomeSwimlaneHeader: View {
    let row: HomeRow
    
    var body: some View {
        if let title = row.title {
            Text(LocalizedStringKey(title))
                .font(.headline)
                .padding([.leading, .trailing], HomeSwimlane.horizontalPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
