import SwiftUI
import EasyRelationshipCore

struct RelationTypesView: View {
    @StateObject private var store: RelationTypesStore
    @State private var isPresentingCreate: Bool = false
    @State private var editTarget: EasyRelationshipCore.RelationType? = nil
    @State private var deleteTarget: EasyRelationshipCore.RelationType? = nil

    init(store: RelationTypesStore) {
        self._store = StateObject(wrappedValue: store)
    }

    var body: some View {
        List {
            if !store.lastErrorMessage.isEmpty {
                Section {
                    Text("操作失败：\(store.lastErrorMessage)")
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }

            if store.relationTypes.isEmpty {
                Section {
                    Text("暂无关系类型")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    ForEach(store.relationTypes) { item in
                        Button {
                            editTarget = item
                        } label: {
                            HStack {
                                Text(item.name)
                                Spacer()
                                Text(item.directional ? "有方向" : "无方向")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteTarget = item
                            } label: {
                                Text("删除")
                            }

                            Button {
                                editTarget = item
                            } label: {
                                Text("编辑")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("关系类型")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingCreate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear { store.reload() }
        .sheet(isPresented: $isPresentingCreate) {
            RelationTypeEditorSheet(mode: .create) { name, directional in
                store.create(name: name, directional: directional)
            }
        }
        .sheet(item: $editTarget) { item in
            RelationTypeEditorSheet(mode: .edit(id: item.id), initialName: item.name, initialDirectional: item.directional) { name, directional in
                store.update(id: item.id, name: name, directional: directional)
            }
        }
        .confirmationDialog(
            "删除关系类型？",
            isPresented: Binding(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                if let item = deleteTarget {
                    store.delete(id: item.id)
                }
                deleteTarget = nil
            }

            Button("取消", role: .cancel) {
                deleteTarget = nil
            }
        } message: {
            Text("如果已有关系使用该类型，删除可能失败。")
        }
    }
}

