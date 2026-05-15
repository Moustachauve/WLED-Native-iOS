import Foundation

enum DeviceAddressNormalizer {
    static func normalizedAddress(from address: String, defaultScheme: String = "http") -> String? {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        let lowercasedAddress = trimmed.lowercased()
        let rawAddress: String
        
        if lowercasedAddress.hasPrefix("http://") || lowercasedAddress.hasPrefix("https://") {
            rawAddress = trimmed
        } else if trimmed.contains("://") {
            return nil
        } else {
            rawAddress = "\(defaultScheme)://\(trimmed)"
        }
        
        guard var components = URLComponents(string: rawAddress),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              components.host?.isEmpty == false else {
            return nil
        }
        
        components.user = nil
        components.password = nil
        components.path = ""
        components.query = nil
        components.fragment = nil
        components.scheme = scheme
        
        return components.url?.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
}

extension Device {
    var displayName: String {
        if let name = customName, !name.isEmpty {
            return name
        }
        if let name = originalName, !name.isEmpty {
            return name
        }
        return String(localized: "(New Device)")
    }
    
    var url: URL? {
        guard let address = address?.trimmingCharacters(in: .whitespacesAndNewlines),
              !address.isEmpty else {
            return nil
        }
        return URL(string: address)
    }
    
    var webSocketURL: URL? {
        guard let url = url,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        components.scheme = components.scheme?.lowercased() == "https" ? "wss" : "ws"
        components.path = "/ws"
        components.query = nil
        components.fragment = nil
        
        return components.url
    }
    
    func getColor(state: WledState?) -> Int64 {
        guard let state = state,
              let colorInfo = state.segment?.first?.colors?.first,
              colorInfo.count >= 3
        else {
            // Return neutral Gray if any data is missing
            return 0x808080
        }
        
        let red = Int64(Double(colorInfo[0]) + 0.5)
        let green = Int64(Double(colorInfo[1]) + 0.5)
        let blue = Int64(Double(colorInfo[2]) + 0.5)
        return (red << 16) | (green << 8) | blue
    }
}

extension Device: Observable { }
