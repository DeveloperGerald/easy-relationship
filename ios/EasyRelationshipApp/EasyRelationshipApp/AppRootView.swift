import SwiftUI
import EasyRelationshipCore

struct AppRootView: View {
    let environment: AppEnvironment

    @AppStorage(SettingsKeys.enableAIGeneration) private var enableAIGeneration: Bool = false
    @AppStorage(SettingsKeys.enableCloudSync) private var enableCloudSync: Bool = false

    @StateObject private var store: AppStore
    @State private var isPresentingCreateGroup: Bool = false
    @State private var renameTarget: EasyRelationshipCore.Group? = nil
    @State private var deleteTarget: EasyRelationshipCore.Group? = nil

    init(environment: AppEnvironment) {
        self.environment = environment
        let dbURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("easyrelationship.sqlite")
        self._store = StateObject(wrappedValue: AppStore.make(databaseURL: dbURL))
    }

    var body: some View {
        NavigationStack {
            List {
                Section("群体") {
                    if store.lastErrorMessage.isEmpty {
                        if store.groups.isEmpty {
                            Text("暂无群体")
                                .foregroundStyle(.secondary)
                        }
                        ForEach(store.groups) { group in
                            NavigationLink(group.name) {
                                GroupDetailView(group: group, appStore: store)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteTarget = group
                                } label: {
                                    Text("删除")
                                }

                                Button {
                                    renameTarget = group
                                } label: {
                                    Text("重命名")
                                }
                                .tint(.blue)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let group = store.groups[index]
                                deleteTarget = group
                            }
                        }
                    } else {
                        Text("数据库初始化失败：\(store.lastErrorMessage)")
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }

                Section("占位") {
                    HStack {
                        Text("AI 生成")
                        Spacer()
                        Text(enableAIGeneration ? "开启" : "未开启")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("云同步")
                        Spacer()
                        Text(enableCloudSync ? "开启" : "未开启")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("EasyRelationship")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingCreateGroup = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(!store.lastErrorMessage.isEmpty)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .onAppear {
                store.reloadGroups()
            }
            .sheet(isPresented: $isPresentingCreateGroup) {
                GroupEditorSheet(mode: .create) { name in
                    store.createGroup(name: name)
                }
            }
            .sheet(item: $renameTarget) { group in
                GroupEditorSheet(mode: .rename(groupId: group.id), initialName: group.name) { name in
                    store.renameGroup(groupId: group.id, name: name)
                }
            }
            .confirmationDialog(
                "删除群体？",
                isPresented: Binding(
                    get: { deleteTarget != nil },
                    set: { if !$0 { deleteTarget = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("删除", role: .destructive) {
                    if let group = deleteTarget {
                        store.deleteGroup(groupId: group.id)
                    }
                    deleteTarget = nil
                }

                Button("取消", role: .cancel) {
                    deleteTarget = nil
                }
            } message: {
                Text("删除后，该群体下的个体与关系也会一并删除。")
            }
        }
    }
}
