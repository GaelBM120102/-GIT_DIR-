import Foundation
import SwiftUI

@MainActor
final class LifeStore: ObservableObject {
    @Published private(set) var data = LifeData()
    @Published var errorMessage: String?
    private let fileURL: URL
    private var canWrite = true

    init() {
        fileURL = URL.documentsDirectory.appending(path: "brujula.json")
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let loaded = try JSONDecoder().decode(LifeData.self, from: Data(contentsOf: fileURL))
            guard loaded.version == 1 else { throw CocoaError(.coderReadCorrupt) }
            data = loaded
        } catch {
            // Never overwrite a file that could not be read.
            canWrite = false
            errorMessage = "No pudimos leer tus datos. Conservamos el archivo original sin modificarlo. Cierra la app y recupera brujula.json desde Archivos antes de volver a intentarlo."
        }
    }

    var entries: [LifeEntry] { data.entries }
    var plans: [LifeEntry] { entries.filter { $0.kind == .plan }.sorted { $0.createdAt > $1.createdAt } }
    var thoughts: [LifeEntry] { entries.filter { $0.kind == .thought }.sorted { $0.createdAt > $1.createdAt } }
    var today: [LifeEntry] { LifeQuery.today(entries).filter { !$0.completed || Calendar.current.isDateInToday($0.dueDate!) } }
    var intention: String { Calendar.current.isDateInToday(data.intentionDate) ? data.intention : "" }

    func upsert(_ entry: LifeEntry) {
        update { value in
            if let index = value.entries.firstIndex(where: { $0.id == entry.id }) { value.entries[index] = entry }
            else { value.entries.insert(entry, at: 0) }
        }
    }

    func toggle(_ entry: LifeEntry) {
        var changed = entry
        changed.completed.toggle()
        upsert(changed)
    }

    func delete(_ entry: LifeEntry) {
        update { value in
            value.entries.removeAll { $0.id == entry.id }
            // Keep a deleted plan's tasks as independent tasks.
            for index in value.entries.indices where value.entries[index].planID == entry.id { value.entries[index].planID = nil }
        }
    }

    func setProfile(name: String, appearance: String) {
        update { $0.name = name.trimmingCharacters(in: .whitespacesAndNewlines); $0.appearance = appearance }
    }

    func setIntention(_ text: String) {
        update { $0.intention = text; $0.intentionDate = Calendar.current.startOfDay(for: Date()) }
    }

    private func update(_ change: (inout LifeData) -> Void) {
        guard canWrite else { errorMessage = "Recupera primero el archivo original desde Archivos. Tus cambios aún no se pueden guardar."; return }
        var next = data
        change(&next)
        do {
            let encoded = try JSONEncoder().encode(next)
            try encoded.write(to: fileURL, options: [.atomic, .completeFileProtectionUnlessOpen])
            data = next
        } catch {
            errorMessage = "No se pudo guardar el cambio. Tus datos anteriores siguen intactos. Revisa el espacio disponible y vuelve a intentarlo."
        }
    }

    func exportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(data)
    }

    func loadExamples() {
        guard entries.isEmpty else { return }
        let plan = LifeEntry(kind: .plan, title: "Hacer espacio para mí", notes: "Construir una rutina que me haga sentir bien, paso a paso.", area: .wellbeing)
        let today = Calendar.current.startOfDay(for: Date())
        let examples = [
            plan,
            LifeEntry(kind: .task, title: "Salir a caminar 20 minutos", area: .wellbeing, dueDate: today, pinned: true, planID: plan.id),
            LifeEntry(kind: .task, title: "Reservar un momento para leer", area: .personal, dueDate: today),
            LifeEntry(kind: .task, title: "Preparar mi espacio de descanso", area: .wellbeing, completed: true, planID: plan.id),
            LifeEntry(kind: .thought, title: "Quiero ir a mi propio ritmo", notes: "A veces lleno el día de cosas y olvido preguntarme qué necesito. Quiero hacer espacio para lo que me importa.", area: .personal, mood: "En calma")
        ]
        update { $0.entries = examples }
    }
}
