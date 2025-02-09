//
//  ContentView.swift
//  MacTable
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import SwiftUI
import IDDList
import Log4swift

struct ContentView: View {
    var cars = Store.cars
    @State var rows = Store.cars
    @State var selection: Car.ID?
    /// The initial column sort
    @State var columnSort: ColumnSort<Car> = .init(ascending: false, columnID: "year")
    @State var showExtraColumn = false
    @State var categoryColumnTitle = "Category"
    
    fileprivate func selectionString() -> String {
        switch selection {
        case .none:
            return "empty"
        case let .some(carID):
            guard let car = rows.first(where: { $0.id == carID })
            else { return "empty"}
            return "\(car.make), \(car.model), \(car.year)"
        }
    }

    @ViewBuilder
    fileprivate func headerView() -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("This is the MacTable demo of the TableView package.")
                    .font(.headline)
                Text("It shows support for single row selection and vanilla swift bindings")
                    .font(.subheadline)
                Text("Selection: ")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                +
                Text(selectionString())
                    .font(.subheadline)
            }
            Spacer()
            VStack {
                Button(action: {
                    showExtraColumn.toggle()
                    categoryColumnTitle = showExtraColumn ? "CategoryExtra" : "Category"
                }) {
                    Text(showExtraColumn ? "Hide The Extra Column" : "Show The Extra Column")
                        .fontWeight(.semibold)
                }
                Button(action: {
                    let count = cars.count - 4
                    self.selection = cars[count].id
                }) {
                    Text("Scroll Selection To Visible")
                        .fontWeight(.semibold)
                }
                // .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.all, 18)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView()
            Divider()
            IDDList(
                rows,
                singleSelection: $selection,
                columnSort: Binding<ColumnSort<Car>>(
                    get: {
                        columnSort
                    }, set: { newValue in
                        self.columnSort = newValue

                        rows = rows.sorted(by: self.columnSort.comparator)
                        Log4swift[Self.self].info("sorted.rows: \(rows.count)")
                    }
                )
            ) {
                Column("Year", id: "year") { rowValue in
                    CellView { model in
                        Text("\(rowValue.year)")
                            .foregroundColor(model.isHighlighted ? .none : .secondary)
                    }
                }
                .columnSort(compare: { $0.year < $1.year })
                .frame(width: 60, alignment: .trailing)

                Column("Make", id: "make") { rowValue in
                    Text(rowValue.make)
                }
                .columnSort(compare: { $0.make < $1.make })
                .frame(width: 80, alignment: .trailing)

                Column("") { rowValue in
                    Text("")
                }
                .frame(width: 20)

                Column("Model", id: "model") { rowValue in
                    CellView { model in
                        Text("\(rowValue.model)")
                            .foregroundColor(model.isHighlighted ? .none : .yellow)
                    }
                }
                .columnSort(compare: { $0.model < $1.model })
                .frame(minWidth: 60, ideal: 80, maxWidth: 100)

                if showExtraColumn {
                    Column("Extra", id: "extra") { rowValue in
                        Text(rowValue.extraColumn)
                    }
                    .columnSort(compare: { $0.extraColumn < $1.extraColumn })
                    .frame(minWidth: 180, ideal: 180, maxWidth: 280)
                }

                Column(categoryColumnTitle, id: "category") { rowValue in
                    Text(rowValue.category)
                }
                .columnSort(compare: { $0.category < $1.category })
                .frame(minWidth: 180, ideal: 200, maxWidth: .infinity)
            }
            .heightOfRow({ rowValue in
                if rowValue.year == 2018 {
                    return 22.0
                }
                return 32.0
            })
            .id(showExtraColumn ? "showExtraColumn=true" : "showExtraColumn=false")
        }
        .frame(minWidth: 680, minHeight: 480)
        // .debug()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .background(Color(NSColor.windowBackgroundColor))
            .environment(\.colorScheme, .light)
        ContentView()
            .background(Color(NSColor.windowBackgroundColor))
            .environment(\.colorScheme, .dark)
    }
}
