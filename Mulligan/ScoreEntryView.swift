import SwiftUI

struct ScoreEntryView: View {
    let course: Course
    @State private var currentHoleIndex = 0
    @State private var scores: [Int] = []
    @State private var showSummary = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        if showSummary {
            VStack(spacing: 20) {
                Text("Round Complete!")
                    .font(.title)
                Text("Course: \(course.name)")
                Text("Total Score: \(scores.reduce(0, +))")
                Text("Par: \(course.holes.reduce(0) { $0 + $1.par })")
                Text("\(scores.reduce(0, +) - course.holes.reduce(0) { $0 + $1.par }) vs Par")
                    .fontWeight(.bold)
                Button("Done") {
                    // Save the game
                    let game = Game(
                        id: UUID(),
                        date: Date(),
                        course: course,
                        scores: course.holes.enumerated().map { (idx, hole) in
                            Score(id: UUID(), holeNumber: hole.number, strokes: scores.indices.contains(idx) ? scores[idx] : hole.par)
                        }
                    )
                    PersistenceManager.shared.saveGame(game)
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .padding()
        } else {
            let hole = course.holes[currentHoleIndex]
            VStack(spacing: 24) {
                Text("Hole \(hole.number)")
                    .font(.title2)
                Text("Par: \(hole.par)")
                    .font(.headline)
                Stepper(value: Binding(
                    get: { scores.count > currentHoleIndex ? scores[currentHoleIndex] : hole.par },
                    set: { newValue in
                        if scores.count > currentHoleIndex {
                            scores[currentHoleIndex] = newValue
                        } else {
                            scores.append(newValue)
                        }
                    }
                ), in: 1...10) {
                    Text("Strokes: \(scores.count > currentHoleIndex ? scores[currentHoleIndex] : hole.par)")
                }
                .padding(.horizontal)
                Button(currentHoleIndex == course.holes.count - 1 ? "Finish Round" : "Next Hole") {
                    if scores.count <= currentHoleIndex {
                        scores.append(hole.par)
                    }
                    if currentHoleIndex == course.holes.count - 1 {
                        showSummary = true
                    } else {
                        currentHoleIndex += 1
                    }
                }
                .font(.title3)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                Spacer()
            }
            .padding()
        }
    }
} 