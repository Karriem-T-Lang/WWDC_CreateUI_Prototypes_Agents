//
//  Game.swift
//  NBABettingSimulator
//
//  Created by Karriem Lang on 9/13/26.
//

import Foundation
import SwiftData

/// Represents a single NBA game and its betting lines.
/// Saved persistently using SwiftData.
@Model
final class Game {
    // MARK: - Properties
    @Attribute(.unique) var id: String // e.g. "2024-10-22_New York Knicks_Boston Celtics"
    var dateString: String
    var date: Date
    var team1: String
    var team2: String
    var spreadTeam1: Double
    var overUnder: Double
    var moneyline1: Int
    var moneyline2: Int
    
    // Final game results (nil if game has not finished)
    var pointsTeam1: Int?
    var pointsTeam2: Int?
    var totalPoints: Int?
    var winLossTeam1: Int?
    var winLossTeam2: Int?

    // MARK: - Initializer
    init(
        dateString: String,
        date: Date? = nil,
        team1: String,
        team2: String,
        spreadTeam1: Double,
        overUnder: Double,
        moneyline1: Int,
        moneyline2: Int,
        pointsTeam1: Int? = nil,
        pointsTeam2: Int? = nil,
        totalPoints: Int? = nil,
        winLossTeam1: Int? = nil,
        winLossTeam2: Int? = nil
    ) {
        self.id = "\(dateString)_\(team1)_\(team2)"
        self.dateString = dateString
        self.date = date ?? Game.dateFormatter.date(from: dateString) ?? Date()
        self.team1 = team1
        self.team2 = team2
        self.spreadTeam1 = spreadTeam1
        self.overUnder = overUnder
        self.moneyline1 = moneyline1
        self.moneyline2 = moneyline2
        self.pointsTeam1 = pointsTeam1
        self.pointsTeam2 = pointsTeam2
        self.totalPoints = totalPoints
        self.winLossTeam1 = winLossTeam1
        self.winLossTeam2 = winLossTeam2
    }
}

// MARK: - Computed Properties & Betting Logic
extension Game {
    /// Indicates whether game results have been posted.
    var isFinished: Bool {
        pointsTeam1 != nil && pointsTeam2 != nil
    }

    /// The winning team's name (or `nil` if unfinished/tied).
    var winner: String? {
        guard let pts1 = pointsTeam1, let pts2 = pointsTeam2 else { return nil }
        if pts1 > pts2 { return team1 }
        if pts2 > pts1 { return team2 }
        return nil
    }

    /// Spread margin for Team 1 (Score diff + Spread).
    var spreadMargin: Double? {
        guard let pts1 = pointsTeam1, let pts2 = pointsTeam2 else { return nil }
        return Double(pts1 - pts2) + spreadTeam1
    }

    /// Returns `true` if Team 1 covered the spread, `false` if they didn't, or `nil` on a push / unfinished game.
    var didTeam1CoverSpread: Bool? {
        guard let margin = spreadMargin else { return nil }
        if margin == 0 { return nil } // Push
        return margin > 0
    }

    /// Returns `true` if total points exceeded over/under line, `false` if under, or `nil` on push / unfinished game.
    var isOverTotal: Bool? {
        guard let total = totalPoints ?? (pointsTeam1 != nil && pointsTeam2 != nil ? (pointsTeam1! + pointsTeam2!) : nil) else {
            return nil
        }
        let totalDouble = Double(total)
        if totalDouble == overUnder { return nil } // Push
        return totalDouble > overUnder
    }
}

// MARK: - CSV Parsing Helper
extension Game {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    /// Convenience initializer to parse directly from a CSV row in `nba_clean01.csv`.
    convenience init?(csvLine: String) {
        let cols = csvLine.split(separator: ",", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard cols.count >= 12,
              let spread = Double(cols[2]),
              let ou = Double(cols[4]),
              let ml1 = Int(cols[5]),
              let ml2 = Int(cols[6])
        else {
            return nil
        }

        let dateStr = cols[0]
        let team1 = cols[1]
        let team2 = cols[3]
        let pts1 = Int(cols[7])
        let pts2 = Int(cols[8])
        let totalPts = Int(cols[9])
        let wl1 = Int(cols[10])
        let wl2 = Int(cols[11])

        self.init(
            dateString: dateStr,
            team1: team1,
            team2: team2,
            spreadTeam1: spread,
            overUnder: ou,
            moneyline1: ml1,
            moneyline2: ml2,
            pointsTeam1: pts1,
            pointsTeam2: pts2,
            totalPoints: totalPts,
            winLossTeam1: wl1,
            winLossTeam2: wl2
        )
    }
}
