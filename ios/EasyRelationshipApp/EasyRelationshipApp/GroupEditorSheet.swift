import SwiftUI

struct GroupEditorSheet: View {
    enum Mode {
        case create
        case rename(groupId: String)
    }

    let mode: Mode
    let initialName: String
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String

    init(mode: Mode, initialName: String = "", onSave: @escaping (String) -> Void) {
        self.mode = mode
        self.initialName = initialName
        self.onSave = onSave
        self._name = State(initialValue: initialName)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("群体名称") {
                    TextField("例如：家谱 / 团队 / 项目A", text: $name)
                        .textInputAutocapitalization(.never)
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
                        onSave(trimmed)
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
            return "新建群体"
        case .rename:
            return "重命名"
        }
    }
}

