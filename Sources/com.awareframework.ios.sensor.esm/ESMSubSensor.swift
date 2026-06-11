import Foundation
import com_awareframework_ios_core

/// Handles SQLite persistence and server sync for ESMData records.
public class ESMSubSensor: AwareSensor {

    public var CONFIG = ESMSensor.Config()

    public init(_ config: ESMSensor.Config) {
        super.init()
        self.CONFIG = config
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

    public override func start() {}
    public override func stop() {}

    public override func sync(force: Bool = false) {
        if let engine = self.dbEngine, let syncConfig = super.syncConfig {
            engine.startSync(syncConfig)
        }
    }

    public override func set(label: String) {}
}
