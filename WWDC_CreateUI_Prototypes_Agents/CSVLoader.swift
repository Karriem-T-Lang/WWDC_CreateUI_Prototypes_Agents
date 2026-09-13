//
//  CSVLoader.swift
//  NBABettingSimulator
//
//  Created by Karriem Lang on 9/13/26.
//

import Foundation
import SwiftData

struct CSVLoader {
    
    /// Loads initial NBA game data from the bundled CSV file into the database.
    /// - Parameters:
    ///   - context: The `ModelContext` used for SwiftData persistence.
    ///   - forceReload: If `true`, re-imports data even if games already exist. Defaults to `false`.
    /// - Returns: The number of games imported.
    @discardableResult
    @MainActor
    static func loadInitialData(
        context: ModelContext,
        forceReload: Bool = false
    ) throws -> Int {
        // 1. Check if data is already loaded to avoid redundant work on app launch
        if !forceReload {
            let descriptor = FetchDescriptor<Game>()
            let existingCount = try context.fetchCount(descriptor)
            if existingCount > 0 {
                print("ℹ️ Database already contains \(existingCount) games. Skipping initial load.")
                return 0
            }
        }
        
        // 2. Locate the CSV file in the app bundle
        guard let fileURL = Bundle.main.url(forResource: "nba_clean01", withExtension: "csv") else {
            print("❌ CSV File 'nba_clean01.csv' not found in Bundle! Check Target Membership.")
            throw CocoaError(.fileNoSuchFile)
        }
        
        // 3. Read the file
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.split(whereSeparator: \.isNewline)
        
        var importedCount = 0
        
        // 4. Parse rows (skipping header at index 0)
        for (index, rawLine) in lines.enumerated() {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if index == 0 || line.isEmpty {
                continue
            }
            
            if let game = Game(csvLine: line) {
                context.insert(game)
                importedCount += 1
            }
        }
        
        // 5. Save changes
        try context.save()
        print("✅ Successfully imported and saved \(importedCount) games into SwiftData!")
        
        return importedCount
    }
}
