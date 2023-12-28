
import Foundation

class DeviceListFilterAndSort: ObservableObject {
    
    @Published var showHiddenDevices: Bool
    @Published private var sort = [
        NSSortDescriptor(keyPath: \Device.isOnline, ascending: false),
        NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:))),
    ]

    init(showHiddenDevices: Bool) {
        self.showHiddenDevices = showHiddenDevices
    }
    
    func getSortDescriptors() -> [NSSortDescriptor] {
        return sort
    }
    
    func getOnlineFilter() -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            getOnlineFilter(isOnline: true),
            getHiddenFilterFormat()
        ])
    }
    
    func getOfflineFilter() -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            getOnlineFilter(isOnline: false),
            getHiddenFilterFormat()
        ])
    }
    
    private func getOnlineFilter(isOnline: Bool) -> NSPredicate {
        return NSPredicate(format: "isOnline == %@", NSNumber(value: isOnline))
    }
    
    private func getHiddenFilterFormat() -> NSPredicate {
        if (showHiddenDevices) {
            return NSPredicate(value: true)
        }
        
        return NSPredicate(format: "isHidden == %@", NSNumber(value: false))
    }
}
