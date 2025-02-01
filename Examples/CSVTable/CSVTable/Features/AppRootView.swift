//
//  AppRootView.swift
//  CSVTable
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import Log4swift
import IDDList
import UniformTypeIdentifiers

struct AppRootView: View {
    @Perception.Bindable var store: StoreOf<AppRoot>

    @ViewBuilder
    fileprivate func headerView() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text(store.headerTitle)
                    .font(.title)

                if store.filePath.isEmpty {
                    Text("Note: ")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    +
                    Text("Please drop a .csv file.")
                        .font(.subheadline)
                } else {
                    Text("Path: ")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    +
                    Text(store.filePath)
                        .font(.subheadline)
                }
            }
            Spacer()
            VStack {
                if store.isLoading {
                    Button(action: {
                        store.send(.cancelLoad)
                    }) {
                        Text("Cancel this load")
                            .fontWeight(.semibold)
                    }
                } else {
                    Text("")
                }
            }
        }
    }

    @MainActor
    @ViewBuilder
    fileprivate func tableView() -> some View {
        IDDList(
            store.rows,
            multipleSelection: $store.selectedRows,
            columnSort: $store.columnSort
        ) {
            for columnIndex in (0 ..< store.columns.count) {
                Column(store.columns[columnIndex], id: store.columns[columnIndex]) { rowValue in
                    Text(rowValue[dynamicMember: "\(columnIndex)"])
                }
                .columnSort(compare: { $0.compareByColumIndex($1, columnIndex: columnIndex) })
                .frame(minWidth: 180, ideal: 180, maxWidth: 280)
            }

            // declare columns in usual fashion
            //
            //  Column("Column1", id: "column1") { rowValue in
            //      Text(rowValue.column1)
            //          .font(.subheadline)
            //  }
            //  .frame(width: 130, alignment: .trailing)
            //  .columnSort(compare: { $0.column1 < $1.column1 })
            //
            //  Column("Column2", id: "column2") { rowValue in
            //      Text(rowValue.column2)
            //          .font(.subheadline)
            //  }
            //  .frame(minWidth: 180, maxWidth: .infinity)
            //  .columnSort(compare: { $0.column2 < $1.column2 })
        }
        .introspect { tableView, scrollView in
            tableView.intercellSpacing = .init(width: 10, height: 1)
            scrollView.hasHorizontalScroller = false
            //  scrollView.scrollerInsets = .init(top: 0.0, left: 0.0, bottom: 14.0, right: 0.0)
            // // scrollView.hasVerticalScroller = false
            // scrollView.usesPredominantAxisScrolling = false
        }
        .id(store.columns.count)
    }

    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 0) {
                headerView()
                    // .border(.yellow)
                    .padding(.bottom, 20)

                switch store.dropStatus {
                case .none, .dragInProgress:
                    Divider()
                        .padding(.vertical, 5)
                    Spacer()
                case .loading, .loaded:
                    tableView()
                        .border(.gray.opacity(0.3))
                }

                HStack {
                    Spacer()
                    Text("displaying \(store.rows.count) files and \(store.selectedRows.count) selected files")
                        .lineLimit(1)
                        .font(.subheadline)
                        .padding(.all, 10)
                }
                // .border(.yellow)
            }
            .frame(minWidth: 800, minHeight: 480)
            .onAppear(perform: { store.send(.appDidStart) })
            .border(store.dragInProgress ? .yellow : .clear, width: 3)
            .padding(.top, 20)
            .padding(.horizontal, 20)
            .onDrop(of: [UTType.fileURL], isTargeted: $store.dragInProgress.sending(\.setDragInProgress)) { providers in
                providers.forEach { provider in
                    _ = provider.loadObject(ofClass: URL.self) { url, _ in
                        if let url {
                            DispatchQueue.main.async {
                                Log4swift[Self.self].info("url: '\(url.path)'")
                                store.send(.load(url))
                            }
                        }
                    }
                }
                return true
            }
        }
    }
}

@MainActor
fileprivate func store() -> StoreOf<AppRoot> {
    let state = AppRoot.State()

    return Store(
        initialState: state,
        reducer: AppRoot.init
    )
}

#Preview("AppRootView - Light") {
    AppRootView(store: store())
        .preferredColorScheme(.light)
}

#Preview("AppRootView - Dark") {
    AppRootView(store: store())
        .preferredColorScheme(.dark)
}


extension AppRoot.State {
    static var mock: Self {
        let rv = AppRoot.State()

        return rv
    }
}
