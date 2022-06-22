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
            
            NavigationLink {
                SearchSettingsBucketsView(buckets: model.topicBuckets, bucketType: .topics, selections: $settings.topicURNs)
            } label: {
                HStack(spacing: 10) {
                    Text(NSLocalizedString("Topics", comment: "Search setting"))
                    if model.isLoadingFilters {
                        ProgressView()
                    }
                }
            }
            .disabled(model.isLoadingFilters || !model.hasTopicFilter)
            
            NavigationLink {
                SearchSettingsBucketsView(buckets: model.showsBuckets, bucketType: .shows, selections: $settings.showURNs)
            } label: {
                HStack(spacing: 10) {
                    Text(NSLocalizedString("Shows", comment: "Search setting"))
                    if model.isLoadingFilters {
                        ProgressView()
                    }
                }
            }
            .disabled(model.isLoadingFilters || !model.hasShowFilter)
            
            Picker(NSLocalizedString("Period", comment: "Search setting"), selection: $settings.period) {
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
            
            Picker(NSLocalizedString("Duration", comment: "Search setting"), selection: $settings.duration) {
                Text(NSLocalizedString("Any", comment: "Search setting option"))
                    .tag(SearchSettingsViewModel.Duration.any)
                Text(NSLocalizedString("< 5 min", comment: "Search setting option"))
                    .tag(SearchSettingsViewModel.Duration.lessThanFiveMinutes)
                Text(NSLocalizedString("> 30 min", comment: "Search setting option"))
                    .tag(SearchSettingsViewModel.Duration.moreThanThirtyMinutes)
            }
            .pickerStyle(.inline)
            
            Toggle(NSLocalizedString("Downloadable", comment: "Search setting"), isOn: $settings.downloadAvailable)
            Toggle(NSLocalizedString("Playable abroad", comment: "Search setting"), isOn: $settings.playableAbroad)
            if model.hasSubtitledFilter {
                Toggle(NSLocalizedString("Subtitled", comment: "Search setting"), isOn: $settings.subtitlesAvailable)
            }
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

// MARK: Binding transforms

private extension SRGMediaSearchSettings {
    private static func period(in settings: SRGMediaSearchSettings) -> SearchSettingsViewModel.Period {
        guard let fromDay = settings.fromDay, let toDay = settings.toDay else {
            return .anytime
        }
        
        let today = SRGDay.today
        let settingsRangeComponents = SRGDay.components(.day, from: fromDay, to: toDay)
        switch settingsRangeComponents.day {
        case 6:
            if today.play_isBetweenDay(fromDay, andDay: toDay) {
                return .thisWeek
            }
            else if SRGDay(byAddingDays: -7, months: 0, years: 0, to: today).play_isBetweenDay(fromDay, andDay: toDay) {
                return .lastWeek
            }
            else {
                return .anytime
            }
        case 0:
            if today == fromDay {
                return .today
            }
            else if SRGDay(byAddingDays: -1, months: 0, years: 0, to: today) == fromDay {
                return .yesterday
            }
            else {
                return .anytime
            }
        default:
            return .anytime
        }
    }
    
    private static func setPeriod(_ period: SearchSettingsViewModel.Period, in settings: SRGMediaSearchSettings) {
        switch period {
        case .anytime:
            settings.fromDay = nil
            settings.toDay = nil
        case .today:
            let today = SRGDay.today
            settings.fromDay = today
            settings.toDay = today
        case .yesterday:
            let yesterday = SRGDay(byAddingDays: -1, months: 0, years: 0, to: .today)
            settings.fromDay = yesterday
            settings.toDay = yesterday
        case .thisWeek:
            let firstDayOfThisWeek = SRGDay.start(for: .weekOfYear, containing: .today)
            settings.fromDay = firstDayOfThisWeek
            settings.toDay = SRGDay(byAddingDays: 6, months: 0, years: 0, to: firstDayOfThisWeek)
        case .lastWeek:
            let firstDayOfThisWeek = SRGDay.start(for: .weekOfYear, containing: .today)
            let firstDayOfLastWeek = SRGDay(byAddingDays: -6, months: 0, years: 0, to: firstDayOfThisWeek)
            settings.fromDay = firstDayOfLastWeek
            settings.toDay = SRGDay(byAddingDays: 6, months: 0, years: 0, to: firstDayOfLastWeek)
        }
    }
    
    var period: SearchSettingsViewModel.Period {
        get {
            return Self.period(in: self)
        }
        set {
            Self.setPeriod(newValue, in: self)
        }
    }
    
    var duration: SearchSettingsViewModel.Duration {
        get {
            if minimumDurationInMinutes == nil && maximumDurationInMinutes == nil {
                return .any
            }
            else if maximumDurationInMinutes == nil {
                return .moreThanThirtyMinutes
            }
            else {
                return .lessThanFiveMinutes
            }
        }
        set {
            switch newValue {
            case .any:
                minimumDurationInMinutes = nil
                maximumDurationInMinutes = nil
            case .lessThanFiveMinutes:
                minimumDurationInMinutes = nil
                maximumDurationInMinutes = 5
            case .moreThanThirtyMinutes:
                minimumDurationInMinutes = 30
                maximumDurationInMinutes = nil
            }
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
