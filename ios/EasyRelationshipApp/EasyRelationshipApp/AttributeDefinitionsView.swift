import SwiftUI
import EasyRelationshipCore

struct AttributeDefinitionsView: View {
    @StateObject private var store: AttributeDefinitionsStore
    @State private var isPresentingCreate: Bool = false
    @State private var editTarget: EasyRelationshipCore.AttributeDefinition? = nil
    @State private var deleteTarget: EasyRelationshipCore.AttributeDefinition? = nil

    init(store: AttributeDefinitionsStore) {
        self._store = StateObject(wrappedValue: store)
    }

    var body: some View {
        List {
            if !store.lastErrorMessage.isEmpty {
                Section {
                    Text("加载失败：\(store.lastErrorMessage)")
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }

            if store.definitions.isEmpty {
                Section {
                    Text("暂无字段")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    ForEach(store.definitions) { definition in
                        Button {
                            editTarget = definition
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(definition.label)
                                Text("\(definition.key) · \(typeText(definition.type))\(definition.required ? " · 必填" : "")")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteTarget = definition
                            } label: {
                                Text("删除")
                            }

                            Button {
                                editTarget = definition
                            } label: {
                                Text("编辑")
                            }
                            .tint(.blue)
                        }
                    }
                    .onMove(perform: store.move)
                }
            }
        }
        .navigationTitle("属性模板")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingCreate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
        .onAppear { store.reload() }
        .sheet(isPresented: $isPresentingCreate) {
            AttributeDefinitionEditorSheet(mode: .create) { key, label, type, required, options in
                store.createDefinition(key: key, label: label, type: type, required: required, options: options)
            }
        }
        .sheet(item: $editTarget) { definition in
            AttributeDefinitionEditorSheet(mode: .edit(definition: definition)) { key, label, type, required, options in
                store.updateDefinition(
                    id: definition.id,
                    key: key,
                    label: label,
                    type: type,
                    required: required,
                    options: options,
                    sortOrder: definition.sortOrder
                )
            }
        }
        .confirmationDialog(
            "删除字段？",
            isPresented: Binding(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                if let definition = deleteTarget {
                    store.deleteDefinition(id: definition.id)
                }
                deleteTarget = nil
            }

            Button("取消", role: .cancel) {
                deleteTarget = nil
            }
        } message: {
            Text("删除字段后，人物已填写的对应值不会自动迁移。")
        }
    }

    private func typeText(_ type: AttributeValueType) -> String {
        switch type {
        case .text:
            return "文本"
        case .number:
            return "数字"
        case .date:
            return "日期"
        case .singleSelect:
            return "单选"
        }
    }
}

