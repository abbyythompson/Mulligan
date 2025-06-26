import Foundation
import CoreLocation

/// List of known golf courses for suggestions.
let knownCourses: [CourseSuggestion] = [
    CourseSuggestion(name: "Pebble Beach Golf Links", location: "Pebble Beach, CA", latitude: 36.5680, longitude: -121.9500),
    CourseSuggestion(name: "St Andrews Old Course", location: "St Andrews, Scotland", latitude: 56.3432, longitude: -2.8032),
    CourseSuggestion(name: "Royal Mid-Surrey Golf Club", location: "Richmond, London", latitude: 51.4682, longitude: -0.3082),
    CourseSuggestion(name: "Richmond Golf Club", location: "Richmond, London", latitude: 51.4457, longitude: -0.2922),
    CourseSuggestion(name: "The Richmond Hill Golf Club", location: "Richmond, London", latitude: 51.4500, longitude: -0.3000),
    CourseSuggestion(name: "Fulwell Golf Club", location: "Twickenham, London", latitude: 51.4472, longitude: -0.3372),
    CourseSuggestion(name: "Dukes Meadows Golf", location: "Chiswick, London", latitude: 51.4842, longitude: -0.2587)
]

/// Returns the nearest course suggestion to the given location.
func nearestCourse(to location: CLLocation?) -> CourseSuggestion {
    guard let location = location else { return knownCourses[0] }
    return knownCourses.min(by: {
        let loc1 = CLLocation(latitude: $0.latitude, longitude: $0.longitude)
        let loc2 = CLLocation(latitude: $1.latitude, longitude: $1.longitude)
        return loc1.distance(from: location) < loc2.distance(from: location)
    }) ?? knownCourses[0]
} 