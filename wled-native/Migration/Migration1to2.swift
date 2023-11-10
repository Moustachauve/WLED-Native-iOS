
import Foundation
import CoreData

class Migration1to2: NSEntityMigrationPolicy {
    @objc func newUUID() -> UUID {
        return UUID()
    }
}
