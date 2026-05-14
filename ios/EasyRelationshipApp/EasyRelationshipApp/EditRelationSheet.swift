import SwiftUI
import EasyRelationshipCore

struct EditRelationSheet: View {
    let people: [EasyRelationshipCore.Person]
    let relationTypes: [EasyRelationshipCore.RelationType]
    let initialFromId: String
    let initialToId: String
    let initialRelationTypeId: String
    let onSave: (String, String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var fromPerson: EasyRelationshipCore.Person? = nil
    @State private var toPerson: EasyRelationshipCore.Person? = nil
    @State private var selectedRelationTypeId: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("人物") {
                    NavigationLink {
                        PersonPickerView(title: "选择发起方", people: people) { person in
                            fromPerson = person
                        }
                    } label: {
                        HStack {
                            Text("从")
                            Spacer()
                            Text(fromPerson?.name ?? "未选择")
                                .foregroundStyle(.secondary)
                        }
                    }

                    NavigationLink {
                        PersonPickerView(title: "选择接收方", people: people) { person in
                            toPerson = person
                        }
                    } label: {
                        HStack {
                            Text("到")
                            Spacer()
                            Text(toPerson?.name ?? "未选择")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button("交换方向") {
                        let tmp = fromPerson
                        fromPerson = toPerson
                        toPerson = tmp
                    }
                    .disabled(fromPerson == nil && toPerson == nil)
                }

                Section("关系类型") {
                    Picker("类型", selection: $selectedRelationTypeId) {
                        Text("未选择").tag("")
                        ForEach(relationTypes) { type in
                            Text(type.name).tag(type.id)
                        }
                    }
                }
            }
            .navigationTitle("编辑关系")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let fromPerson, let toPerson else { return }
                        guard !selectedRelationTypeId.isEmpty else { return }
                        onSave(fromPerson.id, toPerson.id, selectedRelationTypeId)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
        .onAppear {
            fromPerson = people.first(where: { $0.id == initialFromId })
            toPerson = people.first(where: { $0.id == initialToId })
            selectedRelationTypeId = initialRelationTypeId
            if selectedRelationTypeId.isEmpty {
                selectedRelationTypeId = relationTypes.first?.id ?? ""
            }
        }
    }

    private var canSave: Bool {
        guard fromPerson != nil, toPerson != nil else { return false }
        guard !selectedRelationTypeId.isEmpty else { return false }
        return true
    }
}

