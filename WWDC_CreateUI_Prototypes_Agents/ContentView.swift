//
//  ContentView.swift
//  NBABettingSimulator
//
//  Created by Karriem Lang on 9/13/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Fetch all games from SwiftData, ordered chronologically
    @Query(sort: \Game.date) private var games: [Game]
    
    // Simulation State
    @State private var bankroll: Double = 1000.00
    @State private var currentDateIndex: Int = 0
    
    /// Unique dates extracted once per render pass
    private var uniqueDates: [String] {
        var seen = Set<String>()
        return games.compactMap { game in
            seen.insert(game.dateString).inserted ? game.dateString : nil
        }
    }
    
    /// Current selected date string
    private var currentDateString: String {
        let dates = uniqueDates
        guard !dates.isEmpty, currentDateIndex < dates.count else {
            return "2024-10-22"
        }
        return dates[currentDateIndex]
    }
    
    /// Games for the currently selected date
    private var todaysGames: [Game] {
        let activeDate = currentDateString
        return games.filter { $0.dateString == activeDate }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Bankroll & Date Header
                headerCard
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Date Navigation Bar
                dateNavigationBar
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                // Games List
                if todaysGames.isEmpty {
                    ContentUnavailableView(
                        "No Games Scheduled",
                        systemImage: "basketball",
                        description: Text("No games found for \(currentDateString).")
                    )
                } else {
                    List(todaysGames) { game in
                        GameRowView(game: game)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("NBA Simulator")
            .task {
                do {
                    try CSVLoader.loadInitialData(context: modelContext)
                } catch {
                    print("❌ Failed to load initial CSV data: \(error)")
                }
            }
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bankroll")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(bankroll, format: .currency(code: "USD"))
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.green)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Current Date")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(currentDateString)
                    .font(.headline)
            }
        }
        .padding()
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Date Navigation Controls
    private var dateNavigationBar: some View {
        let totalDays = uniqueDates.count
        return HStack {
            Button {
                if currentDateIndex > 0 {
                    currentDateIndex -= 1
                }
            } label: {
                Label("Previous Day", systemImage: "chevron.left")
                    .labelStyle(.iconOnly)
            }
            .disabled(currentDateIndex == 0)
            
            Spacer()
            
            Text("Day \(currentDateIndex + 1) of \(max(totalDays, 1))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button {
                if currentDateIndex < totalDays - 1 {
                    currentDateIndex += 1
                }
            } label: {
                Label("Next Day", systemImage: "chevron.right")
                    .labelStyle(.iconOnly)
            }
            .disabled(currentDateIndex >= totalDays - 1)
        }
        .buttonStyle(.bordered)
    }
}

// MARK: - Game Row View
struct GameRowView: View {
    let game: Game
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Matchup Header & Hidden Score Status
            HStack {
                Text("\(game.team1) @ \(game.team2)")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                // Keep score hidden for upcoming simulation games
                Text("UPCOMING")
                    .font(.caption2)
                    .bold()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
            
            Divider()
            
            // Sportsbook Odds Cards (Spread | Total | Moneyline)
            HStack(spacing: 8) {
                // 1. SPREAD
                oddsBox(
                    title: "SPREAD",
                    line1: "\(game.team1) \(formatSpread(game.spreadTeam1))",
                    line2: "\(game.team2) \(formatSpread(-game.spreadTeam1))"
                )
                
                // 2. TOTAL (O/U)
                oddsBox(
                    title: "TOTAL",
                    line1: String(format: "O %.1f", game.overUnder),
                    line2: String(format: "U %.1f", game.overUnder)
                )
                
                // 3. MONEYLINE
                oddsBox(
                    title: "MONEYLINE",
                    line1: "\(game.team1) \(formatML(game.moneyline1))",
                    line2: "\(game.team2) \(formatML(game.moneyline2))"
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
    
    // MARK: - Helper UI Components
    
    @ViewBuilder
    private func oddsBox(title: String, line1: String, line2: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .bold()
                .foregroundStyle(.secondary)
            
            VStack(spacing: 2) {
                Text(line1)
                    .font(.caption)
                    .bold()
                Text(line2)
                    .font(.caption)
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
    
    // MARK: - Formatting Helpers
    
    private func formatSpread(_ spread: Double) -> String {
        spread > 0 ? "+\(spread)" : "\(spread)"
    }
    
    private func formatML(_ ml: Int) -> String {
        ml > 0 ? "+\(ml)" : "\(ml)"
    }
}

// MARK: - Instant Preview Container
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Game.self, configurations: config)
    
    let sample1 = Game(
        dateString: "2024-10-22",
        team1: "New York Knicks",
        team2: "Boston Celtics",
        spreadTeam1: 6.0,
        overUnder: 221.5,
        moneyline1: 205,
        moneyline2: -250,
        pointsTeam1: 109,
        pointsTeam2: 132,
        totalPoints: 241,
        winLossTeam1: 0,
        winLossTeam2: 1
    )
    let sample2 = Game(
        dateString: "2024-10-22",
        team1: "Minnesota Timberwolves",
        team2: "Los Angeles Lakers",
        spreadTeam1: -1.0,
        overUnder: 224.0,
        moneyline1: -116,
        moneyline2: -102,
        pointsTeam1: 103,
        pointsTeam2: 110,
        totalPoints: 213,
        winLossTeam1: 0,
        winLossTeam2: 1
    )
    container.mainContext.insert(sample1)
    container.mainContext.insert(sample2)
    
    return ContentView()
        .modelContainer(container)
}
