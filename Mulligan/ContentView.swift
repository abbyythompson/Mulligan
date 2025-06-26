//
//  ContentView.swift
//  Mulligan
//
//  Created by Abby Thompson on 26.06.2025.
//

import SwiftUI
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
}

struct CourseSuggestion {
    let name: String
    let location: String
    let latitude: Double
    let longitude: Double
}

let knownCourses: [CourseSuggestion] = [
    CourseSuggestion(name: "Pebble Beach Golf Links", location: "Pebble Beach, CA", latitude: 36.5680, longitude: -121.9500),
    CourseSuggestion(name: "St Andrews Old Course", location: "St Andrews, Scotland", latitude: 56.3432, longitude: -2.8032),
    CourseSuggestion(name: "Royal Mid-Surrey Golf Club", location: "Richmond, London", latitude: 51.4682, longitude: -0.3082),
    CourseSuggestion(name: "Richmond Golf Club", location: "Richmond, London", latitude: 51.4457, longitude: -0.2922),
    CourseSuggestion(name: "The Richmond Hill Golf Club", location: "Richmond, London", latitude: 51.4500, longitude: -0.3000),
    CourseSuggestion(name: "Fulwell Golf Club", location: "Twickenham, London", latitude: 51.4472, longitude: -0.3372),
    CourseSuggestion(name: "Dukes Meadows Golf", location: "Chiswick, London", latitude: 51.4842, longitude: -0.2587)
]

func nearestCourse(to location: CLLocation?) -> CourseSuggestion {
    guard let location = location else { return knownCourses[0] }
    return knownCourses.min(by: {
        let loc1 = CLLocation(latitude: $0.latitude, longitude: $0.longitude)
        let loc2 = CLLocation(latitude: $1.latitude, longitude: $1.longitude)
        return loc1.distance(from: location) < loc2.distance(from: location)
    }) ?? knownCourses[0]
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var games: [Game] = []
    @State private var showNewGame = false
    @State private var showChooseLocation = false
    @Namespace private var animation
    
    var suggestedCourse: CourseSuggestion {
        nearestCourse(to: locationManager.userLocation)
    }
    
    var gamesAtSuggestedCourse: [Game] {
        games.filter { $0.course.name == suggestedCourse.name }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.4), Color.white]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                GeometryReader { geo in
                    Circle()
                        .fill(Color.white.opacity(0.13))
                        .frame(width: geo.size.width * 0.8)
                        .position(x: geo.size.width * 0.8, y: geo.size.height * 0.1)
                        .blur(radius: 0.5)
                    Image(systemName: "flag.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(Color.green.opacity(0.08))
                        .rotationEffect(.degrees(-10))
                        .position(x: geo.size.width * 0.15, y: geo.size.height * 0.18)
                }
                .allowsHitTesting(false)
                ScrollView {
                    VStack(spacing: 36) {
                        // Golf icon at the top
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.7), Color.green]), startPoint: .top, endPoint: .bottom))
                                    .frame(width: 80, height: 80)
                                    .shadow(color: .green.opacity(0.25), radius: 10, y: 6)
                                Image(systemName: "figure.golf")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(.white)
                                    .shadow(color: .green.opacity(0.2), radius: 6, y: 2)
                            }
                            .frame(height: 80)
                            Text("Mulligan")
                                .font(.system(size: 36, weight: .heavy, design: .rounded))
                                .foregroundColor(.primary)
                                .shadow(color: .green.opacity(0.12), radius: 2, y: 1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 32)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(response: 0.7, dampingFraction: 0.7), value: locationManager.userLocation)
                        // Primary action area: Suggestion Card + Recent Rounds at this location
                        VStack(spacing: 0) {
                            // Suggestion Card
                            VStack(spacing: 0) {
                                HStack(alignment: .center) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Ready to play?")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text("Start a round at")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.8))
                                        Text(suggestedCourse.name)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        Text(suggestedCourse.location)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    Spacer()
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.15))
                                            .frame(width: 54, height: 54)
                                        Image(systemName: "location.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                                .padding([.top, .horizontal])
                                Button(action: { withAnimation { showNewGame = true } }) {
                                    HStack {
                                        Spacer()
                                        Text("Start Round")
                                            .font(.headline)
                                            .foregroundColor(.green)
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 36)
                                        Spacer()
                                    }
                                    .background(
                                        Capsule()
                                            .fill(Color.white)
                                            .shadow(color: .green.opacity(0.18), radius: 8, y: 4)
                                    )
                                    .scaleEffect(showNewGame ? 0.97 : 1.0)
                                }
                                .padding(.top, 18)
                                .padding(.bottom, 12)
                                .padding(.horizontal, 24)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showNewGame)
                            }
                            // Visually connected recent rounds
                            if !gamesAtSuggestedCourse.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "location.circle.fill")
                                            .foregroundColor(.white)
                                            .background(Circle().fill(Color.green).frame(width: 28, height: 28))
                                            .frame(width: 28, height: 28)
                                        Text("Recent Rounds at \(suggestedCourse.name)")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                    .padding(.leading)
                                    .padding(.top, 2)
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 18) {
                                            ForEach(gamesAtSuggestedCourse.prefix(5)) { game in
                                                GameCardViewConnected(game: game)
                                                    .transition(.scale)
                                                    .animation(.spring(), value: gamesAtSuggestedCourse.count)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                    .padding(.bottom, 12)
                                }
                                .background(Color.green.opacity(0.18))
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .padding([.horizontal, .bottom], 8)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(LinearGradient(gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: .green.opacity(0.22), radius: 16, y: 8)
                        )
                        .padding(.horizontal)
                        .sheet(isPresented: $showNewGame) {
                            NewGameView(courseSuggestion: suggestedCourse)
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.7), value: suggestedCourse.name)
                        Button(action: { showChooseLocation = true }) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Choose another course")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 24)
                            .background(Capsule().fill(Color(.systemGray6)))
                        }
                        .padding(.top, 4)
                        .sheet(isPresented: $showChooseLocation) {
                            NewGameView(courseSuggestion: nil)
                        }
                        // All Recent Rounds (remains visually distinct)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("All Recent Rounds")
                                .font(.headline)
                                .padding(.leading)
                                .transition(.opacity)
                            ForEach(games.sorted { $0.date > $1.date }.prefix(5)) { game in
                                GameListRowViewClean(game: game)
                                    .padding(.horizontal)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                    .animation(.easeInOut(duration: 0.5), value: games.count)
                            }
                        }
                        Spacer(minLength: 40)
                    }
                }
            }
            .onAppear {
                games = PersistenceManager.shared.loadGames()
            }
            .navigationBarHidden(true)
        }
    }
}

struct GameCardViewConnected: View {
    let game: Game
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
                Text(game.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text("Score: \(game.scores.reduce(0) { $0 + $1.strokes })")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text("Par: \(game.course.holes.reduce(0) { $0 + $1.par })")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.08), radius: 8, y: 4)
        )
        .frame(width: 150)
    }
}

struct GameCardViewClean: View {
    let game: Game
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
                Text(game.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text("Score: \(game.scores.reduce(0) { $0 + $1.strokes })")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text("Par: \(game.course.holes.reduce(0) { $0 + $1.par })")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.08), radius: 8, y: 4)
        )
        .frame(width: 150)
    }
}

struct GameListRowViewClean: View {
    let game: Game
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(game.course.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text(game.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Score: \(game.scores.reduce(0) { $0 + $1.strokes })")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                Text("Par: \(game.course.holes.reduce(0) { $0 + $1.par })")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.06), radius: 4, y: 2)
        )
    }
}

#Preview {
    ContentView()
}
