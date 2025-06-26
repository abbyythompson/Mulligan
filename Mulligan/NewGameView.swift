import SwiftUI

struct NewGameView: View {
    @State private var selectedCourseIndex: Int? = nil
    @State private var showScoreEntry = false
    
    // Hardcoded sample courses
    let courses: [Course] = [
        Course(
            id: UUID(),
            name: "Pebble Beach Golf Links",
            location: "Pebble Beach, CA",
            holes: (1...18).map { Hole(id: UUID(), number: $0, par: [4,4,4,4,5,3,3,4,5,4,4,3,4,5,4,4,3,5][$0-1]) }
        ),
        Course(
            id: UUID(),
            name: "St Andrews Old Course",
            location: "St Andrews, Scotland",
            holes: (1...18).map { Hole(id: UUID(), number: $0, par: [4,4,4,4,5,4,4,3,4,4,3,4,4,5,4,4,3,4][$0-1]) }
        )
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Select a Course")
                .font(.title2)
                .padding(.top)
            
            Picker("Course", selection: $selectedCourseIndex) {
                Text("Select...").tag(Int?.none)
                ForEach(courses.indices, id: \.self) { idx in
                    Text(courses[idx].name).tag(Int?.some(idx))
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
            
            Button(action: {
                showScoreEntry = true
            }) {
                Text("Start Round")
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedCourseIndex == nil ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(selectedCourseIndex == nil)
            .padding(.horizontal)
            
            Spacer()
        }
        .sheet(isPresented: $showScoreEntry) {
            if let idx = selectedCourseIndex {
                ScoreEntryView(course: courses[idx])
            }
        }
    }
} 