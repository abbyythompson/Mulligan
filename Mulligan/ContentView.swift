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

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var games: [Game] = []
    @State private var showNewGame = false
    @State private var showChooseLocation = false
    @State private var showResumeRound = false
    @State private var inProgressRound: InProgressRoundManager.InProgressRound? = nil
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
                    VStack(spacing: 24) {
                        // Play suggestion card
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(inProgressRound != nil ? "Continue your round" : "Ready to play?")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text(inProgressRound != nil ? "Resume at \(inProgressRound!.course.name)" : "Start a round at")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                    Text(inProgressRound != nil ? inProgressRound!.course.name : suggestedCourse.name)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Text(inProgressRound != nil ? inProgressRound!.course.location : suggestedCourse.location)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.18))
                                        .frame(width: 60, height: 60)
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 34, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .padding(.top, 4)
                            }
                            .padding([.top, .horizontal])
                            Button(action: {
                                if inProgressRound != nil {
                                    showResumeRound = true
                                } else {
                                    showNewGame = true
                                }
                            }) {
                                HStack {
                                    Spacer()
                                    Text(inProgressRound != nil ? "Resume Round" : "Start Round")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                        .padding(.vertical, 14)
                                        .padding(.horizontal, 36)
                                    Spacer()
                                }
                                .background(
                                    Capsule()
                                        .fill(Color.white)
                                        .shadow(color: .green.opacity(0.18), radius: 8, y: 4)
                                )
                            }
                            .padding(.top, 18) 
                            .padding(.horizontal, 24)
                            // Subtle choose another course link
                            Button(action: { showChooseLocation = true }) {
                                Text("Not where you are? Choose another course.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .underline()
                                    .frame(maxWidth: .infinity)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 18)
                            }
                            .sheet(isPresented: $showChooseLocation) {
                                NewGameView(courseSuggestion: nil)
                            } 
                            .padding(.bottom, 18)
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
                        .sheet(isPresented: $showResumeRound) {
                            if let round = inProgressRound {
                                ScoreEntryView(course: round.course)
                            }
                        }
                        // Last two rounds at this location
                        if !gamesAtSuggestedCourse.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Last two rounds here")
                                    .font(.headline)
                                    .padding(.leading, 2)
                                HStack(spacing: 16) {
                                    ForEach(gamesAtSuggestedCourse.prefix(2)) { game in
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(game.date, style: .relative)
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                    Text(game.date, style: .date)
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                }
                                                Spacer()
                                                VStack(alignment: .trailing, spacing: 2) {
                                                    let par = game.course.holes.reduce(0) { $0 + $1.par }
                                                    let score = game.scores.reduce(0) { $0 + $1.strokes }
                                                    let diff = score - par
                                                    Text(diff > 0 ? "+\(diff)" : (diff < 0 ? "\(diff)" : "+0"))
                                                        .font(.headline)
                                                        .foregroundColor(diff > 0 ? .orange : (diff < 0 ? .green : .secondary))
                                                    Text("\(score)")
                                                        .font(.title2)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.primary)
                                                }
                                            }
                                        }
                                        .padding()
                                        .frame(width: 170)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.18), Color.white]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                                .shadow(color: Color.green.opacity(0.10), radius: 8, y: 4)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.green.opacity(0.5), lineWidth: 1)
                                        )
                                    }
                                }
                                .padding(.horizontal, 2)
                            }
                            .padding(.horizontal)
                        }
                        // All Recent Rounds (restored card/list style)
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
                inProgressRound = InProgressRoundManager.shared.load()
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
