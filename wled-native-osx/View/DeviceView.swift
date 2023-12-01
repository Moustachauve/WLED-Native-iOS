//
//  DeviceView.swift
//  wled-osx
//
//  Created by Robert Brune on 15.11.23.
//

import SwiftUI
import Foundation
import OSLog

struct DeviceView<D: DeviceProvider>: View {
    
    
    @State var slider:Double
    @StateObject var device:D
    
    
    init(device: D) {
        self._device = StateObject(wrappedValue: device)
        self.slider = Double(device.brightness)
    }
    
    
    var body: some View {
        VStack {
            HStack {
                if (device.isConnected) {
                    onSwitch
                } else {
                    loadingView
                }
                VStack {
                    Text(device.name).font(.title)
                    Text(device.address).font(.subheadline)
                }
                Spacer()
                presetPicker
            }
            brigthnessSlider
        }
    }
    
    var loadingView: some View {
        ProgressView()
            .padding()
            .frame(alignment: .trailing)
    }
    
    var onSwitch: some View {
        Toggle("Turn On/Off", isOn: $device.isOn)
            .toggleStyle(SwitchToggleStyle())
            .labelsHidden()
            .frame(alignment: .trailing)
    }
    
    @State var test:Int64 = 0
    
    var presetPicker: some View {
        Picker(selection: $device.activePreset) {
            ForEach(device.availablePresets, id: \.0) { (tag, name) in
                Text(name).tag(tag)
            }
        } label: {
        }
    }
        
    var brigthnessSlider: some View {
        Slider(
            value: $slider,
            in: 1...255) { value in
                if (!value) {
                    device.brightness = slider
                }
            }
            .onChange(of: device.brightness) { o, n in
                slider = n
            }
    }
}


#if DEBUG

private class TestDevice: DeviceProvider {
    @MainActor var availablePresets: [(Int64, String)] = [(1, "Eins"), (2, "Zwei")]
    
    @MainActor var activePreset: Int64 = -1
    @MainActor var brightness: Double = 0.0
    @MainActor var isOn: Bool = false
    @MainActor var isConnected: Bool = false
    @MainActor var name: String = "WLED"
    @MainActor var address: String = "WLED.local"
    @MainActor var id: String {
        name
    }
}

#endif

#Preview {
    DeviceView(device: TestDevice())
}
