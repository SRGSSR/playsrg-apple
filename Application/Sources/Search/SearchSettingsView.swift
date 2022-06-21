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
    @Binding var query: String
    @Binding var settings: SRGMediaSearchSettings
    
    @StateObject private var model = SearchSettingsViewModel()
    
    var body: some View {
        List {
            Picker(NSLocalizedString("Sort by", comment: "Search setting"), selection: $settings.sortCriterium) {
                Text(NSLocalizedString("Relevance", comment: "Search setting"))
                    .tag(SRGSortCriterium.default)
                Text(NSLocalizedString("Date", comment: "Search setting"))
                    .tag(SRGSortCriterium.date)
            }
            .pickerStyle(.inline)
            
            Picker(NSLocalizedString("Content", comment: "Search setting"), selection: $settings.mediaType) {
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
            .disabled(!model.hasTopicFilter)
            
            NavigationLink(NSLocalizedString("Shows", comment: "Search setting")) {
                Text("TODO")
            }
            .disabled(!model.hasShowFilter)
            
            Picker(NSLocalizedString("Period", comment: "Search setting"), selection: $model.period) {
                Text(NSLocalizedString("Anytime", comment: "Search setting option"))
                    .tag(SearchSettingsViewModel.Period.anytime)
                Text(NSLocalizedString("Today", comment: "Search setting option"))
                    .tag(SearchSettingsViewModel.Period.today)
                Text(NSLocalizedString("Yesterday", comment: "Search setting option"))
                    .tag(SearchSettingsViewModel.Period.yesterday)
                Text(NSLocalizedString("This week", comment: "Search setting option"))
                    .tag(SearchSettingsViewModel.Period.thisWeek)
                Text(NSLocalizedString("Last week", comment: "Search setting option"))
                    .tag(SearchSettingsViewModel.Period.lastWeek)
            }
            .pickerStyle(.inline)
            
            Picker(NSLocalizedString("Duration", comment: "Search setting"), selection: $model.duration) {
                Text(NSLocalizedString("Any", comment: "Search setting option"))
                    .tag(SearchSettingsViewModel.Duration.any)
                Text(NSLocalizedString("< 5 min", comment: "Search setting option"))
                    .tag(SearchSettingsViewModel.Duration.lessThanFiveMinutes)
                Text(NSLocalizedString("> 30 min", comment: "Search setting option"))
                    .tag(SearchSettingsViewModel.Duration.moreThanThirtyMinutes)
            }
            .pickerStyle(.inline)
            
            Toggle(NSLocalizedString("Downloadable", comment: "Search setting"), isOn: $model.downloadAvailable)
            Toggle(NSLocalizedString("Playable abroad", comment: "Search setting"), isOn: $model.playableAbroad)
            Toggle(NSLocalizedString("Subtitled", comment: "Search setting"), isOn: $model.subtitlesAvailable)
        }
        .srgFont(.body)
        .navigationTitle(NSLocalizedString("Filters", comment: "Search filters page title"))
        .onAppear {
            model.query = query
            model.settings = settings
        }
        .onChange(of: query) { newValue in
            model.query = newValue
        }
        .onChange(of: settings) { newValue in
            model.settings = newValue
        }
    }
}

// MARK: Preview

struct SearchSettingsPreviews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SearchSettingsView(query: .constant(""), settings: .constant(SRGMediaSearchSettings()))
        }
        .navigationViewStyle(.stack)
    }
}
