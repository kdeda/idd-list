//
//  AppRootView.swift
//  TCATable
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import Log4swift
import IDDList

struct AppRootView: View {
    let store: StoreOf<AppRoot>

    fileprivate func selectionString(count: Int) -> String {
        switch count {
        case 0:
            return "empty"
        case 1:
            return "one file"
        case _ where count > 1:
            return "\(count) files"
        default:
            return ""
        }
    }
    
    @ViewBuilder
    fileprivate func headerView() -> some View {
        WithViewStore(store) { viewStore in
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("This is the TCATable demo of the TableView.")
                        .font(.headline)
                    Text("It shows support for multiple row selection and TCA")
                        .font(.subheadline)
                    Text("Selection: ")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    +
                    Text(selectionString(count: viewStore.selectedFiles.count))
                        .font(.subheadline)
                }
                Spacer()
            }
            .padding(.all, 18)
        }
    }

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(spacing: 0) {
                headerView()
                    // .border(Color.yellow)
                Divider()
                IDDList(
                    viewStore.files,
                    multipleSelection: viewStore.binding(\.$selectedFiles),
                    columnSorts: viewStore.binding(\.$columnSorts)
                ) {
                    IDDColumn("File Size in Bytes", id: "File Size in Bytes") { rowValue in
                        Text(rowValue.physicalSize.decimalFormatted)
                            .font(.subheadline)
                    }
                    .frame(width: 130, alignment: .trailing)
                    .columnSort(compare: { $0.physicalSize < $1.physicalSize })

                    IDDColumn("On Disk", id: "On Disk") { rowValue in
                        Text(rowValue.logicalSize.compactFormatted)
                            .font(.subheadline)
                    }
                    .frame(width: 70, alignment: .trailing)
                    .columnSort(compare: { $0.logicalSize < $1.logicalSize })

                    IDDColumn("") { rowValue in
                        CellView { model in
                            Image(systemName: "magnifyingglass.circle.fill")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 12, height: 12, alignment: .center)
                                .foregroundColor(model.isHighlighted ? .none : .pink)
                                .font(.subheadline)
                                .padding(2)
                            //    .onTapGesture {
                            //        // this blocks the row selection ... WTF apple
                            //        Log4swift[Self.self].info("revealInFinder: \(file.filePath)")
                            //    }
                        }
                    }
                    .frame(width: 24, alignment: .center)

                    IDDColumn("Last Modified", id: "Last Modified") { rowValue in
                        Text(File.lastModified.string(from: rowValue.modificationDate))
                            .lineLimit(1)
                            .font(.subheadline)
                    }
                    .frame(width: 160)
                    .columnSort(compare: { $0.modificationDate < $1.modificationDate })

                    IDDColumn("File Name", id: "File Name") { rowValue in
                        Text("\(String(format: "[%04d] - [%@]", rowValue.id, rowValue.fileName))")
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .font(.subheadline)
                    }
                    .frame(minWidth: 140, ideal: 200, maxWidth: 280)
                    .columnSort(compare: { $0.fileName < $1.fileName })

                    IDDColumn("File Path", id: "File Path") { rowValue in
                        HStack {
                            Image(nsImage: rowValue.icon)
                                .resizable()
                                .frame(width: 18, height: 18)
                            // If we want pixel perfection than we adjust the height
                            // of this column to be the same as the icon column
                            Text(rowValue.filePath)
                                .lineLimit(1)
                                .font(.subheadline)
                        }
                    }
                    .frame(minWidth: 180, maxWidth: .infinity)
                    .columnSort(compare: { $0.filePath < $1.filePath })
                }
                .introspect { tableView, scrollView in
                    tableView.intercellSpacing = .init(width: 2, height: 1)
                    scrollView.hasHorizontalScroller = false
                    //  scrollView.scrollerInsets = .init(top: 0.0, left: 0.0, bottom: 14.0, right: 0.0)
                    // // scrollView.hasVerticalScroller = false
                    // scrollView.usesPredominantAxisScrolling = false
                }
                Divider()
                HStack {
                    Spacer()
                    Text("displaying \(viewStore.files.count) files and \(viewStore.selectedFiles.count) selected files")
                        .lineLimit(1)
                        .font(.subheadline)
                        .padding(.all, 8)
                }
                // .border(Color.yellow)
            }
            // from TableHeader.body tips
            // the intrinsic size should be 740 + (7 + 6) * 5 + 10 or 815
            .frame(minWidth: 815, minHeight: 480)
            .onAppear(perform: { viewStore.send(.appDidStart) })
        }
    }
}

struct AppRootView_Previews: PreviewProvider {
    static var previews: some View {
        AppRootView(store: Store(
            initialState: AppRoot.State.mock,
            reducer: AppRoot()
        ))
        .frame(width: 840)
        .frame(height: 640)
        .background(Color(NSColor.windowBackgroundColor))
        .environment(\.colorScheme, .light)
        
        AppRootView(store: Store(
            initialState: AppRoot.State.mock,
            reducer: AppRoot()
        ))
        .background(Color(NSColor.windowBackgroundColor))
        .environment(\.colorScheme, .dark)
    }
}
