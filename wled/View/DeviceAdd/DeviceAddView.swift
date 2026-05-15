import SwiftUI

struct DeviceAddView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = DeviceAddViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.currentStep {
                case .form(let errorMessage):
                    DeviceAddStep1FormView(
                        viewModel: viewModel,
                        errorMessage: errorMessage
                    )
                case .adding:
                    DeviceAddStep2LoadingView(address: viewModel.address)
                case .success(let device):
                    DeviceAddStep3Success(device: device)
                }
            }
            .animation(.easeInOut, value: currentStepAnimationID)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                    }
                }
                if viewModel.currentStep.isForm {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            withAnimation {
                                viewModel.submitCreateDevice()
                            }
                        } label: {
                            Label("Add", systemImage: "checkmark")
                        }
                    }
                }
            }
            .navigationTitle("New Device")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: currentStepAnimationID) { newValue in
            guard newValue == 2 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                dismiss()
            }
        }
    }
    
    private var currentStepAnimationID: Int {
        switch viewModel.currentStep {
        case .form:
            0
        case .adding:
            1
        case .success:
            2
        }
    }
}

// MARK: - Step 1: Form

struct DeviceAddStep1FormView: View {
    @ObservedObject var viewModel: DeviceAddViewModel
    @FocusState private var focusedField: Field?

    let errorMessage: String
    
    var body: some View {
        Form {
            Section {
                LabeledContent("Custom Name") {
                    TextField("Custom Name", text: $viewModel.customName)
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                        .focused($focusedField, equals: .customName)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .address
                        }
                }
            }
            
            Section {
                TextField("IP Address or URL", text: $viewModel.address, axis: .vertical)
                    .lineLimit(1)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .onChange(of: viewModel.address) { newValue in
                        let lowercased = newValue.lowercased()
                        
                        if lowercased.hasPrefix("https://") {
                            if !viewModel.useSecure {
                                viewModel.useSecure = true
                            }
                        } else if lowercased.hasPrefix("http://") {
                            if viewModel.useSecure {
                                viewModel.useSecure = false
                            }
                        }
                    }
                    .focused($focusedField, equals: .address)
                    .submitLabel(.done)
                    .onSubmit {
                        normalizeAddressScheme()
                        withAnimation {
                            viewModel.submitCreateDevice()
                        }
                    }
                
                Toggle("Use Secure Connections", isOn: Binding(
                    get: {
                        viewModel.useSecure
                    },
                    set: { newValue in
                        viewModel.useSecure = newValue
                        
                        let lowercased = viewModel.address.lowercased()
                        
                        if newValue && lowercased.hasPrefix("http://") {
                            viewModel.address.removeFirst("http://".count)
                            viewModel.address = "https://" + viewModel.address
                        } else if !newValue && lowercased.hasPrefix("https://") {
                            viewModel.address.removeFirst("https://".count)
                            viewModel.address = "http://" + viewModel.address
                        }
                    }
                ))
            } header: {
                Text("IP Address or URL")
            } footer: {
                Text("WLED only supports HTTPS when accessed through a secure reverse proxy.")
            }
            
            if !errorMessage.isEmpty {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption.bold())
                }
            }
        }
        .onAppear {
            focusedField = .customName
        }
        .onChange(of: focusedField) { newValue in
            if newValue != .address {
                normalizeAddressScheme()
            }
        }
    }
    
    private func normalizeAddressScheme() {
        let trimmedAddress = viewModel.address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAddress.isEmpty else {
            viewModel.address = ""
            return
        }
        
        let lowercased = trimmedAddress.lowercased()
        guard !lowercased.hasPrefix("http://") && !lowercased.hasPrefix("https://") else {
            viewModel.address = trimmedAddress
            return
        }
        
        viewModel.address = (viewModel.useSecure ? "https://" : "http://") + trimmedAddress
    }
    
    enum Field: Hashable {
        case customName
        case address
    }
}

// MARK: - Step 2: Adding, Loading indicator

struct DeviceAddStep2LoadingView: View {
    let address: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            
            Text("Adding \(address)")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Step 3: Success

struct DeviceAddStep3Success: View {
    let device: Device

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            
            Text("Device Added")
                .font(.title3.bold())
            
            Text("\(device.displayName) was added")
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    DeviceAddView()
}
