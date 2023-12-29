//
//  DeviceUpdateInstalling.swift
//  wled-native
//
//  Created by Christophe Perso on 2023-12-28.
//

import SwiftUI

struct DeviceUpdateInstalling: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State var offset: CGFloat = 1000
    @State var updateDone = false
    @State var canDismiss = true
    
    var body: some View {
        ZStack {
            Color(.clear)
            VStack {
                Text("Updating [DEVICE NAME]")
                    .font(.title2)
                    .bold()
                    .padding(.top)
                    .padding(.trailing)
                    .padding(.leading)
                
                ProgressView()
                    .controlSize(.large)
                    .frame(alignment: .trailing)
                    .padding(.bottom, 5)
                
                Text("Installing Update")
                    .font(.title3)
                    .bold()
                
                Text("WLED_0.14.0-b6_ESP32.bin")
                    .font(.callout)
                
                Text("Please do not close the app or turn off the device.")
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text(updateDone ? "Done" : "Cancel")
                        .buttonStyle(.plain)
                }
                .disabled(!canDismiss)
            }
            .fixedSize(horizontal: false, vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 20)
            .offset(x: 0, y: offset)
            .onAppear {
                withAnimation(.spring()) {
                    offset = 0
                }
                startUpdate()
            }
        }
    }
    
    private func startUpdate() {
        // TODO: Implement update here
    }
}

#Preview {
    DeviceUpdateInstalling()
}
