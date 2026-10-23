import SwiftUI
import UniformTypeIdentifiers

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

struct SettingsView: View {
    @EnvironmentObject private var store: LifeStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var appearance = "system"
    @State private var exporting = false
    @State private var document: BackupDocument?
    @State private var exportError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Este espacio es tuyo") {
                    TextField("¿Cómo te gusta que te llamen?", text: $name).textContentType(.nickname)
                    Picker("Apariencia", selection: $appearance) {
                        Text("Como mi iPhone").tag("system")
                        Text("Clara").tag("light")
                        Text("Oscura").tag("dark")
                    }
                }
                Section {
                    Button {
                        do { document = BackupDocument(data: try store.exportData()); exporting = true }
                        catch { exportError = "No se pudo preparar tu copia. Vuelve a intentarlo." }
                    } label: { Label("Exportar una copia de mis datos", systemImage: "square.and.arrow.up") }
                } header: { Text("Tus datos, contigo") } footer: {
                    Text("Todo se guarda en este iPhone, sin cuentas ni servidores propios. La copia JSON contiene tus textos: guárdala donde tú elijas. Esta primera versión todavía no permite importarla ni sincronizarla entre dispositivos. Si eliminas la app, sus datos locales también se borran.")
                }
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("GAPPEL ✦").font(.custom("PermanentMarker-Regular", size: 34, relativeTo: .largeTitle))
                        Text("Tu vida, a tu ritmo.").font(.headline)
                        Text("Versión inicial · iPhone · iOS 17 o posterior").font(.caption).foregroundStyle(.secondary)
                    }.padding(.vertical, 12)
                }
            }.scrollContentBackground(.hidden).screenBackground()
                .navigationTitle("Mi espacio")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Guardar") { store.setProfile(name: name, appearance: appearance); if store.errorMessage == nil { dismiss() } }.fontWeight(.bold)
                    }
                }
                .onAppear { name = store.data.name; appearance = store.data.appearance }
                .fileExporter(isPresented: $exporting, document: document, contentType: .json, defaultFilename: "gappel-respaldo") { result in
                    if case .failure = result { exportError = "No se pudo exportar la copia. Vuelve a intentarlo." }
                }
                .alert("Copia de seguridad", isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) { Button("Entendido") { exportError = nil } } message: { Text(exportError ?? "") }
        }
    }
}

struct SearchView: View {
    @EnvironmentObject private var store: LifeStore
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var editing: LifeEntry?

    var body: some View {
        NavigationStack {
            List {
                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ContentUnavailableView("Encuentra ese algo", systemImage: "magnifyingglass", description: Text("Busca en tus tareas, planes, pensamientos y reflexiones."))
                } else {
                    let results = LifeQuery.search(store.entries, query: query)
                    if results.isEmpty { ContentUnavailableView.search(text: query) }
                    ForEach(results) { entry in
                        Button { editing = entry } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Label(entry.kind.title, systemImage: entry.kind.icon).font(.caption).foregroundStyle(.secondary)
                                Text(entry.title).font(.headline).foregroundStyle(.primary)
                                if !entry.notes.isEmpty { Text(entry.notes).font(.subheadline).foregroundStyle(.secondary).lineLimit(2) }
                                AreaTag(area: entry.area)
                            }.padding(.vertical, 6)
                        }
                    }
                }
            }.scrollContentBackground(.hidden).screenBackground()
                .searchable(text: $query, prompt: "Busca en tu mundo…")
                .navigationTitle("Todo a la mano")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Listo") { dismiss() } } }
                .sheet(item: $editing) { entry in EntryEditor(kind: entry.kind, entry: entry) }
        }
    }
}
