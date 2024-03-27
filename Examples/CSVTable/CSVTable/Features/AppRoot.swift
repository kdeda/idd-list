//
//  AppState.swift
//  CSVTable
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation
import Combine
import ComposableArchitecture
import Log4swift
import IDDList

@Reducer
struct AppRoot {
    @ObservableState
    struct State: Equatable {
        enum DropStatus: Equatable {
            case none
            case dragInProgress
            case loading(URL)
            case loaded(URL)
        }

        var rows: [CSVRow] = []
        var columns: [String] = []
        var selectedRows: Set<CSVRow.ID> = []
        var columnSort: ColumnSort<CSVRow> = .init(ascending: false, columnID: "fileName")
        var dropStatus: DropStatus = .none

        var dragInProgress: Bool {
            switch dropStatus {
            case .none:           return false
            case .dragInProgress: return true
            case .loading:        return false
            case .loaded:         return false
            }
        }

        var isLoading: Bool {
            if case .loading = dropStatus {
                return true
            }
            return false
        }

        var headerTitle: String {
            switch dropStatus {
            case .none:           return "Drag a CSV file in this view and let it rip."
            case .dragInProgress: return "That's it, drop it now."
            case .loading:        return "Loading ..."
            case .loaded:         return "Loaded"
            }
        }

        var filePath: String {
            switch dropStatus {
            case .none:                 return ""
            case .dragInProgress:       return ""
            case let .loading(fileURL): return fileURL.path
            case let .loaded(fileURL):  return fileURL.path
            }
        }
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case appDidStart
        case setDragInProgress(Bool)
        case selectedRowsDidChange([CSVRow])
        case sortFiles
        case cancelLoad
        case load(URL)
        case appendRows([CSVRow])
        case fileDidLoad(URL)

    }

    fileprivate enum CancelID: Hashable {
        case loading
    }

    @Dependency(\.csvClient) var csvClient

    init() {
    }

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding(\.selectedRows):
                Log4swift[Self.self].info("selectedRows: '\(state.selectedRows.count)'")
                return .none

            case .binding(\.columnSort):
                return .send(.sortFiles)

            case .binding:
                return .none

            case .appDidStart:
                return .none

            case let .setDragInProgress(newValue):
                // don't switch if we are loading
                if case .loading = state.dropStatus {
                    Log4swift[Self.self].info("setDragInProgress: '\(newValue)' NOPE")
                    return .none
                }
                state.dropStatus = newValue ? .dragInProgress : .none
                Log4swift[Self.self].info("setDragInProgress: '\(newValue)' YUUP")
                return .none

            case let .selectedRowsDidChange(newValue):
                state.selectedRows = Set(newValue.map(\.id))
                return .none

            case .sortFiles:
                state.rows.sort(by: state.columnSort.comparator)
                return .none

            case .cancelLoad:
                state.dropStatus = .none
                state.selectedRows.removeAll()
                state.rows.removeAll()
                state.columns.removeAll()
                return .cancel(id: CancelID.loading)

            case let .load(fileURL):
                Log4swift[Self.self].info("load: '\(fileURL.path)'")

                if state.isLoading {
                    return .none
                }

                state.dropStatus = .loading(fileURL)
                state.selectedRows.removeAll()
                state.rows.removeAll()
                state.columns.removeAll()
                return .run { send in
                    for await rows in csvClient.parseCSVFile(fileURL) {
                        await send(.appendRows(rows))
                    }
                    await send(.fileDidLoad(fileURL))
                }
                .cancellable(id: CancelID.loading, cancelInFlight: true)

            case let .appendRows(newRows):
                if state.columns.isEmpty {
                    // columns should be the first CSV row
                    // but such that it has the same column count than anyother rows after it
                    // this gets rid of say the first rows of a CSV that have meta data
                    if let last = newRows.last(where: { $0.columns.count > 1}) {
                        let columnCount = last.columns.count
                        if let columnNames = newRows.first(where: { $0.columns.count == columnCount}) {
                            state.columns = columnNames.columns
                            state.columnSort = .init(ascending: false, columnID: columnNames.columns[0])
                        }
                    }
                }

                newRows.forEach { row in
                    if row.columns.count == state.columns.count {
                        var copy = row
                        copy.id = state.rows.count
                        state.rows.append(copy)
                    }
                }
                return .none

            case let .fileDidLoad(fileURL):
                Log4swift[Self.self].info("load: '\(fileURL.path)'")

                state.dropStatus = .loaded(fileURL)
                return .send(.sortFiles)

            }
        }
    }
}
