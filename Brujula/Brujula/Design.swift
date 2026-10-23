import SwiftUI
import UIKit

enum Palette {
    static let green = Color(red: 0.33, green: 0.22, blue: 0.78)
    static let lime = Color(red: 0.83, green: 0.96, blue: 0.32)
    static let pink = Color(red: 1, green: 0.62, blue: 0.82)
    static let purple = Color(red: 0.80, green: 0.74, blue: 1)
    static let orange = Color(red: 1, green: 0.66, blue: 0.40)
    static let paper = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1) : UIColor(red: 0.97, green: 0.96, blue: 0.93, alpha: 1) })
    static let ink = Color.primary
    static func area(_ area: LifeArea) -> Color {
        switch area {
        case .personal: pink
        case .wellbeing: lime
        case .work: purple
        case .relationships: orange
        case .money: Color(red: 0.59, green: 0.84, blue: 1)
        case .learning: Color(red: 1, green: 0.85, blue: 0.38)
        }
    }
}

struct StickerCard: ViewModifier {
    var fill: Color
    func body(content: Content) -> some View {
        let shape = UnevenRoundedRectangle(topLeadingRadius: 5, bottomLeadingRadius: 23, bottomTrailingRadius: 5, topTrailingRadius: 23)
        content.padding(18).background(fill, in: shape)
            .overlay(shape.stroke(.black, lineWidth: 2))
            .shadow(color: .black.opacity(0.9), radius: 0, x: 4, y: 5)
    }
}

extension View {
    func sticker(_ fill: Color = Palette.paper) -> some View { modifier(StickerCard(fill: fill)) }
    func screenBackground() -> some View { background(PaperBackdrop().ignoresSafeArea()) }
}

struct PaperBackdrop: View {
    var body: some View {
        Palette.paper.overlay {
            Canvas { context, size in
                for index in 0..<180 {
                    let x = CGFloat((index * 97 + 11) % 997) / 997 * size.width
                    let y = CGFloat((index * 173 + 37) % 991) / 991 * size.height
                    let radius: CGFloat = index.isMultiple(of: 7) ? 1.2 : 0.65
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)), with: .color(Palette.ink.opacity(0.055)))
                }
            }.accessibilityHidden(true).allowsHitTesting(false)
        }
    }
}

struct StreetStar: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        for index in 0..<16 {
            let angle = Double(index) * .pi / 8 - .pi / 2
            let radius = min(rect.width, rect.height) * (index.isMultiple(of: 2) ? 0.48 : 0.23)
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle)) * radius)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

struct GraffitiTitle: View {
    var text: String
    var size: CGFloat = 34
    var body: some View {
        Text(text).font(.custom("PermanentMarker-Regular", size: size, relativeTo: .largeTitle))
            .tracking(-0.7).fixedSize(horizontal: false, vertical: true)
    }
}

struct AreaTag: View {
    var area: LifeArea
    var body: some View {
        Label(area.rawValue, systemImage: area.icon)
            .font(.caption.weight(.semibold)).padding(.horizontal, 10).padding(.vertical, 5)
            .foregroundStyle(.black).background(Palette.area(area), in: Capsule())
            .overlay(Capsule().stroke(.black.opacity(0.5), lineWidth: 1))
    }
}

struct EmptyCard: View {
    var icon: String
    var title: String
    var subtitle: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 34, weight: .bold)).foregroundStyle(Palette.green)
            Text(title).font(.title3.bold())
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity).padding(.vertical, 25).sticker()
    }
}

struct SectionLabel: View {
    var title: String
    var subtitle: String = ""
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            GraffitiTitle(text: title, size: 23)
            Spacer()
            Text(subtitle).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
        }.padding(.top, 10)
    }
}

struct TaskRow: View {
    @EnvironmentObject private var store: LifeStore
    var entry: LifeEntry
    var edit: () -> Void
    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            Button { withAnimation { store.toggle(entry) } } label: {
                Image(systemName: entry.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(entry.completed ? Palette.green : Palette.ink)
            }.buttonStyle(.plain).accessibilityLabel(entry.completed ? "Marcar pendiente: \(entry.title)" : "Completar: \(entry.title)")
            Button(action: edit) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(entry.title).font(.body.weight(.semibold)).strikethrough(entry.completed).foregroundStyle(entry.completed ? .secondary : .primary)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 8) {
                        AreaTag(area: entry.area)
                        if let date = entry.dueDate, date < Calendar.current.startOfDay(for: Date()), !entry.completed {
                            Text("Atrasada").font(.caption.bold()).foregroundStyle(.red)
                        } else if let date = entry.dueDate {
                            Text(date, format: .dateTime.day().month(.abbreviated)).font(.caption).foregroundStyle(.secondary)
                        }
                        if entry.pinned { Image(systemName: "pin.fill").font(.caption).foregroundStyle(Palette.green) }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }.buttonStyle(.plain)
        }.padding(.vertical, 13)
    }
}

struct PlanCard: View {
    @EnvironmentObject private var store: LifeStore
    var plan: LifeEntry
    var body: some View {
        let steps = store.entries.filter { $0.kind == .task && $0.planID == plan.id }
        VStack(alignment: .leading, spacing: 15) {
            HStack { AreaTag(area: plan.area); Spacer(); Image(systemName: plan.completed ? "checkmark.seal.fill" : "arrow.up.right").font(.title2.bold()).foregroundStyle(.black) }
            GraffitiTitle(text: plan.title, size: 25).foregroundStyle(.black)
            if !plan.notes.isEmpty { Text(plan.notes).font(.subheadline).foregroundStyle(.black.opacity(0.75)).lineLimit(3) }
            ProgressView(value: LifeQuery.progress(for: plan, entries: store.entries)).tint(.black)
            HStack {
                Text("\(steps.filter(\.completed).count) de \(steps.count) pasos")
                Spacer()
                if plan.completed { Text("Logrado ✦") }
                else if let date = plan.dueDate { Text(date, format: .dateTime.day().month(.abbreviated)) }
            }.font(.caption.bold()).foregroundStyle(.black)
        }.sticker(Palette.area(plan.area))
    }
}
