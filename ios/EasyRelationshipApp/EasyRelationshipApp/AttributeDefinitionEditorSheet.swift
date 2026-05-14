import SwiftUI
import EasyRelationshipCore

struct AttributeDefinitionEditorSheet: View {
    enum Mode {
        case create
        case edit(definition: EasyRelationshipCore.AttributeDefinition)
    }

    let mode: Mode
    let onSave: (String, String, AttributeValueType, Bool, [String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var key: String
    @State private var label: String
    @State private var type: AttributeValueType
    @State private var required: Bool
    @State private var optionsText: String

    init(mode: Mode, onSave: @escaping (String, String, AttributeValueType, Bool, [String]) -> Void) {
        self.mode = mode
        self.onSave = onSave

        switch mode {
        case .create:
            self._key = State(initialValue: Self.suggestKey())
            self._label = State(initialValue: "")
            self._type = State(initialValue: .text)
            self._required = State(initialValue: false)
            self._optionsText = State(initialValue: "")
        case .edit(let definition):
            self._key = State(initialValue: definition.key)
            self._label = State(initialValue: definition.label)
            self._type = State(initialValue: definition.type)
            self._required = State(initialValue: definition.required)
            self._optionsText = State(initialValue: definition.options.joined(separator: "\n"))
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("字段") {
                    TextField("显示名称（例如：部门）", text: $label)
                    TextField("Key（唯一）", text: $key)
                        .textInputAutocapitalization(.never)
                }

                Section("类型") {
                    Picker("类型", selection: $type) {
                        Text("文本").tag(AttributeValueType.text)
                        Text("数字").tag(AttributeValueType.number)
                        Text("日期").tag(AttributeValueType.date)
                        Text("单选").tag(AttributeValueType.singleSelect)
                    }

                    Toggle("必填", isOn: $required)
                }

                if type == .singleSelect {
                    Section("选项（每行一个）") {
                        TextEditor(text: $optionsText)
                            .frame(minHeight: 120)
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedKey.isEmpty, !trimmedLabel.isEmpty else { return }
                        let options = parseOptions(optionsText)
                        onSave(trimmedKey, trimmedLabel, type, required, options)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private var title: String {
        switch mode {
        case .create:
            return "新增字段"
        case .edit:
            return "编辑字段"
        }
    }

    private var canSave: Bool {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedKey.isEmpty || trimmedLabel.isEmpty {
            return false
        }
        if type == .singleSelect {
            return !parseOptions(optionsText).isEmpty
        }
        return true
    }

    private func parseOptions(_ text: String) -> [String] {
        let raw = text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        var seen = Set<String>()
        var result: [String] = []
        for item in raw {
            if seen.contains(item) { continue }
            seen.insert(item)
            result.append(item)
        }
        return result
    }

    private static func suggestKey() -> String {
        let suffix = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        return "attr_" + suffix.prefix(8)
    }
}
