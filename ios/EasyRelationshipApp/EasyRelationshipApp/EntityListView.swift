import SwiftUI
import EasyRelationshipCore

struct EntityListView: View {
    @StateObject private var store: EntitiesStore

    @State private var isPresentingCreate: Bool = false
    @State private var editTarget: EasyRelationshipCore.Entity? = nil
    @State private var deleteTarget: EasyRelationshipCore.Entity? = nil

    init(store: EntitiesStore) {
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

            if store.entities.isEmpty {
                Section {
                    Text(store.query.isEmpty ? "暂无数据" : "无匹配结果")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    ForEach(store.entities) { entity in
                        NavigationLink {
                            EntityDetailView(store: store, entityId: entity.id)
                        } label: {
                            Text(entity.name)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteTarget = entity
                            } label: {
                                Text("删除")
                            }

                            Button {
                                editTarget = entity
                            } label: {
                                Text("编辑")
                            }
                            .tint(.blue)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            deleteTarget = store.entities[index]
                        }
                    }
                }
            }
        }
        .navigationTitle("个体")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingCreate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .searchable(text: $store.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索姓名")
        .onChange(of: store.query) { _, _ in
            store.reload()
        }
        .onAppear {
            store.reload()
        }
        .sheet(isPresented: $isPresentingCreate) {
            EntityEditorSheet(
                mode: .create,
                attributeDefinitions: store.attributeDefinitions
            ) { name, attributes in
                store.createEntity(name: name, attributes: attributes)
            }
        }
        .sheet(item: $editTarget) { entity in
            EntityEditorSheet(
                mode: .edit(entityId: entity.id),
                attributeDefinitions: store.attributeDefinitions,
                initialName: entity.name,
                initialAttributes: entity.attributes
            ) { name, attributes in
                store.updateEntity(entityId: entity.id, name: name, attributes: attributes)
            }
        }
        .confirmationDialog(
            "删除个体？",
            isPresented: Binding(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                if let entity = deleteTarget {
                    store.deleteEntity(entityId: entity.id)
                }
                deleteTarget = nil
            }

            Button("取消", role: .cancel) {
                deleteTarget = nil
            }
        } message: {
            Text("删除后，与该个体相关的关系也会被删除。")
        }
    }
}
