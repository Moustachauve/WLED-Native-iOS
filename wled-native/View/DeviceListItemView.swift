
import SwiftUI

struct DeviceListItemView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var device: Device
    var brightness: Binding<Double>
    
    init(device: Device) {
        self.device = device
        self.brightness = Binding(
            get: { Double(device.brightness) },
            set: { device.brightness = Int64($0) } // Or other custom logic
        )
    }

    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(device.name!)
                        .font(.headline)
                    HStack {
                        Text(device.address!)
                            .font(.subheadline)
                        Image(uiImage: getSignalImage(isOnline: device.isOnline, signalStrength: Int(device.networkRssi)))
                            .offset(y: -2)
                        Text("[Offline]")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Toggle("Turn On/Off", isOn: $device.isOnline)
                    .labelsHidden()
                    .frame(alignment: .trailing)
                    .tint(colorFromHex(rgbValue: Int(device.color)))
            }
            Slider(
                value: brightness,
                in: 0...255,
                onEditingChanged: { editing in
                    
                }
            )
            .tint(colorFromHex(rgbValue: Int(device.color)))
        }
    }
    
    func getSignalImage(isOnline: Bool, signalStrength: Int) -> UIImage {
        let icon = !isOnline || signalStrength == 0 ? "wifi.slash" : "wifi"
        var image: UIImage;
        if #available(iOS 16.0, *) {
            image = UIImage(
                systemName: icon,
                variableValue: getSignalValue(signalStrength: Int(device.networkRssi))
            )!
        } else {
            image = UIImage(
                systemName: icon
            )!
        }
        image.applyingSymbolConfiguration(UIImage.SymbolConfiguration(hierarchicalColor: .systemBlue))
        return image
    }
    
    func getSignalValue(signalStrength: Int) -> Double {
        if (signalStrength >= -70) {
            return 1
        }
        if (signalStrength >= -85) {
            return 0.64
        }
        if (signalStrength >= -100) {
            return 0.33
        }
        return 0
    }
    
    func colorFromHex(rgbValue: Int, alpha: Double? = 1.0) -> Color {
        // &  binary AND operator to zero out other color values
        // >>  bitwise right shift operator
        // Divide by 0xFF because UIColor takes CGFloats between 0.0 and 1.0
        
        let red =   CGFloat((rgbValue & 0xFF0000) >> 16) / 0xFF
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 0xFF
        let blue =  CGFloat(rgbValue & 0x0000FF) / 0xFF
        let alpha = CGFloat(alpha ?? 1.0)
        
        return fixColor(color: UIColor(red: red, green: green, blue: blue, alpha: alpha))
    }
    
    // Fixes the color if it is too dark or too bright depending of the dark/light theme
    func fixColor(color: UIColor) -> Color {
        var h = CGFloat(0), s = CGFloat(0), b = CGFloat(0), a = CGFloat(0)
        color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        b = colorScheme == .dark ? fmax(b, 0.2) : fmin(b, 0.75)
        return Color(UIColor(hue: h, saturation: s, brightness: b, alpha: a))
    }
}

struct DeviceListItemView_Previews: PreviewProvider {
    static var previews: some View {
        
        let device = Device(context: PersistenceController.preview.container.viewContext)
        device.name = Date().formatted()
        device.address = "192.168.11.101"
        device.isOnline = true
        device.color = 6244567779
        

        return DeviceListItemView(device: device)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
