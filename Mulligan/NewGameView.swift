import SwiftUI
import CoreLocation

struct NewGameView: View {
    let courseSuggestion: CourseSuggestion?
    @Environment(\.presentationMode) var presentationMode
    @State private var showChooseLocation = false
    
    var body: some View {
        Group {
            if let suggestion = courseSuggestion {
                // Go straight to scoring for the suggested course
                ScoreEntryView(course: suggestion.toCourse())
            } else {
                ChooseLocationView(onSelect: { course in
                    // Start round for selected course
                    presentationMode.wrappedValue.dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        UIApplication.shared.windows.first?.rootViewController?.present(UIHostingController(rootView: ScoreEntryView(course: course.toCourse())), animated: true)
                    }
                }, onExit: {
                    presentationMode.wrappedValue.dismiss()
                })
            }
        }
    }
}

struct ChooseLocationView: View {
    @State private var searchText = ""
    @State private var courses: [CourseSuggestion] = knownCourses
    @Environment(\.presentationMode) var presentationMode
    let onSelect: (CourseSuggestion) -> Void
    let onExit: () -> Void
    @StateObject private var locationManager = LocationManager()
    
    var filteredCourses: [CourseSuggestion] {
        let filtered = searchText.isEmpty ? courses : courses.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) || $0.location.localizedCaseInsensitiveContains(searchText)
        }
        if let loc = locationManager.userLocation {
            return filtered.sorted { a, b in
                let la = CLLocation(latitude: a.latitude, longitude: a.longitude)
                let lb = CLLocation(latitude: b.latitude, longitude: b.longitude)
                return la.distance(from: loc) < lb.distance(from: loc)
            }
        } else {
            return filtered.sorted { $0.name < $1.name }
        }
    }
    
    func distanceString(for course: CourseSuggestion) -> String? {
        guard let loc = locationManager.userLocation else { return nil }
        let courseLoc = CLLocation(latitude: course.latitude, longitude: course.longitude)
        let meters = courseLoc.distance(from: loc)
        if meters < 1000 {
            return "\(Int(meters)) m"
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    TextField("Search courses...", text: $searchText)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    Button(action: onExit) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing)
                }
                .padding(.top, 16)
                ScrollView {
                    VStack(spacing: 18) {
                        ForEach(filteredCourses, id: \.name) { course in
                            Button(action: { onSelect(course) }) {
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(course.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(course.location)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        if let dist = distanceString(for: course) {
                                            Text(dist)
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 18).fill(Color.white).shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.08), radius: 6, y: 2))
                            }
                        }
                    }
                    .padding(.top, 16)
                    .padding(.horizontal)
                }
                Spacer(minLength: 16)
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
} 