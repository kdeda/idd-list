//
//  AppState.swift
//  TCATable
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation
import Combine
import ComposableArchitecture
import Log4swift
import IDDList
import SwiftUI

@Reducer
struct AppRoot {
    /// This is the state for the TableView
    struct State: Equatable, Identifiable {
        var id = UUID()
        var isAppReady = false
        var files: [File] = []
        // var rootURL = URL(fileURLWithPath: "/Volumes/Vault/Library/FoldersWithLotsOfFiles/18000 files")
        var rootURL = URL(fileURLWithPath: NSHomeDirectory())
        var lastBatch = 0
        @BindingState var selectedFiles: Set<File.ID> = []
        @BindingState var columnSort: ColumnSort<File> = .init(ascending: false, columnID: "fileName")
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case appDidStart
        case setFiles([File])
        case selectedFilesDidChange([File])
        case sortFiles(ColumnSort<File>)
        case loadAnotherBatch
        case removeSelection
    }

    @Dependency(\.fileClient) var fileClient

    init() {
    }

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            struct FilterLogMessagesID: Hashable {}

            switch action {
            case .binding(\.$selectedFiles):
                Log4swift[Self.self].info("selectedFiles: '\(state.selectedFiles.count)'")
//                let files = state.files.filter { state.selectedFiles.contains($0.id) }
//                return .send(.selectedFilesDidChange(files))
                return .none

            case .binding(\.$columnSort):
                return .send(.sortFiles(state.columnSort))

            case .binding:
                return .none

            case .appDidStart where !state.isAppReady:
                state.isAppReady = true

                return .run { [rootURL = state.rootURL] send in
                    await send(.setFiles(
                        await fileClient.fetchFiles(rootURL)
                    ))
                }

            case .appDidStart:
                return .none

            case let .setFiles(newValue):
                Log4swift[Self.self].info("files: '\(newValue.count)'")

                state.files.append(contentsOf: newValue)

                // preserve selection
                let newSelection_ = state.files.filter({ state.selectedFiles.contains($0.id) })
                let newSelection = Set(newSelection_.map(\.id))
                if newSelection != state.selectedFiles {
                    Log4swift[Self.self].info("newSelection: '\(newSelection)'")
                    state.selectedFiles = newSelection
                }
                return .send(.sortFiles(state.columnSort))

            case let .selectedFilesDidChange(newValue):
                state.selectedFiles = Set(newValue.map(\.id))
                return .none

            case let .sortFiles(columnSort):
                var startDate = Date()
                Log4swift[Self.self].info(".sortFiles: columnSort[\(columnSort.columnID)].ascending: '\(columnSort.ascending)'")

//                var files = state.files
//                files.sort(by: { lhs, rhs in
//                    lhs.physicalSize < rhs.physicalSize
//                })
//                // 1.98 seconds first time, .155 after ...
//                Log4swift[Self.self].info("sortFiles: '\(state.files.count) nodes' in: '\(startDate.elapsedTime) ms'")
//
                startDate = Date()
                var files2 = state.files
                files2.sort(by: { lhs, rhs in
                    let left = lhs[keyPath: \.physicalSize]
                    let right = rhs[keyPath: \.physicalSize]
                    return left < right
                })
                // 2.05 seconds first time, .155 after ...
                // so key path sorting is slightly slower
                Log4swift[Self.self].info("sortFiles: '\(state.files.count) nodes' in: '\(startDate.elapsedTime) ms'")

                startDate = Date()
                state.files.sort(by: columnSort.comparator)
                // 12 seconds first time, 1.5 after ...
                Log4swift[Self.self].info("sortFiles: '\(state.files.count) nodes' in: '\(startDate.elapsedTime) ms'")

                if state.selectedFiles.isEmpty {
                    // add one in here if you can
                    if state.files.count > 2 {
                        state.selectedFiles.insert(state.files[2].id)
                    }
                }
                return .none

            case .loadAnotherBatch:
                state.lastBatch += 1
                return .run { [rootURL = state.rootURL, batch = state.lastBatch] send in
                    await send(.setFiles(
                        await fileClient.loadAnotherBatch(rootURL, batch)
                    ))
                }
            case .removeSelection:
                state.files = state.files.reduce(into: [File](), { partialResult, nextItem in
                    guard !state.selectedFiles.contains(nextItem.id)
                    else { return }
                    partialResult.append(nextItem)
                })
                state.selectedFiles.removeAll()
                return .none

            }
        }
    }
}
