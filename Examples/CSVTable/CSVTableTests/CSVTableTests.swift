//
//  CSVTableTests.swift
//  CSVTableTests
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2024 id-design, inc. All rights reserved.
//

import ComposableArchitecture
import CustomDump
import Log4swift
import IDDList
import XCTest
@testable import CSVTable

@MainActor
class CSVTableTests: XCTestCase {
    override func setUp() {
        super.setUp()

        // Log4swift.configure(appName: "WhatSize")
        // Log4swift[Self.self].info("\(String(repeating: "-", count: Bundle.main.appVersion.shortDescription.count))")
        // Log4swift[Self.self].info("\(Bundle.main.appVersion.shortDescription)")
        Log4swift[Self.self].info("\(String(repeating: "-", count: Bundle.main.appVersion.shortDescription.count))")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    /**
     Create a possible CSV
     */
    fileprivate func createCSVRows(rowCount: Int, columnCount: Int, separator: String) -> [CSVRow] {
        var csvRows: [CSVRow] = (0 ..< rowCount).map { row in
            let rowID = Int.random(in: ( 1968 ... 2068))

            let columns: [String] = (0 ..< columnCount).map { column in
                let columnID = Int.random(in: ( 1968 ... 2068))
                let uuid = UUID().uuidString
                let firstSpace = uuid.firstIndex(of: "-") ?? uuid.endIndex
                let randomValue = uuid[...firstSpace]
                let column = "\(columnID)-\(rowID)-\(randomValue)"

                return column
            }
            return CSVRow.init(id: 0, columns: columns)
        }

        let columnNames: [String] = (0 ..< columnCount).map { "Column-\(String(format: "%03d", $0))" }
        let header = CSVRow.init(id: 0, columns: columnNames)
        csvRows.insert(header, at: 0)

        csvRows.sort { $0.columns[0] > $1.columns[0] }
        Log4swift[Self.self].info("created csv with: '\(csvRows.count) rows'")
        return csvRows.updateIDs()
    }

    /**
     Test the csv at url with the expected rows.
     These should match
     */
    fileprivate func testCSV(csvURL: URL, expectedRows: [CSVRow]) async throws -> Void {
        Log4swift[Self.self].info("filePath: '\(csvURL.path)'")

        let state = AppRoot.State()
        let store = TestStore(initialState: state) {
            AppRoot()
        } withDependencies: {
            $0.csvClient = .liveValue
        }

        store.exhaustivity = .off

        Log4swift[Self.self].info("...")
        await store.send(.load(csvURL))
        await store.receive(\.fileDidLoad)
        await store.receive(\.sortFiles)

        var rows = store.state.rows
        rows.sort { $0.columns[0] > $1.columns[0] }
        Log4swift[Self.self].info("loaded csv file: '\(csvURL.path)' with: '\(rows.count) rows'")

        if let deltas = diff(rows, expectedRows, format: .proportional) {
            Log4swift[Self.self].info("changes: '\(deltas)'")
        }

        XCTAssertEqual(rows, expectedRows)
    }

    /**
     Do some quick tests
     Create CSV array 2x2
     Store it as a file
     Use the AppRoot to load it and assert on it
     */
    func testCSV2x2() async throws {
        let separator = ","
        let csvRows = createCSVRows(rowCount: 2, columnCount: 2, separator: separator)
        let csvData = csvRows.csvData(separator: separator)
        let csvURLRoot = URL.temporaryDirectory.appendingPathComponent("CSVTable")
        let csvURL = csvURLRoot.appendingPathComponent("2x2.csv")

        try? FileManager.default.createDirectory(at: csvURLRoot, withIntermediateDirectories: false)
        try? csvData.write(to: csvURL)
        Log4swift[Self.self].info("created csv file: '\(csvURL.path)' with: '\(csvRows.count) rows'")

        // make sure file is there
        XCTAssertEqual(csvURL.fileExist, true)
        XCTAssertEqual(csvURL.logicalSize, Int64(csvData.count))

        try await testCSV(csvURL: csvURL, expectedRows: csvRows)
        Log4swift[Self.self].info("completed")
    }

    /**
     Do some quick tests
     Create CSV array 3x3, with crap rows in the front
     Store it as a file
     Use the AppRoot to load it and assert on it
     */
    func testCSV3x3xCrapInFront() async throws {
        let separator = ","
        let csvRows = createCSVRows(rowCount: 3, columnCount: 3, separator: separator)

        // these are part of the CSV file but should be ignored when we parse the CSV
        let crapInFront = """
        FooBar, Hello World
        not part of the CSV

        """

        let csvData = {
            var data = crapInFront.data(using: .utf8) ?? Data()

            data.append(csvRows.csvData(separator: separator))
            return data
        }()
        let csvURLRoot = URL.temporaryDirectory.appendingPathComponent("CSVTable")
        let csvURL = csvURLRoot.appendingPathComponent("3x3xCrap.csv")

        try? FileManager.default.createDirectory(at: csvURLRoot, withIntermediateDirectories: false)
        try? csvData.write(to: csvURL)
        Log4swift[Self.self].info("created csv file: '\(csvURL.path)' with: '\(csvRows.count) rows'")

        // make sure file is there
        XCTAssertEqual(csvURL.fileExist, true)
        XCTAssertEqual(csvURL.logicalSize, Int64(csvData.count))

        try await testCSV(csvURL: csvURL, expectedRows: csvRows)
        Log4swift[Self.self].info("completed")
    }

}
