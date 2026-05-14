import SwiftUI
import EasyRelationshipCore

struct EntityEditorSheet: View {
    enum Mode {
        case create
        case edit(entityId: String)
    }

    let mode: Mode
    let attributeDefinitions: [EasyRelationshipCore.AttributeDefinition]
    let initialName: String
    let initialAttributes: [String: String]
    let onSave: (String, [String: String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var attributes: [String: String]
    @State private var dateValues: [String: Date]
    @State private var invalidNumberKeys: Set<String>
    @State private var touchedDateKeys: Set<String>

    private let dateFormatter: ISO8601DateFormatter = ISO8601DateFormatter()

    init(
        mode: Mode,
        attributeDefinitions: [EasyRelationshipCore.AttributeDefinition],
        initialName: String = "",
        initialAttributes: [String: String] = [:],
        onSave: @escaping (String, [String: String]) -> Void
    ) {
        self.mode = mode
        self.attributeDefinitions = attributeDefinitions
        self.initialName = initialName
        self.initialAttributes = initialAttributes
        self.onSave = onSave
        self._name = State(initialValue: initialName)
        self._attributes = State(initialValue: initialAttributes)
        self._dateValues = State(initialValue: [:])
        self._invalidNumberKeys = State(initialValue: [])
        self._touchedDateKeys = State(initialValue: [])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("名称") {
                    TextField("请输入名称", text: $name)
                        .textInputAutocapitalization(.never)
                }

                if !attributeDefinitions.isEmpty {
                    Section("属性") {
                        ForEach(attributeDefinitions) { definition in
                            attributeField(definition)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .onAppear {
                ensureDateValues()
                validateAllNumbers()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard canSave(name: trimmedName) else { return }
                        onSave(trimmedName, normalizedAttributes())
                        dismiss()
                    }
                    .disabled(!canSave(name: name.trimmingCharacters(in: .whitespacesAndNewlines)))
                }
            }
        }
    }

    private var title: String {
        switch mode {
        case .create:
            return "新增个体"
        case .edit:
            return "编辑个体"
        }
    }

    private func canSave(name: String) -> Bool {
        guard !name.isEmpty else { return false }
        for definition in attributeDefinitions where definition.required {
            switch definition.type {
            case .date:
                let hasDate = (attributes[definition.key]?.isEmpty == false) || (touchedDateKeys.contains(definition.key))
                if !hasDate {
                    return false
                }
            case .number:
                let raw = (attributes[definition.key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                if raw.isEmpty { return false }
                if invalidNumberKeys.contains(definition.key) { return false }
            default:
                let value = (attributes[definition.key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                if value.isEmpty { return false }
            }
        }

        for definition in attributeDefinitions where definition.type == .number {
            let raw = (attributes[definition.key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if raw.isEmpty { continue }
            if invalidNumberKeys.contains(definition.key) { return false }
        }

        return true
    }

    private func normalizedAttributes() -> [String: String] {
        var updated = attributes
        for definition in attributeDefinitions {
            if definition.type == .date, let date = dateValues[definition.key] {
                if touchedDateKeys.contains(definition.key) || (attributes[definition.key]?.isEmpty == false) {
                    updated[definition.key] = dateFormatter.string(from: date)
                }
            }
            if definition.type == .number {
                let raw = (updated[definition.key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                if raw.isEmpty {
                    continue
                }
                let normalized = normalizeNumberText(raw).text
                updated[definition.key] = normalized
            }
        }
        return updated
    }

    @ViewBuilder
    private func attributeField(_ definition: EasyRelationshipCore.AttributeDefinition) -> some View {
        switch definition.type {
        case .text:
            TextField(definition.label, text: bindingForKey(definition.key))
                .textInputAutocapitalization(.never)

        case .number:
            VStack(alignment: .leading, spacing: 6) {
                TextField(definition.label, text: bindingForNumberKey(definition.key))
                    .keyboardType(.decimalPad)
                if invalidNumberKeys.contains(definition.key) {
                    Text("请输入有效数字")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }

        case .singleSelect:
            Picker(definition.label, selection: bindingForKey(definition.key)) {
                Text("未选择").tag("")
                ForEach(definition.options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }

        case .date:
            VStack(alignment: .leading, spacing: 6) {
                DatePicker(definition.label, selection: bindingForDateKey(definition.key), displayedComponents: .date)
                if !definition.required, (attributes[definition.key]?.isEmpty == false || touchedDateKeys.contains(definition.key)) {
                    Button("清除") {
                        attributes.removeValue(forKey: definition.key)
                        dateValues.removeValue(forKey: definition.key)
                        touchedDateKeys.remove(definition.key)
                    }
                    .font(.caption)
                }
            }
        }
    }

    private func bindingForKey(_ key: String) -> Binding<String> {
        Binding(
            get: { attributes[key] ?? "" },
            set: { attributes[key] = $0 }
        )
    }

    private func bindingForNumberKey(_ key: String) -> Binding<String> {
        Binding(
            get: { attributes[key] ?? "" },
            set: { newValue in
                let normalized = normalizeNumberText(newValue)
                attributes[key] = normalized.text
                if normalized.text.isEmpty {
                    invalidNumberKeys.remove(key)
                } else if normalized.isValid {
                    invalidNumberKeys.remove(key)
                } else {
                    invalidNumberKeys.insert(key)
                }
            }
        )
    }

    private func bindingForDateKey(_ key: String) -> Binding<Date> {
        Binding(
            get: { dateValues[key] ?? Date() },
            set: {
                dateValues[key] = $0
                attributes[key] = dateFormatter.string(from: $0)
                touchedDateKeys.insert(key)
            }
        )
    }

    private func ensureDateValues() {
        for definition in attributeDefinitions where definition.type == .date {
            if dateValues[definition.key] != nil { continue }
            if let value = attributes[definition.key], let date = dateFormatter.date(from: value) {
                dateValues[definition.key] = date
            } else {
                if definition.required {
                    dateValues[definition.key] = Date()
                }
            }
        }
    }

    private func validateAllNumbers() {
        var invalid: Set<String> = []
        for definition in attributeDefinitions where definition.type == .number {
            let raw = (attributes[definition.key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if raw.isEmpty { continue }
            if !normalizeNumberText(raw).isValid {
                invalid.insert(definition.key)
            }
        }
        invalidNumberKeys = invalid
    }

    private func normalizeNumberText(_ input: String) -> (text: String, isValid: Bool) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return ("", true)
        }

        let replaced = trimmed
            .replacingOccurrences(of: "，", with: ".")
            .replacingOccurrences(of: "。", with: ".")
            .replacingOccurrences(of: ",", with: ".")

        var out = ""
        var hasDot = false
        var hasMinus = false
        for (idx, ch) in replaced.enumerated() {
            if ch.isWholeNumber {
                out.append(ch)
                continue
            }
            if ch == "." {
                if hasDot { continue }
                hasDot = true
                if out.isEmpty { out.append("0") }
                out.append(".")
                continue
            }
            if ch == "-" {
                if idx == 0 && !hasMinus {
                    hasMinus = true
                    out.append("-")
                }
                continue
            }
        }

        let isValid = Double(out) != nil
        return (out, isValid)
    }
}
