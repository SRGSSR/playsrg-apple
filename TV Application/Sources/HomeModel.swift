//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine

class HomeModel: ObservableObject {
    private static let rowIds: [HomeRow.Id] = [.trending, .latest, .topics]
    
    @Published private(set) var rows = [HomeRow]()
    var cancellables = Set<AnyCancellable>()
    
    func findRow(id: HomeRow.Id) -> HomeRow? {
        return rows.first(where: { $0.id == id })
    }
    
    func updateRows(topicRows: [HomeRow] = []) {
        var updatedRows = [HomeRow]()
        
        for id in Self.rowIds {
            if id == .topics {
                for row in topicRows {
                    if let existingRow = findRow(id: row.id) {
                        updatedRows.append(existingRow)
                    }
                    else {
                        updatedRows.append(row)
                    }
                }
            }
            else {
                if let existingRow = findRow(id: id) {
                    updatedRows.append(existingRow)
                }
                else {
                    updatedRows.append(HomeRow(id: id))
                }
            }
        }
        
        rows = updatedRows
    }
    
    init() {
        updateRows()
    }
    
    func refresh(rows: [HomeRow]) {
        for row in rows {
            if let cancellable = row.load() {
                cancellables.insert(cancellable)
            }
        }
    }
    
    func refresh() {
        cancellables = []
        self.refresh(rows: rows)
        
        SRGDataProvider.current!.tvTopics(for: .RTS)
            .map {
                return $0.0.map { HomeRow(id: .latestForTopic($0)) }
            }
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .sink { topicRows in
                self.updateRows(topicRows: topicRows)
                self.refresh(rows: topicRows)
            }
            .store(in: &cancellables)
    }
}
