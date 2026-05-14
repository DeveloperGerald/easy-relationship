import SwiftUI

struct RelationTypeEditorSheet: View {
    enum Mode {
        case create
        case edit(id: String)
    }

    let mode: Mode
    let initialName: String
    let initialDirectional: Bool
    let onSave: (String, Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var directional: Bool

    init(
        mode: Mode,
        initialName: String = "",
        initialDirectional: Bool = false,
        onSave: @escaping (String, Bool) -> Void
    ) {
        self.mode = mode
        self.initialName = initialName
        self.initialDirectional = initialDirectional
        self.onSave = onSave
        self._name = State(initialValue: initialName)
        self._directional = State(initialValue: initialDirectional)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("名称") {
                    TextField("例如：同事 / 朋友 / 上下级", text: $name)
                        .textInputAutocapitalization(.never)
                }

                Section("规则") {
                    Toggle("方向性", isOn: $directional)
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed, directional)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var title: String {
        switch mode {
        case .create:
            return "新增关系类型"
        case .edit:
            return "编辑关系类型"
        }
    }
}

