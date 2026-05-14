import Foundation

public struct FeatureFlagStore: Sendable {
    private var overrides: [FeatureFlagKey: Bool]

    public init(overrides: [FeatureFlagKey: Bool] = [:]) {
        self.overrides = overrides
    }

    public func isEnabled(_ key: FeatureFlagKey) -> Bool {
        if let override = overrides[key] {
            return override
        }

        switch key {
        case .aiGraphGeneration:
            return false
        case .cloudSync:
            return false
        }
    }

    public mutating func set(_ key: FeatureFlagKey, enabled: Bool) {
        overrides[key] = enabled
    }
}

