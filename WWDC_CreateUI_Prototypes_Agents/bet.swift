//
//  Bet.swift
//  NBABettingSimulator
//
//  Created by Karriem Lang on 9/13/26.
//

import Foundation
import SwiftData

/// Represents a placed wager (Straight, Parlay, or Teaser)
@Model
final class Bet {
    @Attribute(.unique) var id: UUID
    var datePlaced: Date
    var wagerTypeString: String // "Straight", "Parlay", "Teaser"
    var teaserPoints: Double // 0.0 for standard bets, or 4.0, 4.5, 5.0 for teasers
    var stake: Double
    var totalOdds: Int // Combined American Odds (e.g. +260, -110)
    var potentialPayout: Double
    var isSettled: Bool
    var statusString: String // "Pending", "Won", "Lost", "Push"
    
    @Relationship(deleteRule: .cascade) var legs: [BetLeg]
    
    init(
        id: UUID = UUID(),
        datePlaced: Date = Date(),
        wagerTypeString: String,
        teaserPoints: Double = 0.0,
        stake: Double,
        totalOdds: Int,
        potentialPayout: Double,
        isSettled: Bool = false,
        statusString: String = "Pending",
        legs: [BetLeg] = []
    ) {
        self.id = id
        self.datePlaced = datePlaced
        self.wagerTypeString = wagerTypeString
        self.teaserPoints = teaserPoints
        self.stake = stake
        self.totalOdds = totalOdds
        self.potentialPayout = potentialPayout
        self.isSettled = isSettled
        self.statusString = statusString
        self.legs = legs
    }
}

/// Represents an individual pick within a Bet (Single, Parlay leg, or Teaser leg)
@Model
final class BetLeg {
    @Attribute(.unique) var id: UUID
    var gameId: String
    var team1: String
    var team2: String
    var betTypeRaw: String // "spread", "overUnder", "moneyline"
    var selectionName: String // e.g. "BOS -4.5", "Over 224.5", "NYK +150"
    var line: Double // The handicap line used for settlement
    var baseOdds: Int
    var isWon: Bool? // nil = Pending, true = Won, false = Lost
    
    init(
        id: UUID = UUID(),
        gameId: String,
        team1: String,
        team2: String,
        betTypeRaw: String,
        selectionName: String,
        line: Double,
        baseOdds: Int,
        isWon: Bool? = nil
    ) {
        self.id = id
        self.gameId = gameId
        self.team1 = team1
        self.team2 = team2
        self.betTypeRaw = betTypeRaw
        self.selectionName = selectionName
        self.line = line
        self.baseOdds = baseOdds
        self.isWon = isWon
    }
}
