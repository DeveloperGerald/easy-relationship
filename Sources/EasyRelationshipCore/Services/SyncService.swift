import Foundation

public protocol SyncService: Sendable {
    func push() async throws
    func pull() async throws
}

public enum SyncError: Error, Sendable, Equatable {
    case disabled
}

public struct DisabledSyncService: SyncService {
    public init() {}

    public func push() async throws {
        throw SyncError.disabled
    }

    public func pull() async throws {
        throw SyncError.disabled
    }
}

