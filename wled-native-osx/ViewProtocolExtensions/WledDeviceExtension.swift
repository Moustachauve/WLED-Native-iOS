//
//  WledDeviceExtension.swift
//  wled-osx
//
//  Created by Robert Brune on 26.11.23.
//

import Foundation
import WledLib

extension DeviceActor: DeviceProvider {
    
    @MainActor
    var availablePresets: [(Int64, String)] {
        guard var presets = presets?.presets else {
            return [(-1, "–")]
        }
        if (activePreset == -1) {
            presets.insert((-1, "–"), at: 0)
            return presets
        }
        return presets
    }
    
    
    @MainActor
    var activePreset: Int64 {
        get {
            ds?.state.selectedPresetId ?? -1
        }
        set {
            ds?.state.selectedPresetId = newValue
            
            let state = State(selectedPresetId: newValue)
            post(state: state)
        }
    }
    
    
    @MainActor
    var isOn:Bool {
        get {
            ds?.state.isOn ?? false
        }
        set {
            ds?.state.isOn = newValue
            
            let state = State(isOn: newValue)
            post(state: state)
        }
    }
    
    @MainActor
    var brightness:Double {
        get {
            Double(ds?.state.brightness ?? 0)
        }
        set {
            let newBrightness = UInt8(newValue)
            ds?.state.brightness = newBrightness
            
            let state = State(isOn: true, brightness: newBrightness)
            post(state: state)
        }
    }
    
    @MainActor
    var name: String {
        self.identifier.name
    }
    
    @MainActor
    var address: String {
        self.identifier.address
    }
    
    @MainActor
    var isConnected: Bool {
        self.ds != nil
    }
}
