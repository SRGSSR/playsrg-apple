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
    @Binding var settings: MediaSearchSettings
    
    @StateObject private var model = SearchSettingsViewModel()
    @Accessibility(\.isVoiceOverRunning) private var isVoiceOverRunning
    
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
            
            NavigationLink {
                SearchSettingsBucketsView(
                    title: NSLocalizedString("Topics", comment: "Topic list view in search settings"),
                    buckets: model.topicBuckets,
                    selectedUrns: $settings.topicUrns
                )
            } label: {
                HStack(spacing: 10) {
                    Text(NSLocalizedString("Topics", comment: "Search setting"))
                    if model.isLoadingFilters {
                        ProgressView()
                    }
                    if let selectedTopics = model.selectedTopics {
                        Spacer()
                        Text(selectedTopics)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .disabled(model.isLoadingFilters || !model.hasTopicFilter)
            
            NavigationLink {
                SearchSettingsBucketsView(
                    title: NSLocalizedString("Shows", comment: "Show list view in search settings"),
                    buckets: model.showBuckets,
                    selectedUrns: $settings.showUrns
                )
            } label: {
                HStack(spacing: 10) {
                    Text(NSLocalizedString("Shows", comment: "Search setting"))
                    if model.isLoadingFilters {
                        ProgressView()
                    }
                    if let selectedShows = model.selectedShows {
                        Spacer()
                        Text(selectedShows)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .disabled(model.isLoadingFilters || !model.hasShowFilter)
            
            Picker(NSLocalizedString("Period", comment: "Search setting"), selection: $settings.period) {
                Text(NSLocalizedString("Anytime", comment: "Search setting option"))
                    .tag(MediaSearchSettings.Period.anytime)
                Text(NSLocalizedString("Today", comment: "Search setting option"))
                    .tag(MediaSearchSettings.Period.today)
                Text(NSLocalizedString("Yesterday", comment: "Search setting option"))
                    .tag(MediaSearchSettings.Period.yesterday)
                Text(NSLocalizedString("This week", comment: "Search setting option"))
                    .tag(MediaSearchSettings.Period.thisWeek)
                Text(NSLocalizedString("Last week", comment: "Search setting option"))
                    .tag(MediaSearchSettings.Period.lastWeek)
            }
            .pickerStyle(.inline)
            
            Picker(NSLocalizedString("Duration", comment: "Search setting"), selection: $settings.duration) {
                Text(NSLocalizedString("Any", comment: "Search setting option"))
                    .tag(MediaSearchSettings.Duration.any)
                Text(NSLocalizedString("< 5 min", comment: "Search setting option"))
                    .tag(MediaSearchSettings.Duration.lessThanFiveMinutes)
                Text(NSLocalizedString("> 30 min", comment: "Search setting option"))
                    .tag(MediaSearchSettings.Duration.moreThanThirtyMinutes)
            }
            .pickerStyle(.inline)
            
            Toggle(NSLocalizedString("Downloadable", comment: "Search setting"), isOn: $settings.downloadAvailable)
            Toggle(NSLocalizedString("Playable abroad", comment: "Search setting"), isOn: $settings.playableAbroad)
            if model.hasSubtitledFilter {
                Toggle(NSLocalizedString("Subtitled", comment: "Search setting"), isOn: $settings.subtitlesAvailable)
            }
        }
        .srgFont(.body)
        .navigationBarTitleDisplayMode(isVoiceOverRunning ? .inline : .large)
        .navigationTitle(NSLocalizedString("Filters", comment: "Search filters page title"))
        .tracked(withTitle: analyticsPageTitle, levels: analyticsPageLevels)
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

// MARK: Analytics

private extension SearchSettingsView {
    private var analyticsPageTitle: String {
        return AnalyticsPageTitle.settings.rawValue
    }
    
    private var analyticsPageLevels: [String]? {
        return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.search.rawValue]
    }
}

// MARK: Preview

struct SearchSettings_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SearchSettingsView(query: .constant(""), settings: .constant(MediaSearchSettings()))
        }
        .navigationViewStyle(.stack)
    }
}
