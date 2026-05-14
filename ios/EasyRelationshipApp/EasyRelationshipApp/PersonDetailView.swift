import SwiftUI
import EasyRelationshipCore

struct PersonDetailView: View {
    @ObservedObject var store: PeopleStore
    let personId: String

    @State private var isPresentingEdit: Bool = false

    var body: some View {
        Group {
            if let person = store.personById(personId) {
                List {
                    Section("基础") {
                        HStack {
                            Text("姓名")
                            Spacer()
                            Text(person.name)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section("属性") {
                        if store.attributeDefinitions.isEmpty {
                            Text("暂无属性模板")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(store.attributeDefinitions) { definition in
                                HStack {
                                    Text(definition.label)
                                    Spacer()
                                    Text(displayValue(for: definition, person: person))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
                .navigationTitle(person.name)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("编辑") {
                            isPresentingEdit = true
                        }
                    }
                }
                .sheet(isPresented: $isPresentingEdit) {
                    PersonEditorSheet(
                        mode: .edit(personId: person.id),
                        attributeDefinitions: store.attributeDefinitions,
                        initialName: person.name,
                        initialAttributes: person.attributes
                    ) { name, attributes in
                        store.updatePerson(personId: person.id, name: name, attributes: attributes)
                    }
                }
            } else {
                ContentUnavailableView("人物不存在", systemImage: "person.fill.xmark")
                    .onAppear { store.reload() }
            }
        }
    }

    private func displayValue(for definition: EasyRelationshipCore.AttributeDefinition, person: EasyRelationshipCore.Person) -> String {
        let raw = person.attributes[definition.key] ?? ""
        if raw.isEmpty {
            return "—"
        }

        switch definition.type {
        case .date:
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: raw) {
                let out = DateFormatter()
                out.locale = Locale(identifier: "zh_CN")
                out.dateStyle = .medium
                out.timeStyle = .none
                return out.string(from: date)
            }
            return raw
        default:
            return raw
        }
    }
}

