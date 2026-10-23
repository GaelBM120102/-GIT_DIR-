import SwiftUI

struct EntryEditor: View {
    @EnvironmentObject private var store: LifeStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft: LifeEntry
    @State private var hasDate: Bool
    @State private var date: Date
    @State private var confirmDelete = false
    private let isNew: Bool

    init(kind: EntryKind, entry: LifeEntry? = nil, planID: UUID? = nil) {
        var initial = entry ?? LifeEntry(kind: kind, title: "")
        if entry == nil { initial.planID = planID }
        _draft = State(initialValue: initial)
        _hasDate = State(initialValue: initial.dueDate != nil)
        _date = State(initialValue: initial.dueDate ?? Date())
        isNew = entry == nil
    }

    var body: some View {
        NavigationStack {
            Form {
                if isNew {
                    Section {
                        Picker("¿Qué quieres guardar?", selection: $draft.kind) {
                            ForEach(EntryKind.allCases) { kind in Label(kind.title, systemImage: kind.icon).tag(kind) }
                        }.pickerStyle(.segmented)
                    }
                }
                Section(draft.kind == .thought ? "Eso que traes en la cabeza" : "Dale un nombre") {
                    TextField(draft.kind == .thought ? "Un título para este momento" : draft.kind == .plan ? "Algo que quiero hacer…" : "Tengo pendiente…", text: $draft.title, axis: .vertical)
                        .font(.title3.bold()).lineLimit(1...4)
                    TextField(draft.kind == .thought ? "Escribe sin tener que ordenarlo todo…" : "Detalles, ideas o lo que necesites recordar…", text: $draft.notes, axis: .vertical)
                        .lineLimit(5...15)
                }

                Section("Un poco de contexto") {
                    Picker("Área de mi vida", selection: $draft.area) {
                        ForEach(LifeArea.allCases) { area in Label(area.rawValue, systemImage: area.icon).tag(area) }
                    }
                    if draft.kind == .thought {
                        Picker("¿Cómo me siento?", selection: $draft.mood) {
                            Text("Sin etiqueta").tag("")
                            ForEach(["Con energía", "En calma", "Con dudas", "Con estrés", "Triste", "Con gratitud"], id: \.self) { Text($0).tag($0) }
                        }
                    } else {
                        Toggle("Agregar una fecha", isOn: $hasDate)
                        if hasDate { DatePicker("¿Para cuándo?", selection: $date, displayedComponents: .date) }
                        Toggle(draft.kind == .plan ? "Ya lo logré" : "Tarea completada", isOn: $draft.completed)
                        if draft.kind == .task {
                            Toggle("Esto es importante", isOn: $draft.pinned)
                            Picker("Parte de un plan", selection: $draft.planID) {
                                Text("Pendiente independiente").tag(nil as UUID?)
                                ForEach(store.plans) { Text($0.title).tag(Optional($0.id)) }
                            }
                        }
                    }
                }

                if draft.kind == .thought {
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Vuelve a mirarlo").font(.headline)
                            Text("¿Qué estaba pasando cuando lo escribiste?\n¿Qué necesitabas en ese momento?\n¿Hay algo pequeño que quieras hacer ahora?")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }.padding(.vertical, 6)
                        TextField("Lo que entiendo ahora…", text: $draft.reflection, axis: .vertical).lineLimit(5...15)
                    } footer: { Text("Este espacio te ayuda a hacer tu propia reflexión. No incluye análisis automático con inteligencia artificial.") }
                    if !isNew {
                        Section("Llévalo a la acción") {
                            Button { convert(to: .task) } label: { Label("Crear una tarea a partir de esto", systemImage: "checkmark.circle") }
                            Button { convert(to: .plan) } label: { Label("Convertir esta idea en un plan", systemImage: "sparkles") }
                        }
                    }
                }

                if !isNew {
                    Section { Button("Eliminar \(draft.kind.title.lowercased())", role: .destructive) { confirmDelete = true } }
                }
            }
            .scrollContentBackground(.hidden).screenBackground()
            .navigationTitle(isNew ? "Captura algo ✦" : "Hazlo tuyo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }.fontWeight(.bold)
                        .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .confirmationDialog("¿Eliminar este elemento?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Eliminar", role: .destructive) { store.delete(draft); if store.errorMessage == nil { dismiss() } }
            } message: { Text(draft.kind == .plan ? "Sus tareas se conservarán como pendientes independientes." : "Esta acción no se puede deshacer.") }
        }
    }

    private func prepared() -> LifeEntry {
        var entry = draft
        entry.title = entry.title.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.dueDate = hasDate && entry.kind != .thought ? Calendar.current.startOfDay(for: date) : nil
        if entry.kind != .task { entry.planID = nil; entry.pinned = false }
        if entry.kind == .thought { entry.completed = false }
        return entry
    }

    private func save() {
        store.upsert(prepared())
        if store.errorMessage == nil { dismiss() }
    }

    private func convert(to kind: EntryKind) {
        // Save the reflection as well as the new item; retain the original thought.
        store.upsert(prepared())
        guard store.errorMessage == nil else { return }
        let notes = [draft.notes, draft.reflection].filter { !$0.isEmpty }.joined(separator: "\n\n")
        store.upsert(LifeEntry(kind: kind, title: draft.title, notes: notes, area: draft.area))
        if store.errorMessage == nil { dismiss() }
    }
}
