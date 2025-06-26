import Foundation

struct Course: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let location: String
    let holes: [Hole]
}

struct Hole: Identifiable, Codable, Equatable {
    let id: UUID
    let number: Int
    let par: Int
}

struct Game: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let course: Course
    let scores: [Score]
}

struct Score: Identifiable, Codable, Equatable {
    let id: UUID
    let holeNumber: Int
    let strokes: Int
} 