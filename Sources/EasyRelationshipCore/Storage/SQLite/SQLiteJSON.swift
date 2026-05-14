import Foundation

public enum SQLiteJSON {
    public static func encodeDictionary(_ value: [String: String]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: value, options: [])
        guard let string = String(data: data, encoding: .utf8) else {
            throw SQLiteError(code: -1, message: "Failed to encode JSON")
        }
        return string
    }

    public static func decodeDictionary(_ value: String) throws -> [String: String] {
        let data = Data(value.utf8)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dict = json as? [String: String] else {
            return [:]
        }
        return dict
    }

    public static func encodeStringArray(_ value: [String]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: value, options: [])
        guard let string = String(data: data, encoding: .utf8) else {
            throw SQLiteError(code: -1, message: "Failed to encode JSON")
        }
        return string
    }

    public static func decodeStringArray(_ value: String) throws -> [String] {
        let data = Data(value.utf8)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let array = json as? [String] else {
            return []
        }
        return array
    }
}

