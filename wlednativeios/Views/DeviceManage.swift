//
//  DeviceManage.swift
//  wlednativeios
//
//  Created by Christophe on 2021-09-13.
//

import SwiftUI

struct DeviceManage: View {
    var deviceList = DeviceRepository.instance.getAll()
    
    var body: some View {
        NavigationView {
            List(deviceList, id: \.address) {
                deviceItem in DeviceManageListItem(device: deviceItem)
            }
            
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Image("wled_logo_akemi")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(20)
                }
                
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    NavigationLink(destination: DeviceDiscovery()) {
                        Button {
                            
                        } label: {
                            Image(systemName: "pencil")
                        }
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink(destination: DeviceDiscovery()) {
                        Button {
                            
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .navigationTitle("Devices")
        }
    }
}

struct DeviceManage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DeviceManage(deviceList: [
                DeviceItem(address: "192.168.10.194", name: "WLED Bedroom"),
                DeviceItem(address: "192.168.10.195", name: "WLED Kitchen"),
                DeviceItem(address: "192.168.10.196", name: "WLED Kitchen 2")
            ])
        }
    }
}
