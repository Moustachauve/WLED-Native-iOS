//
//  ContentView.swift
//  wled-osx
//
//  Created by Robert Brune on 15.11.23.
//

import SwiftUI
import OSLog

struct ContentView<P: CollectionProvider>: View {
    
    @ObservedObject var deviceManager:P
    
    var body: some View {
        VStack {
            header
            deviceLists
        }
    }
    
    var header: some View {
        HStack {
            Image(.wledLogoAkemi)
                .resizable()
                .scaledToFit()
                .padding()
        
            Spacer()
            quitButton
            
        
        }
            .padding()
    }
    
    var deviceLists: some View {
            List {
                Section(header: Text("Devices")) {
                    ForEach(deviceManager.devices) { device in
                        DeviceView(device: device)
                    }
                }
                Spacer()
            }
                
                .listStyle(PlainListStyle())
    }
    
    var quitButton: some View {
        Button(action: {
            exit(EXIT_SUCCESS)
        }) {
            Image(systemName: "power.circle")
                .font(.title)
        }
            .buttonStyle(BorderlessButtonStyle())
            .padding()
    }
}
    

#Preview {
    ContentView(deviceManager:  DeviceCollection())
        .frame(width: 100, height: 300)
}
