//
//  DeviceAddViewModel.swift
//  WLED
//
//  Created by Christophe Gagnier on 2025-12-21.
//

import Foundation

@MainActor
final class DeviceAddViewModel: ObservableObject {

    @Published var address: String = ""
    @Published var useSecure: Bool = false
    @Published var customName: String = ""
    @Published var currentStep: Step = .form()
    private let firstContactService = DeviceFirstContactService()

    /// Returns the normalized full address including scheme using the current toggle selection.
    var normalizedAddress: String? {
        let cleaned = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }

        let lowercasedAddress = cleaned.lowercased()
        let rawAddress: String

        if lowercasedAddress.hasPrefix("http://") || lowercasedAddress.hasPrefix("https://") {
            rawAddress = cleaned
        } else if cleaned.contains("://") {
            return nil
        } else {
            rawAddress = (useSecure ? "https://" : "http://") + cleaned
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

    var isAddressValid: Bool {
        normalizedAddress != nil
    }

    func submitCreateDevice() {
        if !isAddressValid {
            currentStep = .form(errorMessage: Error.enterValidAddress)
            return
        }
        Task {
            await findDevice()
        }
    }

    /// Starts searching for the device and adds it, if one is found
    private func findDevice() async {
        currentStep = .adding
        do {
            guard let normalizedAddress else {
                currentStep = .form(errorMessage: Error.enterValidAddress)
                return
            }

            let newDeviceId = try await firstContactService.fetchAndUpsertDevice(
                rawAddress: normalizedAddress
            )
            let viewContext = PersistenceController.shared.container.viewContext
            if let newDevice = viewContext.object(with: newDeviceId) as? Device {
                let trimmedCustomName = customName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedCustomName.isEmpty {
                    newDevice.customName = trimmedCustomName
                    try viewContext.save()
                }
                currentStep = .success(device: newDevice)
            }
        } catch let error {
            print("Error: \(error)")
            currentStep = .form(errorMessage: Error.cantConnect)
        }
    }

    // MARK: - State enum
    enum Step: Equatable {
        case form(errorMessage: String = "")
        case adding
        case success(device: Device)

        var isForm: Bool {
            if case .form = self { return true }
            return false
        }
    }

    // MARK: - Struct with magic stuff
    struct Error {
        static let enterValidAddress = String(localized: "Please enter a valid address")
        static let cantConnect = String(localized: "Could not connect to the device. Verify the address")
    }
}
