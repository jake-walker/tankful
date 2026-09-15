//
//  SyncSettingsView.swift
//  tankful
//
//  Created by Jake Walker on 16/09/2026.
//

import SwiftUI
import TankfulSync

struct SyncSettingsView: View {
    @Environment(AppEnvironment.self) internal var env
    
    @State internal var syncEnabled = true
    @State internal var serverURL = ""
    @State internal var username = ""
    @State internal var password = ""
    @State internal var headers = ""
    @State internal var validationMessage: String?
    
    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    Image(systemName: syncEnabled ? "arrow.trianglehead.2.clockwise.rotate.90" : "circle.slash")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .fontWeight(.semibold)
                        .frame(width: 32, height: 32)
                    
                    VStack(alignment: .leading) {
                        Text(syncEnabled ? "Sync Status" : "Sync Disabled")
                            .font(.headline)
                        
                        if syncEnabled {
                            Text(syncText)
                        }
                    }
                }
            }
            
            Section {
                Toggle("Enable sync", isOn: $syncEnabled)
                    .onChange(of: syncEnabled) { _, enabled in
                        if !enabled {
                            env.syncConfiguration = nil
                            validationMessage = nil
                        }
                    }
                
                if syncEnabled {
                    Picker("Backend", selection: .constant(BackendType.tracktor)) {
                        Text("Tracktor").tag(BackendType.tracktor)
                    }
                    .disabled(true)
                }
            }
        
            if syncEnabled {
                Section {
                    LabeledContent {
                        TextField("Server URL", text: $serverURL, prompt: Text("https://tracktor.example.com"))
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                    } label: {
                        Text("Server URL")
                    }
                    
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $password)
                } header: {
                    Text("Server")
                }
                
                Section {
                    TextEditor(text: $headers)
                        .frame(minHeight: 72)
                        .font(.body.monospaced())
                } header: {
                    Text("Headers")
                } footer: {
                    Text("Add one header per line, for example: `X-API-Key: abcdef`")
                }
                
                Section("Actions") {
                    Button("Sync Now") {
                        Task { await syncNow() }
                    }
                    .disabled(isSyncing)
                }
            }
        }
        .navigationTitle("Sync Settings")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if #available(iOS 26.0, *) {
                    Button("Save Changes", systemImage: "checkmark", role: .confirm) {
                        saveSyncConfiguration()
                    }
                } else {
                    Button("Save Changes", systemImage: "checkmark") {
                        saveSyncConfiguration()
                    }
                }
            }
        }
        .onAppear {
            loadSyncConfiguration()
        }
    }
    
    private var isSyncing: Bool {
        if case .syncing = env.syncStatus {
            return true
        }
        return false
    }

    private var syncText: String {
        switch env.syncStatus {
        case .idle(let lastSync):
            if let lastSync {
                return "Last synced \(lastSync.formatted(date: .abbreviated, time: .shortened))"
            } else {
                return "Not yet synced"
            }
        case .syncing:
            return "Syncing..."
        case .failed(_, let message):
            return "Failed: \(message)"
        }
    }
    
    private func syncNow() async {
        do {
            try await env.syncNow()
        } catch {
            print("Sync error: \(error.localizedDescription)")
        }
    }
    
    private func loadSyncConfiguration() {
        guard let configuration = env.syncConfiguration else {
            syncEnabled = false
            return
        }
        
        syncEnabled = true
        serverURL = configuration.baseURL.absoluteString
        headers = configuration.additionalHeaders
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
            .map { "\($0.key): \($0.value)" }
            .joined(separator: "\n")
        
        if case let .credentials(savedUsername, savedPassword) = configuration.authentication {
            username = savedUsername
            password = savedPassword
        }
    }
    
    private func saveSyncConfiguration() {
        guard let baseURL = URL(string: serverURL),
              let scheme = baseURL.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              baseURL.host != nil else {
            validationMessage = "Enter a valid HTTP or HTTPS server URL."
            return
        }
        
        do {
            let additionalHeaders = try parseHeaders(headers)
            let authentication: SyncConfiguration.Authentication?
            
            if username.isEmpty && password.isEmpty {
                authentication = nil
            } else if username.isEmpty || password.isEmpty {
                validationMessage = "Enter both a username and password, or leave both blank."
                return
            } else {
                authentication = .credentials(username: username, password: password)
            }
            
            env.syncConfiguration = SyncConfiguration(
                type: .tracktor,
                baseURL: baseURL,
                additionalHeaders: additionalHeaders,
                authentication: authentication
            )
            validationMessage = nil
        } catch {
            validationMessage = error.localizedDescription
        }
    }
    
    private func parseHeaders(_ text: String) throws -> [String: String] {
        var parsed: [String: String] = [:]
        
        for (index, rawLine) in text.split(whereSeparator: \.isNewline).enumerated() {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }
            guard let separator = line.firstIndex(of: ":") else {
                throw HeaderParsingError.invalidLine(index + 1)
            }
            
            let name = line[..<separator].trimmingCharacters(in: .whitespaces)
            let value = line[line.index(after: separator)...].trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty, !value.isEmpty else {
                throw HeaderParsingError.invalidLine(index + 1)
            }
            parsed[name] = value
        }
        
        return parsed
    }
}

private enum HeaderParsingError: LocalizedError {
    case invalidLine(Int)

    var errorDescription: String? {
        switch self {
        case .invalidLine(let line):
            "Custom header on line \(line) must use \"Name: value\" format."
        }
    }
}

#Preview {
    NavigationView {
        SyncSettingsView()
            .environment(AppEnvironment.preview())
    }
}
