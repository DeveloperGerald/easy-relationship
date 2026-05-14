import Foundation

public struct AppEnvironment: Sendable {
    public var featureFlags: FeatureFlagStore
    public var graphGenerationService: any GraphGenerationService
    public var syncService: any SyncService

    public init(
        featureFlags: FeatureFlagStore = FeatureFlagStore(),
        graphGenerationService: any GraphGenerationService = DisabledGraphGenerationService(),
        syncService: any SyncService = DisabledSyncService()
    ) {
        self.featureFlags = featureFlags
        self.graphGenerationService = graphGenerationService
        self.syncService = syncService
    }
}

