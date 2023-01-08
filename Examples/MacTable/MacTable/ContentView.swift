//
//  ContentView.swift
//  MacTable
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import SwiftUI
import IDDList
import Log4swift

struct ContentView: View {
    var cars = Store.cars
    @State var rows = Store.cars
    @State var selection: Car.ID?
    /// The initial column sort
    @State var columnSorts: [ColumnSort<Car>] = [
        .init(compare: { $0.year < $1.year }, ascending: true, columnID: "Year")
    ]
    @State var showExtraColumn = false
    
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
                columnSorts: Binding<[ColumnSort<Car>]>(
                    get: {
                        columnSorts
                    }, set: { newValue in
                        self.columnSorts = newValue

                        let sortDescriptor = columnSorts[0]
                        rows = rows.sorted(by: sortDescriptor.comparator)
                        Log4swift[Self.self].info("sorted.rows: \(rows.count)")
                    }
                )
            ) {
                Column("Year", id: "Year") { rowValue in
                    CellView { model in
                        Text("\(rowValue.year)")
                            .foregroundColor(model.isHighlighted ? .none : .secondary)
                    }
                }
                .columnSort(compare: { $0.year < $1.year })
                .frame(width: 60, alignment: .trailing)

                Column("Make", id: "Make") { rowValue in
                    Text(rowValue.make)
                }
                .columnSort(compare: { $0.make < $1.make })
                .frame(width: 80, alignment: .trailing)

                Column("") { rowValue in
                    Text("")
                }
                .frame(width: 20)

                Column("Model", id: "Model") { rowValue in
                    CellView { model in
                        Text("\(rowValue.model)")
                            .foregroundColor(model.isHighlighted ? .none : .yellow)
                    }
                }
                .columnSort(compare: { $0.model < $1.model })
                .frame(minWidth: 60, ideal: 80, maxWidth: 100)

                if showExtraColumn {
                    Column("Extra", id: "Extra") { rowValue in
                        Text(rowValue.extraColumn)
                    }
                    .columnSort(compare: { $0.extraColumn < $1.extraColumn })
                    .frame(minWidth: 160)
                }

                Column("Category", id: "Category") { rowValue in
                    Text(rowValue.category)
                }
                .columnSort(compare: { $0.category < $1.category })
                .frame(minWidth: 180, ideal: 200, maxWidth: .infinity)
            }
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
