import Foundation
import com_awareframework_ios_core

/// Handles SQLite persistence and server sync for ESMData records.
public class ESMSubSensor: AwareSensor {

    public var CONFIG = ESMSensor.Config()

    public init(_ config: ESMSensor.Config) {
        super.init()
        self.CONFIG = Self.makeConfig(from: config)
        self.CONFIG.dbPath = ESMData.databaseTableName
        self.CONFIG.dbTableName = ESMData.databaseTableName
        self.initializeDbEngine(config: self.CONFIG)
        super.syncConfig = DbSyncConfig().apply { syncConfig in
            syncConfig.serverType    = self.CONFIG.serverType
            syncConfig.debug         = self.CONFIG.debug
            syncConfig.batchSize     = 1000
            syncConfig.dispatchQueue = DispatchQueue(label: "com.awareframework.ios.sensor.esm.sync.queue")
        }
        if let sqliteEngine = self.dbEngine as? SQLiteEngine,
           let instance = sqliteEngine.getSQLiteInstance() {
            ESMData.createTable(queue: instance)
        }
    }

    public func applySyncSettings(
        from parentConfig: ESMSensor.Config,
        parentSyncConfig: DbSyncConfig?,
        completionHandler: DbSyncCompletionHandler?
    ) {
        CONFIG.dbHost = parentConfig.dbHost
        CONFIG.dbType = parentConfig.dbType
        CONFIG.dbEncryptionKey = parentConfig.dbEncryptionKey
        CONFIG.serverType = parentConfig.serverType
        CONFIG.studyNumber = parentConfig.studyNumber
        CONFIG.studyKey = parentConfig.studyKey
        CONFIG.debug = parentConfig.debug
        CONFIG.label = parentConfig.label
        CONFIG.dbPath = ESMData.databaseTableName
        CONFIG.dbTableName = ESMData.databaseTableName
        initializeDbEngine(config: CONFIG)

        let config = syncConfig ?? DbSyncConfig()
        if let parentSyncConfig {
            config.removeAfterSync = parentSyncConfig.removeAfterSync
            config.batchSize = parentSyncConfig.batchSize
            config.markAsSynced = parentSyncConfig.markAsSynced
            config.skipSyncedData = parentSyncConfig.skipSyncedData
            config.keepLastData = parentSyncConfig.keepLastData
            config.deviceId = parentSyncConfig.deviceId
            config.debugLevel = parentSyncConfig.debugLevel
            config.progressHandler = parentSyncConfig.progressHandler
            config.backgroundSession = parentSyncConfig.backgroundSession
            config.compactDataFormat = parentSyncConfig.compactDataFormat
            config.test = parentSyncConfig.test
        }
        config.serverType = CONFIG.serverType
        config.studyNumber = CONFIG.studyNumber
        config.studyKey = CONFIG.studyKey
        config.debug = CONFIG.debug
        config.completionHandler = completionHandler
        config.dispatchQueue = DispatchQueue(label: "com.awareframework.ios.sensor.esm.sync.queue")
        syncConfig = config
    }

    public override func start() {}
    public override func stop() {}

    public override func sync(force: Bool = false) {
        if let engine = self.dbEngine, let syncConfig = super.syncConfig {
            engine.startSync(syncConfig)
        }
    }

    public override func set(label: String) {}

    private static func makeConfig(from source: ESMSensor.Config) -> ESMSensor.Config {
        ESMSensor.Config().apply { config in
            config.enabled = source.enabled
            config.debug = source.debug
            config.label = source.label
            config.deviceId = source.deviceId
            config.dbEncryptionKey = source.dbEncryptionKey
            config.dbType = source.dbType
            config.serverType = source.serverType
            config.studyNumber = source.studyNumber
            config.studyKey = source.studyKey
            config.dbHost = source.dbHost
            config.sensorObserver = source.sensorObserver
        }
    }
}
