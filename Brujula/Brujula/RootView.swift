import SwiftUI

private struct Capture: Identifiable {
    let id = UUID()
    var kind: EntryKind
    var entry: LifeEntry?
    var planID: UUID?
}

struct RootView: View {
    @EnvironmentObject private var store: LifeStore
    @State private var tab = 0
    @State private var capture: Capture?
    @State private var showSettings = false
    @State private var showSearch = false

    var body: some View {
        TabView(selection: $tab) {
            page(title: "brújula ✦") { TodayView { capture = Capture(kind: $0.kind, entry: $0) } add: { capture = Capture(kind: $0) } }
                .tabItem { Label("Hoy", systemImage: "sun.max") }.tag(0)
            page(title: "Tus pendientes") { TasksView { capture = Capture(kind: .task, entry: $0) } }
                .tabItem { Label("Pendientes", systemImage: "checkmark.circle") }.tag(1)
            page(title: "Lo que viene") { PlansView(edit: { capture = Capture(kind: .plan, entry: $0) }, addStep: { capture = Capture(kind: .task, planID: $0) }) }
                .tabItem { Label("Planes", systemImage: "sparkles") }.tag(2)
            page(title: "Tu cabeza, en papel") { ThoughtsView { capture = Capture(kind: .thought, entry: $0) } }
                .tabItem { Label("Diario", systemImage: "book.closed") }.tag(3)
        }
        .sheet(item: $capture) { value in EntryEditor(kind: value.kind, entry: value.entry, planID: value.planID) }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showSearch) { SearchView() }
        .alert("Necesitamos tu atención", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
            Button("Entendido") { store.errorMessage = nil }
        } message: { Text(store.errorMessage ?? "") }
    }

    private func page<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            content().screenBackground()
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Button { capture = Capture(kind: tab == 2 ? .plan : tab == 3 ? .thought : .task) } label: {
                        HStack { Image(systemName: "plus").foregroundStyle(Palette.lime); Text("Captura algo").font(.custom("PermanentMarker-Regular", size: 18, relativeTo: .headline)); Spacer(); Image(systemName: "arrow.up.right") }
                            .padding(17).foregroundStyle(.white).background(.black, in: RoundedRectangle(cornerRadius: 18))
                    }.padding(.horizontal, 20).padding(.vertical, 8).background(Palette.paper)
                }
                .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(title).font(.custom("PermanentMarker-Regular", size: 20, relativeTo: .headline)).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Button { showSettings = true } label: { Image(systemName: "face.smiling").font(.title3) }.accessibilityLabel("Personalizar mi espacio")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showSearch = true } label: { Image(systemName: "magnifyingglass") }.accessibilityLabel("Buscar en mi vida")
                    }
                }
        }
    }
}

struct TodayView: View {
    @EnvironmentObject private var store: LifeStore
    var edit: (LifeEntry) -> Void
    var add: (EntryKind) -> Void
    @State private var intention = ""
    @State private var editingIntention = false
    private var activePlanCount: Int { store.plans.filter { !$0.completed }.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 23) {
                HStack {
                    Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide)).font(.caption.weight(.bold)).textCase(.uppercase)
                    Spacer()
                    Text("A MI MANERA ✦").font(.custom("PermanentMarker-Regular", size: 11, relativeTo: .caption)).padding(7).background(Palette.pink).foregroundStyle(.black).overlay(Rectangle().stroke(.black, lineWidth: 1.5)).rotationEffect(.degrees(5))
                }
                VStack(alignment: .leading, spacing: 15) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
                            if !store.data.name.isEmpty { Text("HEY, \(store.data.name.uppercased())").font(.caption.weight(.black)) }
                            Text("TU DÍA.\nTUS REGLAS.")
                                .font(.custom("RubikSprayPaint-Regular", size: 42, relativeTo: .largeTitle))
                                .tracking(-1.2).lineSpacing(-2).minimumScaleFactor(0.7)
                                .rotationEffect(.degrees(-3))
                        }
                        Spacer()
                        StreetStar().stroke(.black, lineWidth: 2.5).frame(width: 56, height: 72).rotationEffect(.degrees(12)).padding(.top, 18).accessibilityHidden(true)
                    }
                    Text("Un poco de orden. Mucho de ti.").font(.subheadline.weight(.medium))
                    HStack(spacing: 8) {
                        Text("\(store.today.filter { !$0.completed }.count) para hoy").font(.caption.bold()).padding(9).background(.black, in: Capsule()).foregroundStyle(.white)
                        Text("\(activePlanCount) \(activePlanCount == 1 ? "plan" : "planes") en marcha").font(.caption.bold()).padding(9).overlay(Capsule().stroke(.black))
                    }
                }.foregroundStyle(.black).frame(maxWidth: .infinity, alignment: .leading).sticker(Palette.lime)

                Button {
                    intention = store.intention; editingIntention = true
                } label: {
                    HStack(alignment: .top) {
                        Image(systemName: "scope").font(.title2)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("MI INTENCIÓN DE HOY").font(.caption.weight(.black))
                            Text(store.intention.isEmpty ? "¿Qué merece tu energía hoy?" : store.intention).font(.body.weight(.medium)).multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Image(systemName: "pencil")
                    }.foregroundStyle(.black).sticker(Palette.purple)
                }.buttonStyle(.plain)

                SectionLabel(title: "Un paso a la vez", subtitle: "HOY + ATRASADAS")
                if store.today.isEmpty {
                    EmptyCard(icon: "sun.max", title: "Tu día tiene espacio", subtitle: "Agrega una tarea con fecha de hoy. Los pendientes sin fecha viven en Pendientes.")
                } else {
                    VStack(spacing: 0) {
                        ForEach(store.today) { entry in
                            TaskRow(entry: entry) { edit(entry) }
                            if entry.id != store.today.last?.id { Divider() }
                        }
                    }.padding(.horizontal, 16).background(Palette.paper, in: RoundedRectangle(cornerRadius: 20)).overlay(RoundedRectangle(cornerRadius: 20).stroke(Palette.ink, lineWidth: 1.5))
                }

                Button { add(.thought) } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("SÁCALO DE TU CABEZA").font(.caption.weight(.black))
                            GraffitiTitle(text: "Aquí cabe todo eso\nque traes dentro.", size: 23).multilineTextAlignment(.leading)
                            Text("Escribe un pensamiento ↗").font(.caption.bold())
                        }
                        Spacer()
                        Image(systemName: "pencil.and.scribble").font(.system(size: 39)).rotationEffect(.degrees(-12))
                    }.foregroundStyle(.black).sticker(Palette.pink)
                }.buttonStyle(.plain)

                if store.entries.isEmpty {
                    Button("Explorar con ejemplos (opcionales)") { store.loadExamples() }.font(.footnote).frame(maxWidth: .infinity)
                }
                Text("A tu ritmo también cuenta. ✦").font(.caption.weight(.semibold)).frame(maxWidth: .infinity).foregroundStyle(.secondary).padding(.vertical, 8)
            }.padding(22)
        }
        .alert("Una intención, sin presión", isPresented: $editingIntention) {
            TextField("Hoy quiero…", text: $intention)
            Button("Guardar") { store.setIntention(intention) }
            Button("Cancelar", role: .cancel) {}
        } message: { Text("Puede ser algo tan simple como darte un descanso.") }
    }
}

struct TasksView: View {
    @EnvironmentObject private var store: LifeStore
    var edit: (LifeEntry) -> Void
    @State private var completed = false
    @State private var area: LifeArea?

    private var tasks: [LifeEntry] {
        store.entries.filter { $0.kind == .task && $0.completed == completed && (area == nil || $0.area == area) }
            .sorted { a, b in a.pinned != b.pinned ? a.pinned : (a.dueDate ?? .distantFuture) < (b.dueDate ?? .distantFuture) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GraffitiTitle(text: "Menos ruido.\nMás espacio mental.")
                Picker("Estado", selection: $completed) { Text("Por hacer").tag(false); Text("Hechas").tag(true) }.pickerStyle(.segmented)
                Menu { Button("Todas las áreas") { area = nil }; ForEach(LifeArea.allCases) { value in Button(value.rawValue) { area = value } } } label: {
                    Label(area?.rawValue ?? "Todas las áreas", systemImage: "line.3.horizontal.decrease.circle").font(.subheadline.bold())
                }
                if tasks.isEmpty { EmptyCard(icon: "checkmark.circle", title: completed ? "Tus logros van aquí" : "Nada por aquí todavía", subtitle: completed ? "Cada tarea que completes aparecerá en esta lista." : "Captura un pendiente. No necesitas tener todo resuelto.") }
                else { VStack(spacing: 0) { ForEach(tasks) { entry in TaskRow(entry: entry) { edit(entry) }; Divider() } }.padding(.horizontal, 15).sticker() }
            }.padding(22)
        }
    }
}

struct PlansView: View {
    @EnvironmentObject private var store: LifeStore
    var edit: (LifeEntry) -> Void
    var addStep: (UUID) -> Void
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 23) {
                GraffitiTitle(text: "Grandes ideas.\nPequeños pasos.")
                Text("Todo eso que quieres hacer, con espacio para empezar.").foregroundStyle(.secondary)
                if store.plans.isEmpty { EmptyCard(icon: "sparkles", title: "El futuro empieza con una idea", subtitle: "Crea un plan y divídelo en pasos que sí puedas dar.") }
                ForEach(store.plans) { plan in
                    VStack(alignment: .leading, spacing: 10) {
                        Button { edit(plan) } label: { PlanCard(plan: plan) }.buttonStyle(.plain)
                        let steps = store.entries.filter { $0.kind == .task && $0.planID == plan.id }
                        ForEach(steps) { entry in
                            HStack {
                                Button { store.toggle(entry) } label: { Label(entry.title, systemImage: entry.completed ? "checkmark.circle.fill" : "circle").strikethrough(entry.completed).multilineTextAlignment(.leading) }.buttonStyle(.plain)
                                Spacer()
                            }.padding(.horizontal, 8)
                        }
                        Button { addStep(plan.id) } label: { Label("Agregar un paso", systemImage: "plus") }.font(.subheadline.bold()).padding(.top, 5)
                    }.padding(.bottom, 8)
                }
            }.padding(22)
        }
    }
}

struct ThoughtsView: View {
    @EnvironmentObject private var store: LifeStore
    var edit: (LifeEntry) -> Void
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                GraffitiTitle(text: "Sin filtro.\nSin juicio.", size: 38)
                Text("Escribe ahora. Vuelve cuando quieras entenderlo mejor.").foregroundStyle(.secondary)
                if store.thoughts.isEmpty { EmptyCard(icon: "pencil.and.scribble", title: "Una página para ti", subtitle: "Ideas sueltas, emociones, preguntas… todo tiene lugar aquí.") }
                ForEach(store.thoughts) { thought in
                    Button { edit(thought) } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(thought.createdAt, format: .dateTime.day().month(.abbreviated)).font(.caption.bold())
                                Spacer()
                                if !thought.mood.isEmpty { Text(thought.mood).font(.caption.bold()) }
                            }
                            GraffitiTitle(text: thought.title, size: 25)
                            Text(thought.notes).font(.body).lineLimit(4)
                            HStack { AreaTag(area: thought.area); Spacer(); Text(thought.reflection.isEmpty ? "Volver a mirar ↗" : "Con reflexión ✦").font(.caption.bold()) }
                        }.foregroundStyle(.black).frame(maxWidth: .infinity, alignment: .leading).sticker(Palette.area(thought.area))
                    }.buttonStyle(.plain)
                }
            }.padding(22)
        }
    }
}
