//
//  DeviceProvider.swift
//  wled-osx
//
//  Created by Robert Brune on 26.11.23.
//

import Foundation

protocol DeviceProvider: ObservableObject, Identifiable {
    
    @MainActor var brightness: Double { get set }
    @MainActor var isOn: Bool { get set }
    @MainActor var isConnected: Bool { get }
    
    @MainActor var name: String { get }
    @MainActor var address: String { get }
    
    @MainActor var activePreset: Int64 { get set }
    
    @MainActor var availablePresets:[(Int64, String)] { get }
}
