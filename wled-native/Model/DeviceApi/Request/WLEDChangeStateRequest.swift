
import Foundation
import CoreData

struct WLEDChangeStateRequest: WLEDRequest {
    let context: NSManagedObjectContext
    let state: WLEDStateChange
    
    init(state: WLEDStateChange, context: NSManagedObjectContext) {
        self.state = state
        self.context = context
    }
}
