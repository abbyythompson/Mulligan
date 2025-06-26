import SwiftUI

struct HistoryView: View {
    @State private var games: [Game] = []
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Game History")
                .font(.largeTitle)
                .padding(.top)
            if games.isEmpty {
                Text("No games saved yet.")
                    .foregroundColor(.secondary)
            } else {
                List(games.sorted { $0.date > $1.date }) { game in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(game.course.name)
                            .font(.headline)
                        Text("Date: \(game.date.formatted(date: .abbreviated, time: .omitted))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Score: \(game.scores.reduce(0) { $0 + $1.strokes }) | Par: \(game.course.holes.reduce(0) { $0 + $1.par })")
                            .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
            Spacer()
        }
        .padding()
        .onAppear {
            games = PersistenceManager.shared.loadGames()
        }
    }
} 