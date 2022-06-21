//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SRGDataProviderModel
import SwiftUI

// MARK: View

struct SearchSettingsView: View {
    @ObservedObject var model: SearchViewModel
    
    // TODO: Fill settings properly
    @State private var period: Period = .anytime
    @State private var duration: Duration = .any
    @State private var downloadAvailable: Bool = false
    @State private var playableAbroad: Bool = false
    @State private var subtitlesAvailable: Bool = false
    
    var body: some View {
        List {
            Picker(NSLocalizedString("Sort by", comment: "Search setting"), selection: $model.settings.sortCriterium) {
                Text(NSLocalizedString("Relevance", comment: "Search setting"))
                    .tag(SRGSortCriterium.default)
                Text(NSLocalizedString("Date", comment: "Search setting"))
                    .tag(SRGSortCriterium.date)
            }
            .pickerStyle(.inline)
            
            Picker(NSLocalizedString("Content", comment: "Search setting"), selection: $model.settings.mediaType) {
                Text(NSLocalizedString("All", comment: "Search setting option"))
                    .tag(SRGMediaType.none)
                Text(NSLocalizedString("Videos", comment: "Search setting option"))
                    .tag(SRGMediaType.video)
                Text(NSLocalizedString("Audios", comment: "Search setting option"))
                    .tag(SRGMediaType.audio)
            }
            .pickerStyle(.inline)
            
            NavigationLink(NSLocalizedString("Topics", comment: "Search setting")) {
                Text("TODO")
            }
            NavigationLink(NSLocalizedString("Shows", comment: "Search setting")) {
                Text("TODO")
            }
            
            Picker(NSLocalizedString("Period", comment: "Search setting"), selection: $period) {
                Text(NSLocalizedString("Anytime", comment: "Search setting option"))
                    .tag(Period.anytime)
                Text(NSLocalizedString("Today", comment: "Search setting option"))
                    .tag(Period.today)
                Text(NSLocalizedString("Yesterday", comment: "Search setting option"))
                    .tag(Period.yesterday)
                Text(NSLocalizedString("This week", comment: "Search setting option"))
                    .tag(Period.thisWeek)
                Text(NSLocalizedString("Last week", comment: "Search setting option"))
                    .tag(Period.lastWeek)
            }
            .pickerStyle(.inline)
            
            Picker(NSLocalizedString("Duration", comment: "Search setting"), selection: $duration) {
                Text(NSLocalizedString("Any", comment: "Search setting option"))
                    .tag(Duration.any)
                Text(NSLocalizedString("< 5 min", comment: "Search setting option"))
                    .tag(Duration.lessThanFiveMinutes)
                Text(NSLocalizedString("> 30 min", comment: "Search setting option"))
                    .tag(Duration.moreThanThirtyMinutes)
            }
            .pickerStyle(.inline)
            
            Toggle(NSLocalizedString("Downloadable", comment: "Search setting"), isOn: $downloadAvailable)
            Toggle(NSLocalizedString("Playable abroad", comment: "Search setting"), isOn: $playableAbroad)
            Toggle(NSLocalizedString("Subtitled", comment: "Search setting"), isOn: $subtitlesAvailable)
        }
        .srgFont(.body)
        .navigationTitle(NSLocalizedString("Filters", comment: "Search filters page title"))
    }
}

// MARK: Types

private extension SearchSettingsView {
    enum Period {
        case anytime
        case today
        case yesterday
        case thisWeek
        case lastWeek
    }
    
    enum Duration {
        case any
        case lessThanFiveMinutes
        case moreThanThirtyMinutes
    }
}

// MARK: Preview

struct SearchSettingsPreviews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SearchSettingsView(model: SearchViewModel())
        }
        .navigationViewStyle(.stack)
    }
}
