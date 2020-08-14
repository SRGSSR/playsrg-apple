//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

class HomeModel: ObservableObject {
    private let rowIds = ApplicationConfiguration.rowIds
    
    private var eventRowIds: [HomeRow.Id] = []
    private var topicRowIds: [HomeRow.Id] = []
    
    @Published private(set) var rows = [HomeRow]()
    
    private var cancellables = Set<AnyCancellable>()
    
    func refresh() {
        cancellables = []
        
        synchronizeRows()
        loadRows()
        
        loadModules(with: .event)
        loadTopics()
    }
    
    private func addRow(with id: HomeRow.Id, to rows: inout [HomeRow]) {
        if let existingRow = self.rows.first(where: { $0.id == id }) {
            rows.append(existingRow)
        }
        else {
            rows.append(HomeRow.makeRow(for: id))
        }
    }
    
    private func addRows(with ids: [HomeRow.Id], to rows: inout [HomeRow]) {
        for id in ids {
            addRow(with: id, to: &rows)
        }
    }
    
    private func synchronizeRows() {
        var updatedRows = [HomeRow]()
        for id in rowIds {
            if case let .tvLatestForModule(_, type: type) = id, type == .event {
                addRows(with: eventRowIds, to: &updatedRows)
            }
            else if case .tvLatestForTopic = id {
                addRows(with: topicRowIds, to: &updatedRows)
            }
            else {
                addRow(with: id, to: &updatedRows)
            }
        }
        rows = updatedRows
    }
    
    private func loadRows(with ids: [HomeRow.Id]? = nil) {
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
    
    private func loadModules(with type: SRGModuleType) {
        guard rowIds.contains(.tvLatestForModule(nil, type: type)) else { return }
        
        SRGDataProvider.current!.modules(for: ApplicationConfiguration.vendor, type: type)
            .map { result in
                result.modules.map { HomeMediaRow.Id.tvLatestForModule($0, type: type) }
            }
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .sink { rowIds in
                self.eventRowIds = rowIds
                self.synchronizeRows()
                self.loadRows(with: rowIds)
            }
            .store(in: &cancellables)
    }
    
    private func loadTopics() {
        guard rowIds.contains(.tvLatestForTopic(nil)) else { return }
        
        SRGDataProvider.current!.tvTopics(for: ApplicationConfiguration.vendor)
            .map { result in
                result.topics.map { HomeMediaRow.Id.tvLatestForTopic($0) }
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
