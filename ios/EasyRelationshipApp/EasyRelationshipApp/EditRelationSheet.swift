import SwiftUI
import EasyRelationshipCore

struct EditRelationSheet: View {
    let entities: [EasyRelationshipCore.Entity]
    let relationTypes: [EasyRelationshipCore.RelationType]
    let initialFromId: String
    let initialToId: String
    let initialRelationTypeId: String
    let onSave: (String, String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var fromEntity: EasyRelationshipCore.Entity? = nil
    @State private var toEntity: EasyRelationshipCore.Entity? = nil
    @State private var selectedRelationTypeId: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("个体") {
                    NavigationLink {
                        EntityPickerView(title: "选择发起方", entities: entities) { entity in
                            fromEntity = entity
                        }
                    } label: {
                        HStack {
                            Text("从")
                            Spacer()
                            Text(fromEntity?.name ?? "未选择")
                                .foregroundStyle(.secondary)
                        }
                    }

                    NavigationLink {
                        EntityPickerView(title: "选择接收方", entities: entities) { entity in
                            toEntity = entity
                        }
                    } label: {
                        HStack {
                            Text("到")
                            Spacer()
                            Text(toEntity?.name ?? "未选择")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button("交换方向") {
                        let tmp = fromEntity
                        fromEntity = toEntity
                        toEntity = tmp
                    }
                    .disabled(fromEntity == nil && toEntity == nil)
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
                        guard let fromEntity, let toEntity else { return }
                        guard !selectedRelationTypeId.isEmpty else { return }
                        onSave(fromEntity.id, toEntity.id, selectedRelationTypeId)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
        .onAppear {
            fromEntity = entities.first(where: { $0.id == initialFromId })
            toEntity = entities.first(where: { $0.id == initialToId })
            selectedRelationTypeId = initialRelationTypeId
            if selectedRelationTypeId.isEmpty {
                selectedRelationTypeId = relationTypes.first?.id ?? ""
            }
        }
    }

    private var canSave: Bool {
        guard fromEntity != nil, toEntity != nil else { return false }
        guard !selectedRelationTypeId.isEmpty else { return false }
        return true
    }
}

