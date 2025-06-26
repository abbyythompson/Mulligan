import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    private let gamesKey = "savedGames"
    
    func saveGame(_ game: Game) {
        var games = loadGames()
        games.append(game)
        if let data = try? JSONEncoder().encode(games) {
            UserDefaults.standard.set(data, forKey: gamesKey)
        }
    }
    
    func loadGames() -> [Game] {
        guard let data = UserDefaults.standard.data(forKey: gamesKey),
              let games = try? JSONDecoder().decode([Game].self, from: data) else {
            return []
        }
        return games
    }
} 