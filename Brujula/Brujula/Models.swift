import Foundation

enum EntryKind: String, Codable, CaseIterable, Identifiable {
    case task, plan, thought
    var id: String { rawValue }
    var title: String { switch self { case .task: "Tarea"; case .plan: "Plan"; case .thought: "Pensamiento" } }
    var icon: String { switch self { case .task: "checkmark.circle"; case .plan: "sparkles"; case .thought: "book.closed" } }
}

enum LifeArea: String, Codable, CaseIterable, Identifiable {
    case personal = "Personal", wellbeing = "Bienestar", work = "Trabajo", relationships = "Relaciones", money = "Finanzas", learning = "Aprendizaje"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .personal: "sun.max"
        case .wellbeing: "leaf"
        case .work: "briefcase"
        case .relationships: "heart"
        case .money: "banknote"
        case .learning: "lightbulb"
        }
    }
}

struct LifeEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var kind: EntryKind
    var title: String
    var notes = ""
    var area: LifeArea = .personal
    var createdAt = Date()
    var dueDate: Date?
    var completed = false
    var pinned = false
    var planID: UUID?
    var mood = ""
    var reflection = ""
}

struct LifeData: Codable {
    var version = 1
    var name = ""
    var intention = ""
    var intentionDate = Calendar.current.startOfDay(for: Date())
    var appearance = "system"
    var entries: [LifeEntry] = []
}

enum LifeQuery {
    static func today(_ entries: [LifeEntry], now: Date = Date(), calendar: Calendar = .current) -> [LifeEntry] {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        return entries.filter { $0.kind == .task && $0.dueDate.map { $0 < tomorrow } == true }
            .sorted { a, b in
                if a.completed != b.completed { return !a.completed }
                if a.pinned != b.pinned { return a.pinned }
                return (a.dueDate ?? .distantFuture) < (b.dueDate ?? .distantFuture)
            }
    }

    static func search(_ entries: [LifeEntry], query: String) -> [LifeEntry] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        return entries.filter { entry in
            [entry.title, entry.notes, entry.reflection, entry.area.rawValue, entry.mood]
                .contains { $0.localizedStandardContains(query) }
        }.sorted { $0.createdAt > $1.createdAt }
    }

    static func progress(for plan: LifeEntry, entries: [LifeEntry]) -> Double {
        let steps = entries.filter { $0.kind == .task && $0.planID == plan.id }
        return steps.isEmpty ? 0 : Double(steps.filter(\.completed).count) / Double(steps.count)
    }
}
