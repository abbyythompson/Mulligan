import SwiftUI

struct ScoreEntryView: View {
    let course: Course
    @State private var currentHoleIndex = 0
    @State private var scores: [Int] = []
    @State private var showSummary = false
    @Environment(\.presentationMode) var presentationMode
    @State private var showExitAlert = false
    @State private var showFinishAlert = false
    
    // Load in-progress round if available
    init(course: Course) {
        self.course = course
        if let saved = InProgressRoundManager.shared.load(), saved.course.name == course.name {
            _currentHoleIndex = State(initialValue: saved.currentHoleIndex)
            _scores = State(initialValue: saved.scores)
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                headerView
                if currentHoleIndex > 0 && !showSummary {
                    previousHolesSummary
                    Divider().padding(.horizontal, 8)
                }
                if showSummary {
                    withAnimation(.easeInOut) {
                        ScorecardView(course: course, scores: scores)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    Button("Done") {
                        InProgressRoundManager.shared.clear()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.title3)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.top)
                } else {
                    currentHoleCard
                }
                Spacer(minLength: 16)
            }
        }
        .alert(isPresented: $showExitAlert) {
            Alert(title: Text("Exit Round?"), message: Text("You can resume this round later from the home screen."), dismissButton: .default(Text("OK"), action: {
                InProgressRoundManager.shared.save(course: course, currentHoleIndex: currentHoleIndex, scores: scores)
                presentationMode.wrappedValue.dismiss()
            }))
        }
        .alert(isPresented: $showFinishAlert) {
            Alert(title: Text("Finish Round?"), message: Text("Are you sure you want to finish and save this round?"), primaryButton: .destructive(Text("Finish")) {
                if scores.count <= currentHoleIndex {
                    scores.append(course.holes[currentHoleIndex].par)
                }
                showSummary = true
                // Save completed game
                let game = Game(
                    id: UUID(),
                    date: Date(),
                    course: course,
                    scores: course.holes.enumerated().map { (idx, hole) in
                        Score(id: UUID(), holeNumber: hole.number, strokes: scores.indices.contains(idx) ? scores[idx] : hole.par)
                    }
                )
                PersistenceManager.shared.saveGame(game)
                InProgressRoundManager.shared.clear()
            }, secondaryButton: .cancel())
        }
    }

    private var headerView: some View {
        VStack(spacing: 4) {
            Text(course.name)
                .font(.title2)
                .fontWeight(.bold)
            Text(course.location)
                .font(.subheadline)
                .foregroundColor(.secondary)
            if !showSummary {
                Text("Hole \(currentHoleIndex + 1) of \(course.holes.count)")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.top, 2)
            }
        }
        .padding(.top, 18)
        .padding(.bottom, 8)
        .background(Color(.systemGroupedBackground).opacity(0.95))
    }

    private var previousHolesSummary: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(0..<currentHoleIndex, id: \.self) { idx in
                    Button(action: {
                        currentHoleIndex = idx
                    }) {
                        HStack(spacing: 2) {
                            Text("H\(course.holes[idx].number)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(scores.indices.contains(idx) ? String(scores[idx]) : "-")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.green.opacity(0.7)))
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.08)))
            .padding(.bottom, 4)
        }
    }

    private var currentHoleCard: some View {
        let hole = course.holes[currentHoleIndex]
        let maxShots = max(10, hole.par + 5)
        let currentScore = scores.count > currentHoleIndex ? scores[currentHoleIndex] : 0
        let cardNumbers = Array(1...maxShots)
        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return VStack(spacing: 18) {
            // Current hole card
            VStack(spacing: 10) {
                Text("Hole \(hole.number)")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Par: \(hole.par)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                numberCardGrid(cardNumbers: cardNumbers, columns: columns, currentScore: currentScore, hole: hole)
                // Alternate: 'I took a shot' button
                Button(action: {
                    let newScore = currentScore + 1
                    if scores.count > currentHoleIndex {
                        scores[currentHoleIndex] = newScore
                    } else {
                        if scores.count == currentHoleIndex {
                            scores.append(newScore)
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("I took a shot")
                            .font(.headline)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 24)
                    .background(Capsule().fill(Color.green.opacity(0.15)))
                }
                .padding(.top, 8)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white).shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.06), radius: 4, y: 2))
            .padding(.horizontal)
            // Action buttons
            VStack(spacing: 10) {
                Button(currentHoleIndex == course.holes.count - 1 ? "Finish Round" : "Next Hole") {
                    if currentHoleIndex == course.holes.count - 1 {
                        showFinishAlert = true
                    } else {
                        if scores.count <= currentHoleIndex {
                            scores.append(currentScore)
                        }
                        currentHoleIndex += 1
                        InProgressRoundManager.shared.save(course: course, currentHoleIndex: currentHoleIndex, scores: scores)
                    }
                }
                .font(.title3)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .animation(.easeInOut, value: currentHoleIndex)
                Button("Save & Exit") {
                    showExitAlert = true
                }
                .foregroundColor(.secondary)
                .padding(.top, 2)
            }
        }
        .padding(.top, 12)
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }

    private func numberCardGrid(cardNumbers: [Int], columns: [GridItem], currentScore: Int, hole: Hole) -> some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(cardNumbers, id: \.self) { num in
                Button(action: {
                    if scores.count > currentHoleIndex {
                        scores[currentHoleIndex] = num
                    } else {
                        if scores.count == currentHoleIndex {
                            scores.append(num)
                        }
                    }
                }) {
                    Text("\(num)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(currentScore == num ? .white : .primary)
                        .frame(width: 54, height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(currentScore == num ? Color.green : Color(.systemGray6))
                                .shadow(color: currentScore == num ? Color.green.opacity(0.25) : Color(.sRGBLinear, white: 0, opacity: 0.08), radius: 6, y: 2)
                        )
                        .overlay(
                            Group {
                                let diff = num - hole.par
                                if diff == -2 {
                                    // Double circle (eagle)
                                    Circle().stroke(Color.green, lineWidth: 3).frame(width: 54, height: 54)
                                        .overlay(
                                            Circle().stroke(Color.green, lineWidth: 2).frame(width: 44, height: 44)
                                        )
                                } else if diff == -1 {
                                    // Single circle (birdie)
                                    Circle().stroke(Color.green, lineWidth: 3).frame(width: 54, height: 54)
                                } else if diff == 1 {
                                    // Single square (bogey)
                                    RoundedRectangle(cornerRadius: 16).stroke(Color.orange, lineWidth: 3).frame(width: 54, height: 54)
                                } else if diff == 2 {
                                    // Double square (double bogey)
                                    RoundedRectangle(cornerRadius: 16).stroke(Color.orange, lineWidth: 3).frame(width: 54, height: 54)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16).stroke(Color.orange, lineWidth: 2).frame(width: 44, height: 44)
                                        )
                                }
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(currentScore == num ? Color.green : Color(.systemGray4), lineWidth: 2)
                        )
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

struct ScorecardView: View {
    let course: Course
    let scores: [Int]
    var body: some View {
        VStack(spacing: 12) {
            Text("Scorecard")
                .font(.title3)
                .fontWeight(.bold)
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 9)
            LazyVGrid(columns: columns, spacing: 8) {
                // Hole numbers row
                ForEach(0..<18, id: \.self) { idx in
                    Text("H\(course.holes[idx].number)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
                // Par row
                ForEach(0..<18, id: \.self) { idx in
                    Text("Par \(course.holes[idx].par)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
                // Score row
                ForEach(0..<18, id: \.self) { idx in
                    Text(scores.indices.contains(idx) ? String(scores[idx]) : "-")
                        .font(.headline)
                        .fontWeight(.medium)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.green.opacity(0.12)))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 2)
            // Out/In totals and divider
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Out (1-9)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(scores.prefix(9).reduce(0, +))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                Divider().frame(height: 32)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("In (10-18)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(scores.suffix(9).reduce(0, +))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            .padding(.top, 4)
            HStack {
                Text("Total: \(scores.reduce(0, +))")
                    .font(.headline)
                Spacer()
                Text("Par: \(course.holes.reduce(0) { $0 + $1.par })")
                    .font(.headline)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
        .padding(.horizontal)
    }
}

// InProgressRoundManager for saving/resuming rounds
class InProgressRoundManager {
    static let shared = InProgressRoundManager()
    private let key = "inProgressRound"
    struct InProgressRound: Codable {
        let course: Course
        let currentHoleIndex: Int
        let scores: [Int]
    }
    func save(course: Course, currentHoleIndex: Int, scores: [Int]) {
        let round = InProgressRound(course: course, currentHoleIndex: currentHoleIndex, scores: scores)
        if let data = try? JSONEncoder().encode(round) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    func load() -> InProgressRound? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let round = try? JSONDecoder().decode(InProgressRound.self, from: data) else {
            return nil
        }
        return round
    }
    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
} 