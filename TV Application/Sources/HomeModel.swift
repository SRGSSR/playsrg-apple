//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

class HomeModel: ObservableObject {
    // TODO: Will later be generated from application configuration
    private static let defaultRowIds: [HomeRow.Id] = [.trending, .latest, .latestForModule(nil, type: .event), .latestForTopic(nil)]
    
    private var eventRowIds: [HomeRow.Id] = []
    private var topicRowIds: [HomeRow.Id] = []
    
    @Published private(set) var rows = [HomeRow]()
    
    private var cancellables = Set<AnyCancellable>()
    
    private func addRow(with id: HomeRow.Id, to rows: inout [HomeRow]) {
        if let existingRow = self.rows.first(where: { $0.id == id }) {
            rows.append(existingRow)
        }
        else {
            rows.append(HomeRow(id: id))
        }
    }
    
    private func addRows(with ids: [HomeRow.Id], to rows: inout [HomeRow]) {
        for id in ids {
            addRow(with: id, to: &rows)
        }
    }
    
    private func synchronizeRows() {
        var updatedRows = [HomeRow]()
        for id in Self.defaultRowIds {
            if case let .latestForModule(_, type: type) = id, type == .event {
                addRows(with: eventRowIds, to: &updatedRows)
            }
            else if case .latestForTopic = id {
                addRows(with: topicRowIds, to: &updatedRows)
            }
            else {
                addRow(with: id, to: &updatedRows)
            }
        }
        rows = updatedRows
    }
    
    func loadRows(with ids: [HomeRow.Id]? = nil) {
        func reloadedRows(with ids: [HomeRow.Id]?) -> [HomeRow] {
            guard let ids = ids else { return rows }
            return rows.filter { ids.contains($0.id) }
        }
        
        for row in reloadedRows(with: ids) {
            if let cancellable = row.load() {
                cancellables.insert(cancellable)
            }
        }
    }
            
    func refresh() {
        cancellables = []
        
        self.synchronizeRows()
        self.loadRows()
        
        let vendor = ApplicationConfiguration.vendor
        let dataProvider = SRGDataProvider.current!
        
        dataProvider.modules(for: vendor, type: .event)
            .map { result in
                result.modules.map { HomeRow.Id.latestForModule($0, type: .event) }
            }
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .sink { rowIds in
                self.eventRowIds = rowIds
                self.synchronizeRows()
                self.loadRows(with: rowIds)
            }
            .store(in: &cancellables)
        
        dataProvider.tvTopics(for: vendor)
            .map { result in
                result.topics.map { HomeRow.Id.latestForTopic($0) }
            }
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .sink { rowIds in
                self.topicRowIds = rowIds
                self.synchronizeRows()
                self.loadRows(with: rowIds)
            }
            .store(in: &cancellables)
    }
}
