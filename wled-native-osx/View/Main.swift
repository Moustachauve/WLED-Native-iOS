//
//  Main.swift
//  wled-osx
//
//  Created by Robert Brune on 15.11.23.
//

import SwiftUI

@main
struct WLEDNativeBar: App {
    
    let deviceManager = DeviceCollection()
    
    var body: some Scene {
        MenuBarExtra("WLED", systemImage: "lamp.table.fill") {
            ContentView(deviceManager: deviceManager)
        }
            .menuBarExtraStyle(.window)
    }
}
