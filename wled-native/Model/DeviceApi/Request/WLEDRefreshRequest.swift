
import Foundation
import CoreData

struct WLEDRefreshRequest: WLEDRequest {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
}
