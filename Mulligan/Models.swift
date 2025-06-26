import Foundation
import CoreLocation

/// Represents a golf course.
struct Course: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let location: String
    let holes: [Hole]
}

/// Represents a single hole on a course.
struct Hole: Identifiable, Codable, Equatable {
    let id: UUID
    let number: Int
    let par: Int
}

/// Represents a completed game/round.
struct Game: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let course: Course
    let scores: [Score]
}

/// Represents a score for a single hole.
struct Score: Identifiable, Codable, Equatable {
    let id: UUID
    let holeNumber: Int
    let strokes: Int
}

/// Represents a course suggestion (for location-based selection).
struct CourseSuggestion {
    let name: String
    let location: String
    let latitude: Double
    let longitude: Double
}

extension CourseSuggestion {
    func toCourse() -> Course {
        Course(
            id: UUID(),
            name: self.name,
            location: self.location,
            holes: (1...18).map { Hole(id: UUID(), number: $0, par: [4,4,4,4,5,3,3,4,5,4,4,3,4,5,4,4,3,5][($0-1)%18]) }
        )
    }
} 